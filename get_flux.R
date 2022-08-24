#!/usr/bin/env Rscript

# usage:
# mkdir -p /data/NEON/ABBY
# Rscript get_flux.R ABBY '2020-07' '2020-07' $TOKEN /data/NEON/ABBY

# test args
# site      <- 'TEAK'
# startdate <- '2019-06'
# enddate   <- '2021-07'
# api_token <-
# savepath  <- paste0('/data/', site)

# parse args and set path
args = commandArgs(trailingOnly=TRUE)
site      <- args[1]
startdate <- args[2]
enddate   <- args[3]
api_token <- args[4]
savepath  <- args[5]

# print a message
print(paste0('Files will be saved internally to ', savepath))
print('---------------------------------------')


# we'll need these
library(neonUtilities)
library(raster)
library(rgdal)
library(dplyr)
library(rhdf5)

# do this weird R thing
options(stringsAsFactors=F)

# make sure savepath exits
dir.create(savepath, recursive=TRUE, showWarnings=FALSE)

# product IDs  and global variables
fluxID    <- 'DP4.00200.001'

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
print('Getting tower footprints...')
footprint <- footRaster(filepath=filepath)

# create dir for footprints
foot_path <- file.path(savepath, 'footprints')

dir.create(foot_path, recursive=TRUE, showWarnings=FALSE)

# Iterate through the raster layers saving tifs
i <- 1
for (lyr in footprint@layers) {

  # make filename
  fname <- paste(foot_path, tail(strsplit(names(lyr), "\\.")[[1]], n=1), sep="/")
  fname <- paste0(fname, ".tiff")

  # change all negatives to -9999 (no data)
  ras <- reclassify(lyr, cbind(-Inf, 0, -9999), right=FALSE)

  # write tiff
  print(paste0('    ... writing ', fname))
  writeRaster(ras, filename=fname, overwrite = TRUE)

  i <- i + 1
  }

# save the summary layer ( [[1]] ) of the footprint, in same fashion as others
footsum <- footprint[[1]]
fname <- paste(foot_path, "summary.tiff", sep="/")
print(paste0('    ... writing ', fname))
ras <- reclassify(footsum, cbind(-Inf, 0, -9999), right=FALSE)
writeRaster(ras, filename=fname, overwrite = TRUE)

# garbage collect, just in case
gc()


# -------------- hyperspectral ---------------

# extract the extent of the footprint rasters
e <- extent(footsum)

# get the mins coords out using this ridiculous syntax
xmin <- xmin(e)
ymin <- ymin(e)
xmax <- xmax(e)
ymax <- ymax(e)

# make a list to form a 1000m grid to get all needed tiles
easting <- seq(xmin, xmax, 1000)
e_len <- length(easting)
n_len <- length(seq(ymin , ymax, 1000))
northing <- rep(seq(ymin , ymax, 1000), e_len)

east_idx <- rep(1, n_len)
for (i in seq(2, n_len)) {
  east_idx <- c(east_idx, rep(i, n_len))
}

easting <- easting[east_idx]

# figure out needed years
start_year <- strsplit(startdate, '-')[[1]][1]
end_year <- strsplit(enddate, '-')[[1]][1]

if (start_year == end_year) {
  years <- list(start_year)
} else {
  s <- strtoi(start_year)
  e <- strtoi(end_year)
  ys <- s:e
  years <- list(start_year, end_year)
}

# make sure dir exists
p <- paste(savepath, "hyperspectral", sep='/')
dir.create(p, recursive=TRUE, showWarnings=FALSE)

# download hyperspectral for each year
for (y in years) {
  R_is_dumb <- tryCatch(
    byTileAOP(dpID = "DP3.30006.001",
              site = site,
              year = y,
              check.size = FALSE,
              easting = easting,
              northing = northing,
              savepath = p,
              token = api_token),
    warning = function(cond) {
      print(cond)
    },
    error = function(cond) {
      print(cond)
    },
    finally = {
      message(paste("Hyperspectral data saved to ", p))
    }
  )

}

print('Download of flux data complete!')
