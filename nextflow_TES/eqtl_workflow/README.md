# Simple demonstrator pipeline for eQTL analysis

First, perform the actions described in the parent README file: log in to the Kubernetes pod and set up the necessary environment variables.

Download the example HISAT2 index and reference GTF file from here: https://www.dropbox.com/sh/eko17f1b5azsnxn/AAD7BmX-gHzRDeV2R0fpud1ba?dl=0.

Run the workflow:
```bash
nextflow eqtl.nf \
  --studyFile study_file.txt \
  --hisat2_index hisat2_index/hisat2_index \
  --gtf_file Homo_sapiens.GRCh38.91.chr21.gtf \
  -with-docker nfcore/rnaseq:1.4.2
```

It should take up to 5–10 minutes to execute, and the results should appear as four `*.counts` files in the `result/` subdirectory.
