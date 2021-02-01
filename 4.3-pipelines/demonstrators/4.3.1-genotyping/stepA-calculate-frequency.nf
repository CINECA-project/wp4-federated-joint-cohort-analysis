#!/usr/bin/env nextflow

input_data_ch = Channel.fromPath(params.inputData)
    .splitCsv(header: true, sep: "\t", strip: true)
    .map { row -> [row.sample_id, row.fetch_mode, row.path] }

process fetchInputData {

    publishDir "results/", mode: "copy"

    // samtools library cannot handle network errors, so we need to retry in case they happen
    errorStrategy "retry"
    maxRetries 5

    input: set sample_id, fetch_mode, path from input_data_ch
    output: set sample_id, file("${sample_id}.bam") into reads_bam

    script:

        if( fetch_mode == "EGA" )
            """echo EGA"""

        else if ( fetch_mode == "FTP" )
            """
            samtools view -b "${path}" chr22:20014945-20069053 > "${sample_id}.bam"
            """

        else
            error "Unsupported data fetch mode: ${fetch_mode}"

}

