# Running the dummy Nextflow workflow using TESK

## Log in to Kubernetes cluster
In order to be able to pass files to and from a pipeline, you need to start Nextflow jobs on TESK while logged in to same Kubernetes cluster where TESK will run the jobs. The login node and executor nodes must share the same filesystem.

Instructions below have been tested for CSC Rahti cloud running on RedHat OpenShift. Instructions will need to be amended for other cloud types.

1. Set up configuration variables

        # Cloud parameters
        export CLOUD_BASE_URL=c03.k8s-popup.csc.fi:8443
        export CLOUD_NAMESPACE=tesk-cineca
        export NEXTFLOW_POD=nextflow-dockerhub-7-9bdlm

        # OpenShift command line tools release
        export OC_RELEASE_URL=https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz

1. Download command line `oc` tool (see original instructions in [Rahti cloud documentation](https://docs.csc.fi/cloud/rahti/usage/cli/#how-to-install-the-oc-tool)):
        wget -qO- ${OC_RELEASE_URL} \
        | tar --extract --gzip --wildcards --strip-components 1 --file=/dev/stdin '*/oc'

1. In your browser, go to https://${CLOUD_BASE_URL}/console/command-line. Copy and execute the `./oc login ...` command.
1. Switch to the necessary namespace: `./oc project ${CLOUD_NAMESPACE}`
1. RSH to the required pod: `./oc rsh ${NEXTFLOW_POD}`

## Run the workflow
Transfer the necessary files to the pod. Then run:
```bash
export DOCKER_IMAGE=centos
export WORK_DIR=/mnt
export NXF_MODE=ga4gh
export NXF_EXECUTOR=tes
export NXF_EXECUTOR_TES_ENDPOINT='https://tesk-cineca.c03.k8s-popup.csc.fi'
export NXF_DEBUG=3
nextflow run main.nf -with-docker ${DOCKER_IMAGE} -w ${WORK_DIR}
```

Important considerations & known limitations:
* It is important not to use a trailing slash when specifying the endpoint.
* Also it is mandatory to include a Docker image to run.
* Specifying memory requirements in Nextflow processes (e.g. `memory '100KB'`). If this is done, the task will hang seemingly forever and never complete.

## Building Nextflow from source (optional)
Since Nextflow support for TES is in alpha version and may contain multiple bugs, we may sometimes make changes to the Nextflow code. Until they are incorporated into master and released, we'll have to build Nextflow from source to make use of those modifications.

The commands to build Nextflow from scratch are as follows (make sure to substitute the correct fork and branch names):

```bash
git clone https://github.com/tskir/nextflow
cd nextflow
git checkout ga4gh-test-file-type
make compile
cd ..
```

To use this installation instead of system-wide Nextflow, run `bash nextflow/launch.sh [flags]`.
