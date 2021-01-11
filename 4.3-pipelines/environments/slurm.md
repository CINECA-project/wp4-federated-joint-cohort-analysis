# Running Nextflow workflows using SLURM 

The same hello_world.nf workflow can also be executed using the SLURM resource manager installed at many compute clusters. For example, at the at [University of Tartu HPC](https://hpc.ut.ee/en/home/), we can use the following command:

```bash
nextflow hello_world.nf -with-singularity centos \
        -process.executor slurm \
        -process.queue main
```

Note that we had to replace `-with-docker` with `-with-singularity`, because Docker is not supported in that environment. We also had to specify the executor and the name of the queue. 
