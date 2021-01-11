# Nextflow technical considerations

## Building Nextflow from source
Before building, install and select Java 8 as the default. In Ubuntu this can be done by running the commands:
```
sudo apt install openjdk-8-jdk
sudo update-alternatives --config java
# Then select Java 8 as the default
```

Build from source (make sure to substitute the correct fork and branch names):
```bash
git clone https://github.com/nextflow-io/nextflow
cd nextflow
git checkout master
make packGA4GH
cd ..
```

Note that the default `make pack` will produce a binary which does **not** include GA4GH support, so you have to run `make packGA4GH` instead.

There are two ways to run this installation instead of system-wide Nextflow:
* You can run `bash nextflow/launch.sh [flags]`, but it has do be done on the same machine where you compiled it, otherwise the different baked-in paths will not match.
* You can transfer the self-contained binary generated in the `build/releases/` directory to the Kubernetes pod and run it there.

Note that every time you swap Nextflow versions, you must wipe the `.nextflow` directory, otherwise you might end up still using the old version.
