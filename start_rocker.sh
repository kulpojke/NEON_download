#!/bin/sh

docker build rocker_docker -t rocker_docker && \
docker run --rm -it -v $PWD:/work -v /media/data/NEON:/data -p 8787:8787 -e DISABLE_AUTH=true  rocker_docker