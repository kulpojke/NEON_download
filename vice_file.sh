#!/bin/sh

SITE=$1
STARTDATE=$2
ENDDATE=$3
APITOKEN=$4

# run the app
Rscript /file.R $SITE $STARTDATE $ENDDATE $APITOKEN /root/work
