# Tutorial: Performing end-to-end molecular QTLs analysis with the eQTL Catalogue workflows

The aim of molecular quantitative trait locus (molQTL) analysis is to identify genetic variants associated with molecular traits such as gene expression levels, transcript usage or splice-junction usage. This analysis involves multiple complex steps that can be logically separated from each each. First, raw genotype data from genotyping microarrays needs to be quality contolled and imputed against the latest reference panel. This can be done with the [eQTL-Catalogue/genimpute](https://github.com/eQTL-Catalogue/genimpute) workflow. Secondly, molecular traits need to quantified from the raw sequencing data. For RNA-sequencing-based traits such as gene expression levels or splice-junction usage, we present the [eQTL-Catalogue/rnaseq](https://github.com/eQTL-Catalogue/rnaseq) workflow in this tutorial. For other molecular traits such as chromatin accessibility or histone modifications, we recommend the excellent workflows developed by the [nf-core](https://nf-co.re/) community such as [nf-core/atacseq](https://github.com/nf-core/atacseq) or [nf-core/chipseq](https://github.com/nf-core/chipseq). Once the molecular traits have been quantified, they need to be normalised and standardised for association testing with linear regression. This typically involves adjusting for the sequencing read coverage of each sample and other covariates, log transformation of the data and further inverse normal transformation to reduce the impact of outliers. For the RNA-seq-based traits, these steps have been implemented in the [eQTL-Catalogue/qcnorm](https://github.com/eQTL-Catalogue/qcnorm) worklfow presented in step 3. Finally, we need to test for associations between normalised molecular traits and imputed genetic variants using the [eQTL-Catalogue/qtlmap](https://github.com/eQTL-Catalogue/qtlmap) workflow prsented in step 4. 

## Step 1: Genotype imputation with eQTL-Catalogue/genimpute

The [eQTL-Catalogue/genimpute](https://github.com/eQTL-Catalogue/genimpute) workflow takes raw genotype data in plink format, lifts variant positions to the correct reference genome version with CrossMap, aligns the genotypes to the reference panel with Genotype Harmonizer,  performs QC filtering with bcftools, phases the genotypes with Eagle and finally imputes the genotypes with Minimac4. The workflow also correctly handles the genotypes on the X chromosome, performing imputation separately for the pseudoautosomal regions (PAR) and the non-PAR regions.

![genimpute_level_schema](workflow_execution_files/genimpute_metromap.png)


#### Dowload the workflow from GitHub

```bash
git clone https://github.com/eQTL-Catalogue/genimpute.git
cd genimpute
```

#### Input
1. Raw genotype data in PLINK binary format (.bed, .bim, .fam) and using GRCh37 coordinates. 

For an example, you can download the raw genotypes from the [CEDAR](https://doi.org/10.5281/zenodo.6171348) dataset from Zenodo:

```bash
wget https://zenodo.org/record/6171348/files/CEDAR_HumanOmniExpress-12v1.tar.gz
tar -xzvf CEDAR_HumanOmniExpress-12v1.tar.gz
```
The eQTL-Catalogue/genimpute workflow assumes that the input genotypes are in the binary plink format (.bed/.bim/.fam), use GRCh37 coordinates and the name of the X chromosome is 'X' with PAR and non-PAR regions merged. To check that your plink files corresponds to these standards and to fix common issues, please see:
* [Checking raw genotype files prior to imputation](plink_check.md)

2. Imputation and phasing reference panel.

You can download eQTL Catalogue [1000 Genomes 30x on GRCh38](https://www.internationalgenome.org/data-portal/data-collection/30x-grch38) reference panel from the eQTL Catalogue FTP server:

```bash
wget ftp://ftp.ebi.ac.uk/pub/databases/spot/eQTL/references/genimpute_complete_reference_150322.tar.gz
tar -xzvf genimpute_complete_reference_150322.tar.gz
```
Note that the default paths to the phasing and imputation reference panels are specified in the `nextflow.config` file. If you place the `genimpute_complete_reference` folder into the genimpute workflow directory, then the paths should already be correct. If you decide to put the reference panel files somewhere else then you also need to modiy the corresponding paths in the `nextflow.config` file. 

#### Output
Imputed genotypes in VCF format using GRCh38 coordinates.

#### Running the workflow
```bash
nextflow run main.nf \
  -profile tartu_hpc -resume\
  --bfile plink_genimpute/CEDAR\
  --output_name CEDAR\
  --outdir CEDAR\
  --impute_PAR true\
  --impute_non_PAR true
```

#### Manual QC steps

- Check the <output_prefix>.imiss file for samples with large proportion of missing genotypes (e.g. > 5%). These samples are likely to have poor genotyping quality and should probably the excluded from the analysis before continuing. Remove these inviduals from the original plink file and re-run the genimpute workflow.

## Step 2: RNA-seq quantification with eQTL-Catalogue/rnaseq

The [eQTL-Catalogue/rnaseq](https://github.com/eQTL-Catalogue/rnaseq) workflow is inspired by the [nf-core/rnaseq](https://nf-co.re/rnaseq) workflow and performs adapter trimming (TrimGalore), alignment to the reference genome (HISAT2),  gene and exon-level read counting (featureCounts), read coverage visualisation (deepTools), genotype concordance checks (qtltools MBV), splice junction quantification (LeafCutter) and transcript expression quantification (Salmon, txrevise).

![rnaseq_workflow_schema](workflow_execution_files/rnaseq_metromap.png)

#### Dowload the workflow from GitHub

```bash
git clone https://github.com/eQTL-Catalogue/rnaseq.git
cd rnaseq
```

#### Input
1. Transcriptome reference annotations

Inside the rnaseq workflow directory, you first need to download the reference annotations corresponding to Ensembl 105/GENCODE 39 from here:

```bash
wget ftp://ftp.ebi.ac.uk/pub/databases/spot/eQTL/references/rnaseq_complete_reference_290322.tar.gz
tar -xzvf rnaseq_complete_reference_290322.tar.gz
```

This will create the rnaseq_complete_reference dirctory containing the following files:
 - HISAT2 index (GRCh38/Ensembl 105)
 - GENCODE v39 transriptome annotations for gene-level, exon-level and trancriptome-level quantification.
 - Pre-computed txrevise annotations based on Ensembl 105 and FANTOM5 CAGE data.
 - Molecular trait metadata for gene expression, exon expression, transcript usage and txrevise phenotypes.

2. Raw RNA-seq data in fastq format. 
  - Is it paired-end or single-end? (Do you have one or two fastq files per sample?)
  - Is it stranded or unstranded?
  - Paths to the fastq files can be passed with the readPathsFile parameter. See example files for [paired-end](https://github.com/eQTL-Catalogue/rnaseq/blob/master/data/read_paths_GEUVADIS_GBR20.tsv) and [single-end](https://github.com/eQTL-Catalogue/rnaseq/blob/master/data/read_paths_GEUVADIS_GBR20_singleEnd.tsv) data from the GEUVADIS_GBR20 test dataset.

3. Imputed genotypes in VCF format (from the genimpute workflow). These are required to check genotype condordance between the VCF files and the RNA-seq data using the [QTLtools MBV](https://doi.org/10.1093/bioinformatics/btx074) method.

If you have genotyping microarray data, you can obtain the imputed VCF in correct format using the genimpute workflow from Step 1 of this tutorial. 

To run the workflow on the [GEUVADIS_GBR20](https://doi.org/10.5281/zenodo.6391156) test dataset, you can obtain the corresponding VCF from Zenodo:

```bash
wget https://zenodo.org/record/6391156/files/GEUVADIS_GBR20.vcf.gz
```

#### Output
Raw gene expression, exon expression, transcript usage, txevise event usage and leafcutter splice-junction usage matrices in a format suitable for the eQTL-Catalogue/qcnorm workflow (Step 3).

#### Running the workflow

##### Paired-end, unstranded
```bash
nextflow run main.nf\
 -profile tartu_hpc\
  -resume \
 --readPathsFile data/read_paths_GEUVADIS_GBR20.tsv\
 --unstranded\
 --run_mbv\
 --mbv_vcf GEUVADIS_GBR20.vcf.gz
```

##### Single-end, unstranded
```bash
nextflow run main.nf\
 -profile tartu_hpc\
  -resume \
 --readPathsFile data/read_paths_GEUVADIS_GBR20_SE.tsv\
 --unstranded\
 --singleEnd\
 --run_mbv\
 --mbv_vcf GEUVADIS_GBR20.vcf.gz
```

##### Paired-end, stranded
(Note that this example will complete, but ignores ~50% of the reads because the GEUVADIS dataset is unstranded)
```bash
nextflow run main.nf\
 -profile tartu_hpc\
  -resume \
 --readPathsFile data/read_paths_GEUVADIS_GBR20.tsv\
 --reverse_stranded\
 --run_mbv\
 --mbv_vcf GEUVADIS_GBR20.vcf.gz
```

#### Other useful options
Use the `-executor.queueSize` option to limit the number alignment jobs running in parallel to avoid too much load on the disks.


## Step 3: Gene expression and genotype data normalisation and QC with eQTL-Catalogue/qcnorm

The [eQTL-Catalogue/qcnorm workflow](https://github.com/eQTL-Catalogue/qcnorm) that takes raw results from the [eQTL-Catalogue/rnaseq](https://github.com/eQTL-Catalogue/rnaseq) workflow and applies appropriate normalisation techniques for each quantification method. Gene and exon counts are quantile normalised using the cqn R package before inverse normal transformation is applied. In contrast, transcript and splice-junction quantification results are converted into proportional estimates before inverse normal transformation is applied. The workflow also produces a QC report in html format containing the PCA and MDS plots of the gene expression data, as well as concordance checks for biological sex and genotype data.

#### Dowload the workflow from GitHub

```bash
git clone https://github.com/eQTL-Catalogue/qcnorm.git
cd qcnorm
```

#### Input
1. `--vcf_file`: **Absolute path** to mputed genotypes from the genimpute workflow
2. `--quant_results_path`: **Absolute path** to RNA-seq quantification results from the [eQTL-Catalogue/rnaseq] workflow.
3. `--sample_meta_path`: **Absolute path** to the sample metadata file. See here for an example from the [GEUVADIS_GBR20 dataset](workflow_execution_files/GEUVADIS_GBR20_sample_metadata.tsv). 
Required columns: sample_id, genotype_id, qtl_group, sex, genotype_qc_passed, rna_qc_passed, study.

For the GEUVADIS_GBR20 dataset, you can download the sample metadata file from Zenodo:

```bash
wget https://zenodo.org/record/6391156/files/GEUVADIS_GBR20_sample_metadata.tsv
```

Note that all three main inputs (`--quant_results_path`,`--vcf_file` and `--sample_meta_path`) should be **absolute paths** to the corresponding files or folders. This ensures that in Step 4, the [eQTL-Catalogue/qtlmap] workflow is also able to find these files. 


4. Molecular trait metadata files 

These can be downloaded as part of the eQTL-Caltalogue/rnaseq workflow reference dataset:

```bash
wget ftp://ftp.ebi.ac.uk/pub/databases/spot/eQTL/references/rnaseq_complete_reference_290322.tar.gz
tar -xzvf rnaseq_complete_reference_290322.tar.gz
```

5. Reference population genotype dataset

This dataset is used to project individuals in the VCF file to the 1000 Genomes reference populations:

```bash
wget https://zenodo.org/record/6935520/files/popassign_complete_reference_280722.tar.gz
tar -xzvf popassign_complete_reference_280722.tar.gz
```


#### Output
 `--outdir`: Absolute path to qcnorm output folder containing normalised molecular trait matrices in a format suitable for the qtlmap workflow. Relative path will also work here, but makes it more difficult to run qltmap workflow in the next step.

#### Running the workflow
```bash
nextflow run main.nf -profile tartu_hpc \
 -resume\
 --study_name GEUVADIS_GBR20\
 --vcf_file /<absolute_path_to>/GEUVADIS_GBR20.vcf.gz\
 --quant_results_path /<absolute_path_to>/rnaseq/results\
 --sample_meta_path /<absolute_path_to>/GEUVADIS_GBR20_sample_metadata.tsv\
 --skip_exon_norm true\
 --skip_tx_norm true\
 --skip_txrev_norm true\
 --skip_leafcutter_norm true\
 --outdir /<absolute_path_to>/GEUVADIS_GBR20_qcnorm
```

To include all quantification methods into the normalisation, just remove the `--skip_XXX_norm` parameters:

```bash
nextflow run main.nf -profile tartu_hpc \
 -resume\
 --study_name GEUVADIS_GBR20\
 --vcf_file /<absolute_path_to>/GEUVADIS_GBR20.vcf.gz\
 --quant_results_path /<absolute_path_to>/rnaseq/results\
 --sample_meta_path /<absolute_path_to>/GEUVADIS_GBR20_sample_metadata.tsv\
 --outdir /<absolute_path_to>/GEUVADIS_GBR20_qcnorm
```


#### Manual QC steps

1. Check genotype concordance between the imputed genotypes and aligned RNA-seq reads. The summarised QTLtools mbv output is stored in the `QC/<study_name>_MBV_best_matches_matrix.tsv` file. Correct any obvious sample swaps between RNA-seq and genotype files. Exclude RNA-seq samples that do not match any individuals in the genotype data by setting the `genotype_qc_passed` field to FALSE in the sample metadata file. Also exclude RNA-seq samples that match more than one individual in the genotype data as this could be a sign of cross-contamination between RNA samples (NOTE: make sure that each individual is present only once in the genotype data and your data does not contain any monoxygotic twins.). 
2. Study the 'pop_assing/relatedness_matrix.tsv' file to ensure that there are no related individuals in the genotype data. Relatedness values > 0.2 are an obvious concern.
3. Check the gene expression PCA and MDS plots in the `QC/<study_name>_QC_report.html` file. Exclude any obvious outliers by setting `rna_qc_passed` field to FALSE in the sample metadata file. 
4. Check of the expression of sex-specific genes is consistent with the annotated sex of the samples. Fix missing or mis-annotated sex in the sample metadata file. Note that high simultaneous expression of both XIST (female-specifc) and Y chromosome genes (male-specifc) can be a good indiciation of RNA cross-contamination between two samples. This is often concordant with the results seen in the RNA-seq analysis.


### Normalising gene expression data only

If you already have an RNA-seq read count matrix and do not want to re-run the rnaseq workflow, then you can use the qcorm to just obtain the normalised gene expression matrix (cqn normlisation followed by inverse normal transformation).

An example count matrix from the GEUVADIS_GBR20 dataset can be downloaded from Zenodo:

```bash
wget https://zenodo.org/record/6631875/files/GEUVADIS_GBR20_gene_counts.tsv.gz
```

And then, qcnorm can be run like this:

```bash
nextflow run main.nf -profile tartu_hpc -resume\
 -entry norm_only\
 --study_name GEUVADIS_GBR20\
 --ge_exp_matrix_path GEUVADIS_GBR20_gene_counts.tsv.gz\
 --sample_meta_path GEUVADIS_GBR20_sample_metadata.tsv\
 --skip_exon_norm true\
 --skip_tx_norm true\
 --skip_txrev_norm true\
 --skip_leafcutter_norm \
 --outdir GEUVADIS_GBR20_qcnorm_ge
```

## Step 4: QTL analysis and fine mapping with eQTL-Catalogue/qtlmap

The [eQTL-Catalogue/qtlmap](https://github.com/eQTL-Catalogue/qtlmap) workflow takes normalised molecular trait matrix along with metadata from the [qcnorm](#step-3-gene-expression-and-genotype-data-normalisation-and-qc-with-eqtl-catalogueqcnorm) workflow and imputed genotypes from the [genimpute](#step-1-genotype-imputation-with-eqtl-cataloguegenimpute) workflow and uses the fastQTL tool to test for association between genetic variants located near each molecular trait (e.g. +/- 1Mb around the gene) and the normalised trait value. These associations are referred to cis quantitative trait loci (cis-QTLs). To account for unmeasured confounders and population structure, the workflow also calculates principal components of the trait and genotype matrices and includes those as covariates in the linear model. Finally, the workflow also performs statistical finemapping using the susieR software. The summary results created by the qtlmap workflow do not contain any individual-level data and follow the formatting conventions of the eQTL Catalogue, making it easy to integrate new datasets with the existing ones available from the eQTL Catalogue.

![qtlmap_workflow_schema](workflow_execution_files/qtlmap_metromap.png)

#### Dowload the workflow from GitHub

```bash
git clone https://github.com/eQTL-Catalogue/qtlmap.git
cd qtlmap
```

#### Input
1. Normalised moleocular trait files from the qcnorm workflow. **NOTE:** The studyFile from qcnorm `(qcnorm_output_directory>/<study_name>/<study_name>_qtlmap_inputs.tsv)` contains paths relative to the `--outdir` parameter. If you specified `--outdir` with absolute path, then most paths in the studyFile should also be ansolute paths.

2. The same molecular trait metadata files that were used by the rnaseq and qcnorm workflows. 

Either create a symlink to existing rnaseq_complete_reference folder or download again from the eQTL Catalogue FTP server:

```bash
wget ftp://ftp.ebi.ac.uk/pub/databases/spot/eQTL/references/rnaseq_complete_reference_290322.tar.gz
tar -xzvf rnaseq_complete_reference_290322.tar.gz
```

Note that if you did not impute the genotypes with genimpute workflow then you should make sure that VCF file contains bi-allelic variants only (bcftools view -m2 -M2). 

3. Mapping file form unique variant ids (CHR_POS_REF_ALT) to rsids (--varid_rsid_map_file parameter).

The mapping file can be downloaded from Zenodo:

```bash
wget https://zenodo.org/record/6034023/files/dbSNP_b151_GRCh38p7_splitted_var_rsid.vcf.gz
```

#### Output

#### Running the workflow

```bash
nextflow run main.nf -profile eqtl_catalogue\
  --studyFile <qcnorm_output_directory>/<study_name>/<study_name>_qtlmap_inputs.tsv\
  --vcf_has_R2_field FALSE\
  --varid_rsid_map_file dbSNP_b151_GRCh38p7_splitted_var_rsid.vcf.gz\
  --n_batches 200
```

### Running the workflow on the CEDAR dataset

##### Download input data

1. Make a new folder for the input data

```bash
mkdir data
cd data
```

2. Download imputed genotypes (from the eQTL-Catalogue/genimpute workflow)

```bash
wget https://zenodo.org/record/6171348/files/CEDAR_genimpute_200921.vcf.gz
wget https://zenodo.org/record/6171348/files/CEDAR_genimpute_200921.vcf.gz.csi
```

3. Download normalised gene expression matrix (from the eQTL-Catalogue/qcnorm workflow)

```bash
wget https://zenodo.org/record/6171348/files/CEDAR.platelet.tsv.gz
```

4. Download sample metadata

```bash
wget https://zenodo.org/record/6171348/files/CEDAR_sample_metadata.tsv
```

5. Download molecular trait metadata

```bash
wget https://zenodo.org/record/3366011/files/HumanHT-12_V4_Ensembl_96_phenotype_metadata.tsv.gz
```

6. Study file mapping all of the input files to correct workflow parameters

```bash
wget https://raw.githubusercontent.com/eQTL-Catalogue/eQTL-Catalogue-resources/master/tutorials/CEDAR_study_file.tsv
```

7. Download mapping from unique variant ids to rsids

```bash
wget https://zenodo.org/record/6034023/files/dbSNP_b151_GRCh38p7_splitted_var_rsid.vcf.gz
```

#### Run qtlmap

```bash
nextflow run main.nf -profile tartu_hpc\
   --studyFile data/CEDAR_study_file.tsv\
    --vcf_has_R2_field true\
    --run_permutation true\
    --run_nominal true\
    --run_susie true\
    --vcf_genotype_field DS\
    --n_batches 200\
    --covariates sex\
    --varid_rsid_map_file data/dbSNP_b151_GRCh38p7_splitted_var_rsid.vcf.gz\
    -resume
```
