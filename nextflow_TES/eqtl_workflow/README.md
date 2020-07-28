# Pipeline for eQTL analysis



### Download HISAT2 index and reference GTF file from here

https://www.dropbox.com/sh/eko17f1b5azsnxn/AAD7BmX-gHzRDeV2R0fpud1ba?dl=0

### Run Nextflow workflow

nextflow main.nf --studyFile study_file.txt\
    --hisat2_index hisat2_index/hisat2_index\
    --gtf_file annotations/Homo_sapiens.GRCh38.91.chr21.gtf