#!/usr/bin/env nextflow


input_data_ch = Channel.fromPath(params.inputData)
    .splitCsv(header: true, sep: "\t", strip: true)
    .map { row -> [row.sample_id, row.fetch_mode, row.path] }


process fetchReferenceGenome {

    publishDir params.resultsDir, mode: "copy"
    output: path "reference.fa" into reference_genome_fa

    """
    wget -qO- ${params.referenceGenomeLink} | gzip -cd > reference.fa
    """

}


process fetchInputData {

    publishDir params.resultsDir, mode: "copy"

    // samtools library cannot handle network errors, so we need to retry explicitly in case they happen.
    errorStrategy "retry"
    maxRetries 5

    input: set sample_id, fetch_mode, path from input_data_ch
    output: set sample_id, file("${sample_id}.bam") into reads_bam

    script:

        // In this case, --max-retries 0 is because the network error retries are already handled by Nextflow.
        if( fetch_mode == "EGA" )
            """
            pyega3 -d -t fetch "${path}" \
                -r 17 -s 61554422 -e 61575741 \
                --max-retries 0 --format BAM --saveto "${sample_id}.bam"
            """

        else if ( fetch_mode == "FTP" )
            """
            samtools view -b "${path}" chr17:63477061-63498373 > "${sample_id}.bam"
            """

        else
            error "Unsupported data fetch mode: ${fetch_mode}"

}


process callVariants {

    publishDir params.resultsDir, mode: "copy"

    input:
        set sample_id, file("${sample_id}.bam") from reads_bam
        file("reference.fa") from reference_genome_fa
    output:
        set sample_id, file("${sample_id}.vcf") into calls_vcf

    """
    bcftools mpileup -Ou -f "reference.fa" "${sample_id}.bam" \
        | bcftools call -m -Ou \
        | bcftools view -i "%QUAL > 30" -Ov -o "${sample_id}.vcf"
    """

}
