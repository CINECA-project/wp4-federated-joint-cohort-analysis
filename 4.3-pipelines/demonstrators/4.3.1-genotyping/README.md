# Joint cohort genotyping demonstrator pipeline

This simple demonstrator pipeline follows the basic principles of the [common federation approach](../../README.md) adopted by WP4. The goal is to demonstrate how a simple metric (in this case, allele frequency) can be computed in a federated manner.

Step A (private step) reduces the individual level genotypes to dataset-specific allele counts, which are then exported and collected in a central location.

Step B (meta-analysis step) then computes the final allele frequencies based on the results collected from step A.

The instructions below demonstrate how the pipelie can be run on two separate datasets using two different execution environments.

## Step A, dataset 1: GIAB
...

## Step A, dataset 2: EGA synthetic dataset
...

## Step B, result integration
...
