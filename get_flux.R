#!/usr/bin/env Rscript


# parse args and set path
args = commandArgs(trailingOnly=TRUE)
site      <- args[1]
startdate <- args[2]
enddate   <- args[3]
api_token <- args[4]
savepath  <- args[5]

# do this wierd R thing
options(stringsAsFactors=F)

# we'll need these
library(neonUtilities)
library(raster)
library(rgdal)
library(dplyr)
library(parallel)

# product IDs  and global variables
fluxID    <- 'DP4.00200.001'
soilCO2ID <- 'DP1.00095.001'
soilH2OID <- 'DP1.00094.001'
soilTID   <- 'DP1.00041.001'
precipID  <- 'DP1.00006.001'
timeIndex <- 1
interval  <- '1_minute'
ncores    <- detectCores()

#-------------- flux -------------------------
# bag the eddy flux data from the API
print('Downloading flux data.')
print('---------------------------------------')
zipsByProduct(dpID=fluxID, package='expanded',
              site=site,
              startdate=startdate, enddate=enddate,
              savepath=savepath,
              check.size=F, token=api_token)

# extract the level 4 data
print('Extracting flux data.')
print('---------------------------------------')
filepath <- file.path(savepath, 'filesToStack00200')
flux <- stackEddy(filepath=filepath,
                  level="dp04")

# get just the dataframe
flux <- flux[[1]]

# extract the columns of interest from the flux data
flux <- flux %>% select(timeBgn,
                        data.fluxCo2.nsae.flux,
                        qfqm.fluxCo2.nsae.qfFinl,
                        data.fluxTemp.nsae.flux,
                        qfqm.fluxTemp.nsae.qfFinl,
                        data.fluxH2o.nsae.flux,
                        qfqm.fluxH2o.nsae.qfFinl)

# garbage collect, just in case
gc()

#-------------- footprint -------------------
# get the tower footprint
print('Getting tower footprint...')
footprint <- footRaster(filepath=filepath)

# create dir for footprints
foot_path <- file.path(savepath, paste0(site, '_footprints'))

if (!dir.exists(foot_path)) {
  dir.create(foot_path)
}
# save the summary layer ( [[1]] ) of the footprint
footsum <- footprint[[1]]
footsum <- reclassify(footsum, cbind(-Inf, 0, -9999), right=FALSE)

fname <- file.path(foot_path, paste(site, startdate, 'footprint.tif', sep='_'))

print(paste0('    ... saving tower footprint of dimension', dim(footsum), ' ...'))
writeRaster(footsum, filename=fname, overwrite = TRUE)

print(paste0('    ... footprint written as ', fname))

# remove rasters /stacks to free memory
rm(footsum)
rm(footprint)
gc()