#!/bin/sh

SITE=$1
STARTDATE=$2
ENDDATE=$3
APITOKEN=$4

# run the app
Rscript file.R $SITE $STARTDATE $ENDDATE $APITOKEN

chmod -R 766 /savepath