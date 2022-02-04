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

docker run --rm -it -v $SAVEPATH:/out --user $(id -u):$(id -g) quay.io/kulpojke/neon-timeseries:ts_construct-0d0154b $SITE $STARTDATE $ENDDATE $APITOKEN

# ./start_download.sh /media/data/Downloads/neon SOAP 2020-01 2020-07 $TOKEN
