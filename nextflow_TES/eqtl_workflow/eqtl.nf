Channel.fromPath(params.studyFile)
    .ifEmpty { error "Cannot find study file: ${params.studyFile}" }
    .splitCsv(header: true, sep: '\t', strip: true)
    .map{row -> [ row.study, file(row.fastq1), file(row.fastq2) ]}
    .set { fastq_ch }

Channel
    .fromPath( "${params.hisat2_index}*" )
    .ifEmpty { exit 1, "HISAT2 index files not found: ${params.hisat2_index}" }
    .set { hisat2_index_ch }

Channel
    .fromPath(params.gtf_file)
    .ifEmpty { exit 1, "Gene annotations GTF file not found: ${params.gtf_file}" } 
    .set { gtf_ch }

process hisat2Align{
    
    input:
    set sample_name, file(fastq1), file(fastq2) from fastq_ch
    file hisat2_indices from hisat2_index_ch.collect()

    output:
    set sample_name, file("${sample_name}.bam") into hisat2_bam

    script:
    index_base = hisat2_indices[0].toString() - ~/.\d.ht2/
    """
    hisat2 -x $index_base -1 ${fastq1} -2 ${fastq2} | samtools view -Sb > ${sample_name}.bam
    """
}

process countReads{
    publishDir "results/", mode: 'copy', pattern: "*.counts"

    input:
    set sample_name, file(bam_file) from hisat2_bam
    file gtf_file from gtf_ch.collect()

    output:
    file("${sample_name}.counts") into counts_ch

    script:
    """
    featureCounts -p -C -D 5000 -d 50 -s2 -a ${gtf_file} -o ${sample_name}.counts ${bam_file}
    """

}