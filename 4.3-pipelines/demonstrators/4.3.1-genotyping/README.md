# Joint cohort genotyping demonstrator pipeline

This simple demonstrator pipeline follows the basic principles of the [common federation approach](../../README.md) adopted by WP4. The goal is to demonstrate how a simple metric (in this case, allele frequency) can be computed in a federated manner.

Step A (private step) reduces the individual level genotypes to dataset-specific allele counts, which are then exported and collected in a central location.

Step B (meta-analysis step) then computes the final allele frequencies based on the results collected from step A.

The instructions below demonstrate how the pipeline can be run on two separate datasets with two different reference genomes using three different execution environments. The example input files are provided.

The test region used for the demonstrator is the ACE gene with the coordinates:
* GRCh37: chr17:61554422-61575741
* GRCh38: chr17:63477061-63498373

## Step A1, raw data processing: GIAB

|Property|Value|
|---|---|
|Dataset|GIAB|
|Access protocol|FTP|
|Number of samples|7|
|Data format|BAM|
|Reference genome|GRCh38|
|Processing environment|TESK @ CSC Rahti cloud|

This example, [`input-1-giab.tsv`](input-1-giab.tsv), uses FTP links to GRCh38 alignments of HG001...HG007 obtained from https://github.com/genome-in-a-bottle/giab_data_indexes.

See also the [general instructions](/4.3-pipelines/environments/tesk.md) for setting up and using the TESK environment.

```bash
time ./nextflow stepA-calculate-frequency.nf \
  --inputData input-A1-giab.tsv \
  --referenceGenomeLink 'http://hgdownload.cse.ucsc.edu/goldenpath/hg38/chromosomes/chr17.fa.gz' \
  --debugDir debug_giab \
  --outputVcf result-A1-giab.vcf.gz
```

## Step A2, raw data processing: EGA

|Property|Value|
|---|---|
|Dataset|EGA synthetic dataset|
|Access protocol|htsget via EGA download client|
|Number of samples|6|
|Data format|BAM|
|Reference genome|GRCh37|
|Processing environment|LSF @ EMBL-EBI cluster|

The example, [`input-2-ega.tsv`](input-2-ega.tsv), was constructed using 6 BAM files from the EGA test dataset EGAD00001003338. Details: https://github.com/EGA-archive/ega-download-client.

See also the [general instructions](/4.3-pipelines/environments/lsf.md) for setting up and using the LSF environment.

```bash
time ./nextflow stepA-calculate-frequency.nf \
  --inputData input-A2-ega.tsv \
  --referenceGenomeLink 'ftp://ftp.ensembl.org/pub/grch37/current/fasta/homo_sapiens/dna/Homo_sapiens.GRCh37.dna.chromosome.17.fa.gz' \
  --debugDir debug_ega \
  --outputVcf result-A2-ega.vcf.gz
```

## Step B, result integration

Procesing environment: **local (Linux machine).**

See also the [general instructions](/4.3-pipelines/environments/local.md) for setting up and using the local (Linux) environment.

After steps A1 and A2 have been run, collect the result files (`result-A1-giab.vcf.gz` and `result-A2-ega.vcf.gz`) into the same location.

```bash
time ./nextflow stepB-integrate-results.nf \
  --inputData input-B.tsv \
  --targetReferenceGenomeLink 'http://hgdownload.cse.ucsc.edu/goldenpath/hg38/chromosomes/chr17.fa.gz' \
  --debugDir debug_integrate \
  --outputVcf result-B.vcf.gz
```

The resulting file, `result-B.vcf.gz`, contains the joint `AN` and `AC` counts from two datasets, and a joint `AF` calculated from them.
