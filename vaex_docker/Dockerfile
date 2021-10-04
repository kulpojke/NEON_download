FROM ubuntu:focal-20210921

RUN apt update \
    && apt install python3 \
    python3-pip \
    build-essential \
    && apt-get build-dep hdf5

RUN pip3 install vaex


