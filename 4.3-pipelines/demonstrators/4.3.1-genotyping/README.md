# Joint cohort genotyping demonstrator pipeline

This simple demonstrator pipeline follows the basic principles of the [common federation approach](../../README.md) adopted by CINECA WP4. The goal is to demonstrate how a simple metric (in this case, allele frequency) can be computed in a federated manner, without requiring ever collecting the raw (individual level) data in a central location.

Step A (private step) reduces the individual level genotypes to dataset-specific allele numbers and counts, which are then exported and collected in a central location. Step B (meta-analysis step) then computes the final allele frequencies based on the results collected from step A.

The instructions below demonstrate how the pipeline can be run on two separate datasets with two different reference genomes using three different execution environments. The example input files are provided. The test region used for the demonstrator is the ACE gene with the coordinates chr17:61554422-61575741 in GRCh37 and chr17:63477061-63498373 in GRCh38.

## Dependency installation

The pipeline dependencies are contained in a [`Dockerfile`](Dockerfile), available as a `tskir/cineca-wp4-genotyping` image.

For simplicity, the commands below always display Nextflow being invoked simply as `nextflow`; however, the syntax slightly varies between environments. Please see the separate documentation for each environment on how to run it.

## Step A1, individual level data processing: GIAB

|Property|Value|
|---|---|
|Dataset|GIAB|
|Access protocol|FTP|
|Number of samples|7 (4 used)|
|Data format|BAM|
|Reference genome|GRCh38|
|Processing environment|TESK @ CSC Rahti cloud|

This example, [`input-A1-giab.tsv`](input-A/input-A1-giab.tsv), uses FTP links to GRCh38 alignments of HG001...HG007 obtained from https://github.com/genome-in-a-bottle/giab_data_indexes.

See also the [general instructions](/4.3-pipelines/environments/tesk.md) for setting up and using the TESK environment.

```bash
nextflow run -with-docker tskir/cineca-wp4-genotyping:v0.4.0 \
  stepA-calculate-frequency.nf \
  --inputData input-A/input-A1-giab.tsv \
  --referenceGenomeLink 'http://hgdownload.cse.ucsc.edu/goldenpath/hg38/chromosomes/chr17.fa.gz' \
  --debugDir debug_giab \
  --outputVcf result-A1-giab.vcf.gz
```

## Step A2, individual level data processing: EGA

|Property|Value|
|---|---|
|Dataset|EGA synthetic dataset|
|Access protocol|htsget via EGA download client|
|Number of samples|6 (4 used)|
|Data format|BAM|
|Reference genome|GRCh37|
|Processing environment|LSF @ EMBL-EBI cluster|

The example, [`input-A2-ega.tsv`](input-A/input-A2-ega.tsv), was constructed using 6 BAM files from the EGA test dataset EGAD00001003338. Details: https://github.com/EGA-archive/ega-download-client.

See also the [general instructions](/4.3-pipelines/environments/lsf.md) for setting up and using the LSF environment.

```bash
nextflow run -with-docker tskir/cineca-wp4-genotyping:v0.4.0 \
  stepA-calculate-frequency.nf \
  --inputData input-A/input-A2-ega.tsv \
  --referenceGenomeLink 'ftp://ftp.ensembl.org/pub/grch37/current/fasta/homo_sapiens/dna/Homo_sapiens.GRCh37.dna.chromosome.17.fa.gz' \
  --debugDir debug_ega \
  --outputVcf result-A2-ega.vcf.gz
```

## Step B, result integration

Procesing environment: **local (Linux machine).**

After steps A1 and A2 have been run, collect the result files (`result-A1-giab.vcf.gz` and `result-A2-ega.vcf.gz`) into the same location (`input-B` directory in this example). The input file, [`input-B.tsv`](input-B/input-B.tsv), contains the two output files from the previous steps, as well as a definition of transformations (chromosome renaming and liftover) applicable to each file.

```bash
nextflow run -with-docker tskir/cineca-wp4-genotyping:v0.4.0 \
  stepB-integrate-results.nf \
  --inputData input-B/input-B.tsv \
  --inputDir `realpath input-B` \
  --targetReferenceGenomeLink 'http://hgdownload.cse.ucsc.edu/goldenpath/hg38/chromosomes/chr17.fa.gz' \
  --debugDir debug_integrate \
  --outputVcf result-B.vcf.gz
```

The resulting file, [`result-B.vcf.gz`](expected-results/result-B.vcf.gz), contains the joint `AN` and `AC` counts from two datasets.
