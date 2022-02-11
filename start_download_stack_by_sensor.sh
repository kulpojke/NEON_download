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

SAVEPATH=$1
SITE=$2
STARTDATE=$3
ENDDATE=$4
APITOKEN=$5

#docker build r_docker -t r_docker && \
docker run --rm -it -v $SAVEPATH:/out --user $(id -u):$(id -g) quay.io/kulpojke/neon-timeseries:shafe6cf06 $SITE $STARTDATE $ENDDATE $APITOKEN

# ./start_download_stack_by_sensor.sh /home/michael/data/ABBY ABBY 2020-07 2020-07 $TOKEN
