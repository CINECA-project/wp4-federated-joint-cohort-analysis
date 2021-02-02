#!/usr/bin/env nextflow


input_data_ch = Channel.fromPath(params.inputData)
    .splitCsv(header: true, sep: "\t", strip: true)
    .map { row -> [row.dataset_id, row.input_vcf, row.chr_name_mapping, row.liftover_required] }

input_dir = file(params.inputData).getParent()


process renameChromosomeNames {

    publishDir params.debugDir

    input:
        set dataset_id, input_vcf, chr_name_mapping, liftover_required from input_data_ch
    output:
        set dataset_id, file("${dataset_id}.renamed.vcf.gz"), liftover_required into renamed_data_ch

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