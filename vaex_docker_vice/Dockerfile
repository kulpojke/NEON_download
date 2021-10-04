FROM ubuntu:focal-20210921

RUN apt update \
    && apt install python3 \
    python3-pip \
    build-essential \
    && apt-get build-dep hdf5

RUN pip3 install vaex

COPY vice_csv2h5.sh /
COPY csv2h5.py /

WORKDIR /root/work

ENTRYPOINT [ "vice_csv5h5.sh" ]

