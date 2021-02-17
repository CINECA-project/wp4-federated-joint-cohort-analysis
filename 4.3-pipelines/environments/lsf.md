# Running CINECA WP4 pipelines on LSF

## Installing Nextflow

Check if Nextflow is already installed and can be invoked as usual: `nextflow`.

If Nextflow is not installed, install it locally using `wget -qO- https://get.nextflow.io | bash` and then invoke as `./nextflow`.

## Adjusting the run parameters

### Executor settings

To make sure that Nextflow is using the LSF functionality and not just running the jobs on the login node, make sure to export the environment variable prior to running:
```bash
export NXF_EXECUTOR=lsf
```

### Using Singularity as a Docker replacement

If the LSF cluster in question does not support Docker (as is the case with the EMBL-EBI cluster), replace `-with-docker` flag with `-with-singularity`, keeping the same image name. It will be downloaded and repackaged into a Singularity image automatically.

### Caching Singularity images

The first time the Docker image is pulled and converted into the Singularity format, it may take a long time, depending on cluster performance, image size, and other factors. It is hence recommended that you set the `$NXF_SINGULARITY_CACHEDIR` to a location where the images will be cached. This location must be on a shared filesystem within the cluster.

**Important:** check if you have the `$SINGULARITY_CACHEDIR` variable already set up in your environment. If so, make sure that `$NXF_SINGULARITY_CACHEDIR` is set to the same location:
```bash
export NXF_SINGULARITY_CACHEDIR=$SINGULARITY_CACHEDIR
```

Otherwise Nextflow may get confused and in some cases will pull the image into one location but then try to load it from another. This appears to be a bug: https://github.com/nextflow-io/nextflow/issues/1659#issuecomment-780291808.
