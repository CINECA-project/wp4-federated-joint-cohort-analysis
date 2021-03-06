#!/usr/bin/env nextflow


input_data_ch = Channel.fromPath(params.inputData)
    .splitCsv(header: true, sep: "\t", strip: true)
    .map { row -> [row.dataset_id, row.input_vcf, row.chr_name_mapping, row.liftover_chain] }

// We need the .collect() because this has to be a value channel, reused by all input data sets
input_dir_ch = Channel.fromPath(params.inputDir, type: 'dir').collect()
final_vcf_name = file(params.outputVcf).getName()
final_vcf_dir = file(params.outputVcf).getParent()


process fetchTargetReferenceGenome {

    errorStrategy "retry"
    maxRetries 3
    publishDir params.debugDir

    output:
        path "reference.fa" into reference_genome_fa

    """
    wget -qO- ${params.targetReferenceGenomeLink} | gzip -cd > reference.fa
    """

}


process renameChromosomes {

    publishDir params.debugDir

    input:
        file input_dir from input_dir_ch
        set dataset_id, input_vcf, chr_name_mapping, liftover_chain from input_data_ch
    output:
        set dataset_id, file("${dataset_id}.1-renamed.vcf.gz"), liftover_chain into renamed_data_ch

    script:

        if ( chr_name_mapping == "-" )
            """
            ln -s ${input_dir}/${input_vcf} "${dataset_id}.1-renamed.vcf.gz"
            """

        else
            """
            bcftools annotate -Oz --rename-chrs ${input_dir}/${chr_name_mapping} ${input_dir}/${input_vcf} \
                > "${dataset_id}.1-renamed.vcf.gz"
            """

}


process variantLiftover {

    memory '2 GB'
    publishDir params.debugDir

    input:
        set dataset_id, renamed_vcf, liftover_chain from renamed_data_ch
        file("reference.fa") from reference_genome_fa
    output:
        set dataset_id, file("${dataset_id}.2-remapped.vcf.gz") into remapped_data_ch

    script:

        if ( liftover_chain == "-" )
            """
            ln -s ${renamed_vcf} "${dataset_id}.2-remapped.vcf.gz"
            """

        else
            """
            # Create sequence dictionary
            java -Xmx2g -jar /picard.jar CreateSequenceDictionary \
                -R "reference.fa" \
                -O "reference.dict"

            # Lift over
            java -Xmx2g -jar /picard.jar LiftoverVcf \
                -I ${renamed_vcf} \
                -O "${dataset_id}.2-remapped.vcf.gz" \
                -CHAIN <(wget -qO- ${liftover_chain} | gzip -cd) \
                -REJECT /dev/null \
                -R "reference.fa"
            """

}


process renameAnnotations {

    /* Before combining AC and AN annotations, it's necessary to rename them to avoid bcftools trying to recompute
    them. See also: https://github.com/samtools/bcftools/issues/1394. */

    input:
        set dataset_id, file("${dataset_id}.2-remapped.vcf.gz") from remapped_data_ch
    output:
        set dataset_id, file("${dataset_id}.3-annotations.vcf.gz") into annotations_data_ch

    """
    bcftools annotate \
        --rename-annots <(echo -e 'INFO/AN\tAN_\nINFO/AC\tAC_') \
        -Oz -o "${dataset_id}.3-annotations.vcf.gz" \
        "${dataset_id}.2-remapped.vcf.gz"
    """

}


process indexVcf {

    publishDir params.debugDir

    input:
        set dataset_id, file("${dataset_id}.3-annotations.vcf.gz") from annotations_data_ch
    output:
        file("${dataset_id}.3-annotations.vcf.gz") into ready_vcf_ch
        file("${dataset_id}.3-annotations.vcf.gz.tbi") into ready_vcf_index_ch

    """
    tabix -p vcf "${dataset_id}.3-annotations.vcf.gz"
    """

}


process mergeVcf {

    publishDir final_vcf_dir, mode: "copy"

    // We don't need the indexes explicitly, but we must request them as inputs so that they appear alongside VCF files.
    input:
        file vcf_files from ready_vcf_ch.collect()
        file indexes_tbi from ready_vcf_index_ch.collect()
    output:
        file("${final_vcf_name}")

    """
    bcftools merge -Ou ${vcf_files} --info-rules 'AN_:sum,AC_:sum' \
        | bcftools annotate \
              --rename-annots <(echo -e 'INFO/AN_\tAN\nINFO/AC_\tAC') -Oz -o "${final_vcf_name}"
    """

}
