FROM alpine:3.13.2

# General dependencies
RUN apk add autoconf bash bzip2-dev curl-dev gcc git libbz2 libressl-dev linux-headers make musl-dev ncurses-dev \
    openjdk11-jre perl py3-pip python3-dev wget xz-dev zlib-dev

# Latest htslib, samtools, and bcftools versions (required for certain functionality)
RUN git clone --branch develop git://github.com/samtools/htslib.git && \
    cd htslib && git submodule update --init --recursive && make -j `nproc` && make install && \
    cd .. && rm -rf htslib
RUN git clone --branch develop git://github.com/samtools/bcftools.git && \
    cd bcftools && autoheader && autoconf && ./configure && make -j `nproc` && make install && \
    cd .. && rm -rf bcftools
RUN git clone --branch develop git://github.com/samtools/samtools.git && \
    cd samtools && autoheader && autoconf && ./configure && make -j `nproc` && make install && \
    cd .. && rm -rf samtools

# Picardtools
RUN cd / && wget -q https://github.com/broadinstitute/picard/releases/download/2.24.2/picard.jar

# EGA Python client
RUN pip3 install pyega3 --upgrade
