library("readxl")
library("dplyr")

#Import CEDAR sample metadata
sample_meta = readr::read_tsv("4.4-federated-eQTL-analysis/cohort_metadata/H3Africa/CEDAR_sample_metadata.tsv") %>%
  dplyr::filter(genotype_qc_passed == TRUE, rna_qc_passed == TRUE) %>%
  dplyr::filter(qtl_group == "T-cell_CD4")

#Make OneK1K biosamples table
biosamples = read_xlsx("4.4-federated-eQTL-analysis/cohort_metadata/Beacon-v2-Models_CINECA_UK1.xlsx", sheet = "biosamples")
biosamples = biosamples[1:290,] %>%
  dplyr::mutate(collectionDate = "2023-02-25") %>%
  dplyr::mutate(id = sample_meta$genotype_id) %>%
  dplyr::mutate(individualId = sample_meta$genotype_id) %>%
  dplyr::mutate(info.BioSamples.accession = NA) %>%
  dplyr::mutate(info.BioSamples.externalUrl = NA) %>%
  dplyr::mutate(info.EGAsampleId = NA) %>%
  dplyr::mutate(info.sampleName = sample_meta$genotype_id)
write.table(biosamples, "4.4-federated-eQTL-analysis/cohort_metadata/H3Africa/tsv_files/biosamples.tsv", sep = "\t", quote = F, row.names = F, na = "")
  
#And indindividuals table
individuals = read_xlsx("4.4-federated-eQTL-analysis/cohort_metadata/Beacon-v2-Models_CINECA_UK1.xlsx", sheet = "individuals")
individuals = individuals[1:290,] %>%
  dplyr::mutate(diseases_diseaseCode.label = NA) %>%
  dplyr::mutate(diseases_diseaseCode.id = NA) %>%
  dplyr::mutate(ethnicity.id = NA) %>%
  dplyr::mutate(ethnicity.label = NA) %>%
  dplyr::mutate(geographicOrigin.id = NA) %>%
  dplyr::mutate(geographicOrigin.label = NA) %>%
  dplyr::mutate(id = sample_meta$genotype_id) %>%
  dplyr::mutate(interventionsOrProcedures_procedureCode.id = NA) %>%
  dplyr::mutate(interventionsOrProcedures_procedureCode.label = NA)
write.table(individuals, "4.4-federated-eQTL-analysis/cohort_metadata/H3Africa/tsv_files/individuals.tsv", sep = "\t", quote = F, row.names = F, na = "")

#And runs
runs = read_xlsx("4.4-federated-eQTL-analysis/cohort_metadata/Beacon-v2-Models_CINECA_UK1.xlsx", sheet = "runs")
runs = runs[1:290,] %>%
  dplyr::mutate(biosampleId = sample_meta$genotype_id) %>%
  dplyr::mutate(individualId = sample_meta$genotype_id) %>%
  dplyr::mutate(libraryStrategy = "Genotyping microarray") %>%
  dplyr::mutate(platformModel.label = "HumanOmniExpress-12v1")
rna_runs = runs %>%
  dplyr::mutate(libraryStrategy = "Gene expression microarray") %>%
  dplyr::mutate(platformModel.label = "HumanHT-12_V4")
all_runs = dplyr::bind_rows(runs, rna_runs)
all_runs = dplyr::mutate(all_runs, id = paste0("RUN", c(1:nrow(all_runs))))
write.table(all_runs, "4.4-federated-eQTL-analysis/cohort_metadata/H3Africa/tsv_files/runs.tsv", sep = "\t", quote = F, row.names = F, na = "")





  