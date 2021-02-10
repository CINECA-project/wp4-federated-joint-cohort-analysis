# Joint cohort genotyping demonstrator pipeline

This simple demonstrator pipeline follows the basic principles of the [common federation approach](../../README.md) adopted by CINECA WP4. The goal is to demonstrate how a simple metric (in this case, allele frequency) can be computed in a federated manner, without requiring ever collecting the raw (individual level) data in a central location.

Step A (private step) reduces the individual level genotypes to dataset-specific allele numbers and counts, which are then exported and collected in a central location. Step B (meta-analysis step) then computes the final allele frequencies based on the results collected from step A.

The instructions below demonstrate how the pipeline can be run on two separate datasets with two different reference genomes using three different execution environments. The example input files are provided. The test region used for the demonstrator is the ACE gene with the coordinates chr17:61554422-61575741 in GRCh37 and chr17:63477061-63498373 in GRCh38.

## Dependency installation

```bash
cd bin
# Nextflow
wget -qO- https://get.nextflow.io | bash
# Latest bcftools version (required for certain functionality)
# git clone --branch develop git://github.com/samtools/htslib.git
# cd htslib && git submodule update --init --recursive && make -j `nproc` && cd ..
# git clone --branch develop git://github.com/samtools/bcftools.git
# cd bcftools && autoheader && autoconf && ./configure && make -j `nproc` && cd ..
# git clone --branch develop git://github.com/samtools/samtools.git
# cd samtools && autoheader && autoconf && ./configure && make -j `nproc` && cd ..
# Picard tools
wget -q https://github.com/broadinstitute/picard/releases/download/2.24.2/picard.jar
cd ..
```

## Step A1, raw data processing: GIAB

|Property|Value|
|---|---|
|Dataset|GIAB|
|Access protocol|FTP|
|Number of samples|7 (4 used)|
|Data format|BAM|
|Reference genome|GRCh38|
|Processing environment|TESK @ CSC Rahti cloud|

This example, [`inputs/input-A1-giab.tsv`](input-A/input-A1-giab.tsv), uses FTP links to GRCh38 alignments of HG001...HG007 obtained from https://github.com/genome-in-a-bottle/giab_data_indexes.

See also the [general instructions](/4.3-pipelines/environments/tesk.md) for setting up and using the TESK environment.

```bash
./bin/nextflow stepA-calculate-frequency.nf \
  --inputData input-A/input-A1-giab.tsv \
  --referenceGenomeLink 'http://hgdownload.cse.ucsc.edu/goldenpath/hg38/chromosomes/chr17.fa.gz' \
  --binDir `realpath bin` \
  --debugDir debug_giab \
  --outputVcf result-A1-giab.vcf.gz
```

## Step A2, raw data processing: EGA

|Property|Value|
|---|---|
|Dataset|EGA synthetic dataset|
|Access protocol|htsget via EGA download client|
|Number of samples|6 (4 used)|
|Data format|BAM|
|Reference genome|GRCh37|
|Processing environment|LSF @ EMBL-EBI cluster|

The example, [`inputs/input-A2-ega.tsv`](input-A/input-A2-ega.tsv), was constructed using 6 BAM files from the EGA test dataset EGAD00001003338. Details: https://github.com/EGA-archive/ega-download-client.

See also the [general instructions](/4.3-pipelines/environments/lsf.md) for setting up and using the LSF environment.

```bash
./bin/nextflow stepA-calculate-frequency.nf \
  --inputData input-A/input-A2-ega.tsv \
  --referenceGenomeLink 'ftp://ftp.ensembl.org/pub/grch37/current/fasta/homo_sapiens/dna/Homo_sapiens.GRCh37.dna.chromosome.17.fa.gz' \
  --binDir `realpath bin` \
  --debugDir debug_ega \
  --outputVcf result-A2-ega.vcf.gz
```

## Step B, result integration

Procesing environment: **local (Linux machine).**

After steps A1 and A2 have been run, collect the result files (`result-A1-giab.vcf.gz` and `result-A2-ega.vcf.gz`) into the same location (`input-B` directory in this example).

```bash
./bin/nextflow stepB-integrate-results.nf \
  --inputData input-B/input-B.tsv \
  --targetReferenceGenomeLink 'http://hgdownload.cse.ucsc.edu/goldenpath/hg38/chromosomes/chr17.fa.gz' \
  --binDir `realpath bin` \
  --debugDir debug_integrate \
  --outputVcf result-B.vcf.gz
```

The resulting file, `expected-results/result-B.vcf.gz`, contains the joint `AN` and `AC` counts from two datasets.
