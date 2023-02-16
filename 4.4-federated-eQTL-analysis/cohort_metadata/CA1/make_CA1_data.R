library("readxl")
library("dplyr")

#Import OneK1K sample metadata
sex_table = readr::read_tsv("4.4-federated-eQTL-analysis/cohort_metadata/CA1/OneK1K_sex_table.tsv")
sample_meta = readr::read_tsv("4.4-federated-eQTL-analysis/cohort_metadata/CA1/OneK1K_CD4_Naive_sample_metadata.tsv") %>%
  dplyr::left_join(sex_table)
write.table(sample_meta, "~/Downloads/OneK1K_genotypes/OneK1K_CD4_Naive_sample_metadata.tsv", row.names = F, quote = F, sep = "\t")

#Make OneK1K biosamples table
biosamples = read_xlsx("4.4-federated-eQTL-analysis/cohort_metadata/Beacon-v2-Models_CINECA_UK1.xlsx", sheet = "biosamples")
biosamples = biosamples[1:981,] %>%
  dplyr::mutate(collectionDate = "2023-02-11") %>%
  dplyr::mutate(id = sample_meta$genotype_id) %>%
  dplyr::mutate(individualId = sample_meta$genotype_id) %>%
  dplyr::mutate(info.BioSamples.accession = NA) %>%
  dplyr::mutate(info.BioSamples.externalUrl = NA) %>%
  dplyr::mutate(info.EGAsampleId = NA) %>%
  dplyr::mutate(info.sampleName = sample_meta$genotype_id)
write.table(biosamples, "4.4-federated-eQTL-analysis/cohort_metadata/CA1_tsv_files/biosamples.tsv", sep = "\t", quote = F, row.names = F, na = "")
  
#And indindividuals table
individuals = read_xlsx("4.4-federated-eQTL-analysis/cohort_metadata/Beacon-v2-Models_CINECA_UK1.xlsx", sheet = "individuals")
individuals = individuals[1:981,] %>%
  dplyr::mutate(diseases_diseaseCode.label = NA) %>%
  dplyr::mutate(diseases_diseaseCode.id = NA) %>%
  dplyr::mutate(ethnicity.id = NA) %>%
  dplyr::mutate(ethnicity.label = NA) %>%
  dplyr::mutate(geographicOrigin.id = NA) %>%
  dplyr::mutate(geographicOrigin.label = NA) %>%
  dplyr::mutate(id = sample_meta$genotype_id) %>%
  dplyr::mutate(interventionsOrProcedures_procedureCode.id = NA) %>%
  dplyr::mutate(interventionsOrProcedures_procedureCode.label = NA)
write.table(individuals, "4.4-federated-eQTL-analysis/cohort_metadata/CA1_tsv_files/individuals.tsv", sep = "\t", quote = F, row.names = F, na = "")

#And runs
runs = read_xlsx("4.4-federated-eQTL-analysis/cohort_metadata/Beacon-v2-Models_CINECA_UK1.xlsx", sheet = "runs")
runs = runs[1:981,] %>%
  dplyr::mutate(biosampleId = sample_meta$genotype_id) %>%
  dplyr::mutate(individualId = sample_meta$genotype_id) %>%
  dplyr::mutate(libraryStrategy = "Genotyping microarray")
rna_runs = runs %>%
  dplyr::mutate(libraryStrategy = "RNA-seq")
all_runs = dplyr::bind_rows(runs, rna_runs)
all_runs = dplyr::mutate(all_runs, id = paste0("RUN", c(1:nrow(all_runs))))
write.table(all_runs, "4.4-federated-eQTL-analysis/cohort_metadata/CA1_tsv_files/runs.tsv", sep = "\t", quote = F, row.names = F, na = "")





  