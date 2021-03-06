#!/usr/bin/env nextflow


input_data_ch = Channel.fromPath(params.inputData)
    .splitCsv(header: true, sep: "\t", strip: true)
    .map { row -> [row.sample_id, row.fetch_mode, row.path] }

final_vcf_name = file(params.outputVcf).getName()
final_vcf_dir = file(params.outputVcf).getParent()


process fetchReferenceGenome {

    errorStrategy "retry"
    maxRetries 3
    publishDir params.debugDir

    output:
        path "reference.fa" into reference_genome_fa

    """
    wget -qO- ${params.referenceGenomeLink} | gzip -cd > reference.fa
    """

}


process fetchInputData {

    // samtools library cannot handle network errors, so we need to retry explicitly in case they happen.
    errorStrategy "retry"
    maxRetries 100
    publishDir params.debugDir

    input:
        set sample_id, fetch_mode, path from input_data_ch
    output:
        set sample_id, file("${sample_id}.bam") into reads_bam

    script:

        if( fetch_mode == "EGA" )
            """
            pyega3 -d -t fetch "${path}" \
                --max-retries 0 \
                -r 17 -s 61554422 -e 61575741 \
                --format BAM --saveto "${sample_id}.bam"
            """

        else if ( fetch_mode == "FTP" )
            """
            samtools view -b "${path}" chr17:63477061-63498373 > "${sample_id}.bam"
            """

        else
            error "Unsupported data fetch mode: ${fetch_mode}"

}


process callVariants {

    publishDir params.debugDir

    input:
        set sample_id, file("${sample_id}.bam") from reads_bam
        file("reference.fa") from reference_genome_fa
    output:
        file("${sample_id}.vcf.gz") into calls_vcf
        file("${sample_id}.vcf.gz.tbi") into indexes_tbi

    """
    bcftools mpileup -Ou -f "reference.fa" "${sample_id}.bam" \
        | bcftools call -m -Ou \
        | bcftools view -i "%QUAL > 30" -Ov -o "${sample_id}.vcf"
    bgzip "${sample_id}.vcf"
    tabix -p vcf "${sample_id}.vcf.gz"
    """

}


process mergeVcf {

    publishDir final_vcf_dir, mode: "copy"

    // We don't need the indexes explicitly, but we must request them as inputs so that they appear alongside VCF files.
    input:
        file vcf_files from calls_vcf.collect()
        file indexes_tbi from indexes_tbi.collect()
    output:
        file("${final_vcf_name}")

    """
    bcftools merge -Ou ${vcf_files} \
        | bcftools view -Oz -i 'INFO/AC>0' -s '' --force-samples > "${final_vcf_name}"
    """

}
