# Running Nextflow workflows using TESK

This document contains instructions on how to run federated analysis workflows. The protocol for running them is the same; the only difference is the actual Nextflow workflow file to be run, and its parameters. Currently, there are two workflows available:
* A simple “Hello world” to test your setup. This is available in file [`hello_world.nf`](../demonstrators/hello-world/hello_world.nf).
* eQTL workflow in the [eqtl_workflow](../demonstrators/4.3.3-eqtl) directory. See detailed instructions there.

## Log in to Kubernetes cluster
In order to be able to pass files to and from a pipeline, you need to start Nextflow jobs on TESK while logged in to same Kubernetes cluster where TESK will run the jobs. The login node and executor nodes must share the same filesystem.

Instructions below have been tested for CSC Rahti cloud running on RedHat OpenShift. Instructions will need to be amended for other cloud types.

1. Set up configuration variables

        # Cloud parameters
        export CLOUD_BASE_URL=c03.k8s-popup.csc.fi:8443
        export CLOUD_NAMESPACE=tesk-cineca

        # OpenShift command line tools release
        export OC_RELEASE_URL=https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz

1. Download command line `oc` tool (see original instructions in [Rahti cloud documentation](https://docs.csc.fi/cloud/rahti/usage/cli/#how-to-install-the-oc-tool))

        wget -qO- ${OC_RELEASE_URL} \
        | tar --extract --gzip --wildcards --strip-components 1 --file=/dev/stdin '*/oc'
1. In your browser, go to `https://${CLOUD_BASE_URL}/console/command-line`. Copy and execute the `./oc login ...` command.
1. Switch to the necessary namespace: `./oc project ${CLOUD_NAMESPACE}`.
1. List all pods using the command: `./oc get pods`. Find pod which name starts with `nextflow-dockerhub`. Put it into `NEXTFLOW_POD` variable.
1. RSH to the required pod: `./oc rsh ${NEXTFLOW_POD}`

## Prepare the execution environment
Transfer the necessary files to the pod. Make sure to put all of them into a file system which is shared between the pod you're in (“login pod”), and the pods which TES installation will use to execute the workflow steps (“executor pods”).

Set the common environment variables:
```bash
export NXF_MODE=ga4gh
export NXF_EXECUTOR=tes
export NXF_EXECUTOR_TES_ENDPOINT='https://tesk-cineca.c03.k8s-popup.csc.fi'
export NXF_DEBUG=3
```

## Run the pipeline
After the previous steps are done, you are ready to run the pipeline. The actual pipeline to be run and its parameters will vary depending on your use case. To run the simplest “hello world” pipeline:
```bash
nextflow run hello_world.nf -with-docker centos
```

See subdirectories for specific pipeline for instructions on how to run them.

## Considerations & known limitations of running Nextflow workflows with TES
* It is important not to use a trailing slash when specifying the endpoint.
* It is mandatory to specify a Docker image to run.
* Specifying memory requirements in Nextflow processes (e.g. `memory '100KB'`). If this is done, the task will hang seemingly forever and never complete. See https://github.com/CINECA-project/wp4-federated-joint-cohort-analysis/issues/14.

## Note on file transfer
To transfer files to and from a pod, use `./oc rsync /home/user/dir ${NEXTFLOW_POD}:/tmp`. Note that the second parameter is the _parent_ directory for the sync, so that this example command will create `/tmp/dir` and put contents of `/home/user/dir` in there.
