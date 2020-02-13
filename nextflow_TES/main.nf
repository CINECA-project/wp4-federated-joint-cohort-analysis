#!/usr/bin/env nextflow

process say_hello {
    echo true
    // executor 'slurm'
    cpus 1
    time '1h'
    memory '100KB'
    // singularity.enabled true
    // singularity.autoMounts true
    // singularity.cacheDir "$baseDir/singularity_img/"
    // container 'kerimoff/pop_assign:latest'

    script:
    """
    echo hello_world
    """
}