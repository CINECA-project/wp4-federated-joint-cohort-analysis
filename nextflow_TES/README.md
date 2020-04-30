# Running the dummy Nextflow workflow using TESK

## Build Nextflow

Stock Nextflow support for TES is in alpha version and may contain multiple bugs. Hence, to run the pipelines, for now we will be using a forked version with the necessary changes introduced.

This fork will be periodically updated, and the code changes will be sent to main Nextflow repository. Once all changes are merged, we will revert to using stock Nextflow.

```bash
git clone https://github.com/tskir/nextflow
cd nextflow
git checkout ga4gh-test-file-type
make compile
cd ..
```

## Run the workflow

It is important not to use a trailing slash when specifying the endpoint. Also it is mandatory to include a Docker image to run.

```bash
export NXF_MODE=ga4gh
export NXF_EXECUTOR=tes
export NXF_EXECUTOR_TES_ENDPOINT='https://csc-tesk-test.rahtiapp.fi'
export NXF_DEBUG=3
bash nextflow/launch.sh run main.nf -with-docker alpine
```
