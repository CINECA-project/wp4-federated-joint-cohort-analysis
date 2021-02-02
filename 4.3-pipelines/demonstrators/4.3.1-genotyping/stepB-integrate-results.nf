#!/usr/bin/env nextflow


input_data_ch = Channel.fromPath(params.inputData)
    .splitCsv(header: true, sep: "\t", strip: true)
    .map { row -> [row.dataset_id, row.input_vcf, row.chr_name_mapping, row.liftover_chain] }

input_dir = file(params.inputData).getParent()


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
        set dataset_id, input_vcf, chr_name_mapping, liftover_chain from input_data_ch
    output:
        set dataset_id, file("${dataset_id}.renamed.vcf.gz"), liftover_chain into renamed_data_ch

    script:

        if ( chr_name_mapping == "-" )
            """
            cp ${input_dir}/${input_vcf} "${dataset_id}.renamed.vcf.gz"
            """

        else
            """
            bcftools annotate -Oz --rename-chrs ${input_dir}/${chr_name_mapping} ${input_dir}/${input_vcf} \
                > "${dataset_id}.renamed.vcf.gz"
            """

}


process variantLiftover {

    memory '2 GB'
    publishDir params.debugDir

    input:
        set dataset_id, renamed_vcf, liftover_chain from renamed_data_ch
        file("reference.fa") from reference_genome_fa
    output:
        set dataset_id, file("${dataset_id}.remapped.vcf.gz") into remapped_data_ch

    script:

        if ( liftover_chain == "-" )
            """
            cp ${renamed_vcf} "${dataset_id}.remapped.vcf.gz"
            """

        else
            """
            # Create sequence dictionary
            java -Xmx2g -jar ${input_dir}/picard.jar CreateSequenceDictionary \
                -R "reference.fa" \
                -O "reference.dict"

            # Lift over
            java -Xmx2g -jar ${input_dir}/picard.jar LiftoverVcf \
                -I ${renamed_vcf} \
                -O "${dataset_id}.remapped.vcf.gz" \
                -CHAIN <(wget -qO- ${liftover_chain} | gzip -cd) \
                -REJECT /dev/null \
                -R "reference.fa"
            """

}
