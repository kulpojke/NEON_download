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

SITE=$1
STARTDATE=$2
ENDDATE=$3
SITE_DIR=$4
APITOKEN=$5

# run get_flux in container
docker run -ti --rm -v "$PWD":/home/work -w /home/work --user $(id -u):$(id -g) quay.io/kulpojke/neon-timeseries:sha8cc4e44 Rscript src/get_flux.R $SITE $STARTDATE $ENDDATE $SITE_DIR $APITOKEN

# run select_comlpete_observation in container
docker run -ti --rm -v "$SITE_DIR":/home/work -w /home/work \
    --user $(id -u):$(id -g) \
    quay.io/kulpojke/neon-timeseries:py-shadd689ac python src\select_complete_observations.py \
        --site=TALL \
        --file_path=filesToStack00200