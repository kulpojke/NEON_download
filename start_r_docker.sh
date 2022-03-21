#!/bin/sh

docker build temp_r_docker -t temp_r_docker && \
docker run --rm -it -v $PWD:/work -v /media/data:/data --user $(id -u):$(id -g) temp_r_docker