FROM ubuntu:20.04

# General dependencies
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -q update && apt-get -q -y upgrade && apt-get -y install \
    autoconf git gcc libz-dev libbz2-dev liblzma-dev libcurl4-openssl-dev libncurses5-dev make wget

# Latest htslib, samtools, and bcftools versions (required for certain functionality)
RUN git clone --branch develop git://github.com/samtools/htslib.git && \
    cd htslib && git submodule update --init --recursive && make -j `nproc`
RUN git clone --branch develop git://github.com/samtools/bcftools.git && \
    cd bcftools && autoheader && autoconf && ./configure && make -j `nproc` && make install
RUN git clone --branch develop git://github.com/samtools/samtools.git && \
    cd samtools && autoheader && autoconf && ./configure && make -j `nproc` && make install

# Picardtools
RUN cd / && wget -q https://github.com/broadinstitute/picard/releases/download/2.24.2/picard.jar
