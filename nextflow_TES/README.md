# Running Nextflow workflows using TESK

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
* It is mandatory to specify a Docker image to run.
* Specifying memory requirements in Nextflow processes (e.g. `memory '100KB'`). If this is done, the task will hang seemingly forever and never complete. See https://github.com/CINECA-project/wp4-federated-joint-cohort-analysis/issues/14.

## Note on file transfer
To transfer files to and from a pod, use `./oc rsync /home/user/dir ${NEXTFLOW_POD}:/tmp`. Note that the second parameter is the _parent_ directory for the sync, so that this example command will create `/tmp/dir` and put contents of `/home/user/dir` in there.

# Building Nextflow from source
Before building, install and select Java 8 as the default. In Ubuntu this can be done by running the commands:
```
sudo apt install openjdk-8-jdk
sudo update-alternatives --config java
# Then select Java 8 as the default
```

Build from source (make sure to substitute the correct fork and branch names):
```bash
git clone https://github.com/tskir/nextflow
cd nextflow
git checkout master
make -j `nproc` pack
cd ..
```

There are two ways to run this installation instead of system-wide Nextflow:
* You can run `bash nextflow/launch.sh [flags]`, but it has do be done on the same machine where you compiled it, otherwise the different baked-in paths will not match.
* You can transfer the self-contained binary generated in the `build/releases/` directory to the Kubernetes pod and run it there.

Note that every time you swap Nextflow versions, you must wipe the `.nextflow` directory, otherwise you might end up still using the old version.
