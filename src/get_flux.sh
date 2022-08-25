#!/bin/sh

while getopts ":h" option; do
   case $option in
      h) # display Help
        echo "SYNOPSIS"
        echo "     has args"
        echo "DESCRIPTION"
        echo "     does things"
        exit;;
   esac
done

script=$1
SITE=$2
STARTDATE=$3
ENDDATE=$4
OUT=$5
APITOKEN=$6

#docker build r_docker -t r_docker && \
#docker run --rm -it -v $SAVEPATH:/out --user $(id -u):$(id -g) quay.io/kulpojke/neon-timeseries:sha8cc4e44 R CMD check .
docker run -ti --rm -v "$PWD":/home/docker -w /home/docker --user $(id -u):$(id -g) quay.io/kulpojke/neon-timeseries:sha8cc4e44 Rscript $script $SITE $STARTDATE $ENDDATE $OUT $APITOKEN


#./src/get_flux.sh src/get_flux.R TALL '2020-07' '2020-08' TALL $TOKEN
