#!/usr/bin/env Rscript


# parse args and set path
args = commandArgs(trailingOnly=TRUE)
site      <- args[1]
startdate <- args[2]
enddate   <- args[3]
savepath  <- args[4]
api_token <- args[5]

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
interval  <- paste0(timeIndex, '_minute')
ncores    <- detectCores()

# -------------- function definitions --------------------------------------

sep_vertical <- function(sensor_data) {
  #' function to seperate sensor data into a list of dfs by verticalPosition
  #' @param sensor_data -- the sensor data as returned by neonUtilities::loadByProduct()

  # find the index of the  data coresponding to the time interval
  idx <- which(grepl(interval, names(sensor_data)), arr.ind=TRUE)
  # now get the data using the index
  df <- sensor_data[[idx]]
  if ("finalQF" %in% names(df)) {

    # get suffix finalQF file to be unambigous after merge
    sufx <- unlist(strsplit(names(sensor_data)[[idx]], '_'))[[1]]

    # rename the QF cols
    # this line is an exmaple of R making the simplest task unreadable and confusing
    df <- rename_with(df, .fn = ~paste0( ., sufx), .cols = finalQF)
  }

  # get the positions
  positions <- unique(df[c("verticalPosition")])[[1]]
  # make an empty list
  df_list <-  c()
  # seperate df by verticalPosition and put new dfs in list
  for (position in positions) {
    d <- df[df$verticalPosition == position,]
    # change timestamps to timeBgn to harmonize with flux data
    d$timeBgn <- d$startDateTime
    # drop some unneeded columns
    d <- select(d,
                -startDateTime,
                -endDateTime,
                -domainID,
                -verticalPosition,
                -release,
                -publicationDate,
                -siteID)
    # concat to list
    df_list <- c(df_list, setNames(list(d), paste0("z", position)))
  }
  return(df_list)
}


sep_horizontal <- function(list_of_dfs) {
  #' function to seperate each df in a list of dfs by horizontalPosition
  #' @param list_of_dfs -- the list of dfs

  # make an empty list
  df_list <- c()
  # seperate data by horizontalPosition for each df in list_of_dfs
  for (i in seq_along(list_of_dfs)) {
    z <- names(list_of_dfs)[i]
    df <- list_of_dfs[[i]]
    # get the positions
    positions <- unique(df[c("horizontalPosition")])[[1]]
    for (position in positions) {
      d <- df[df$horizontalPosition == position,]
      # drop some unneeded columns
      d <- select(d, -horizontalPosition)
      df_list <- c(df_list, setNames(list(d), paste0(z, "h", position)))
    }
  }
  return(df_list)
}


precip_prune <- function(precip_data) {
  #' function to select only the desired columns from the precip table

  # find the index of the interval appropriate data, prefer SECPRE but fall back
  # to PRIPRE (bc KNOWN ISSUE 2020-06-10). keep track of which with pri_sec
  print('in precip_prune')

  if (timeIndex == 30) {
    sufx = '_30min'
  } else { sufx = '_1min'}

  print(paste('sufx :', sufx))

  idx <- which(grepl(paste0('SECPRE', sufx), names(precip_data)), arr.ind=TRUE)
  pri_sec <- 2
  if (length(idx) != 1) {
    idx <- which(grepl(paste0('PRIPRE', sufx), names(precip_data)), arr.ind=TRUE)
    pri_sec <- 1
  }

  # now get the data using the index
  df <- precip_data[[idx]]
  print(class(df))
  # douple check to makes ure we are only dealing with one guage (is this true at all sites?)
  if (unique(df["verticalPosition"]) > 1){
    print(paste0('Warning there is ore than one verital position for sensors at ', site))
  }
  if (unique(df["horizontalPosition"]) > 1){
    print(paste0('Warning there is ore than one verital position for sensors at ', site))
  }

  # neaten the df before returnng it
  if (pri_sec ==2){
    # select the desired rows
    df <- df %>% select(startDateTime, secPrecipBulk, secPrecipExpUncert, secPrecipRangeQF, secPrecipSciRvwQF)
  } else {
    # select the desired rows
    df <- df %>% select(startDateTime, priPrecipBulk, priPrecipExpUncert, priPrecipRangeQF, priPrecipSciRvwQF)
  }

  # change startDateTime to timeBgn for consistency with flux
  df$timeBgn <- df$startDateTime
  df <- select(df, -startDateTime)

  return(df)
}


merge_dfs_list <- function(list_of_dfs) {
  #' Function to merge a list of dfs. Tags column names with sensor
  #' position taken from names(list_of_dfs).
  #' @param list_of_dfs -- the list of dfs
  for (i in 1:length(list_of_dfs)) {
    loc <- names(list_of_dfs)[[i]]
    df <- list_of_dfs[[i]]
    if (i==1) {
      df <- df %>% rename_with(~ paste(.x, loc, sep="_"), -timeBgn)
      data <- df
    } else {
      df <- df %>% rename_with(~ paste(.x, loc, sep="_"), -timeBgn)
      data <- inner_join(data, df, by="timeBgn")
    }
  }
  return(data)
}

# --------end of function definitions --------------------------------------


#-----initial soil characterization ----------
# get initial soil characterization (DP1.10047.001) if it is not already there
# also put the soil volumatric water content zip in there to get sensor_positions
soil_char_dir <-file.path(savepath, 'filesToStack10047')

if (!dir.exists(soil_char_dir)) {
  
  print('Downloading initial soil characterization (DP1.10047.001)')

  zipsByProduct(dpID='DP1.10047.001', package='expanded',
              site=site,
              startdate='2015-08', enddate='2021-06',
              savepath=savepath,
              check.size=F, token=api_token)

  # due to incorect sensor locations look at
  # readmeswcdepths.txt and 
  # swc_depths.csv which should be included

  #zipsByProduct(dpID=soilH2OID, package='expanded',
  #            site=site,
  #            startdate='2015-08', enddate='2015-08',
  #            savepath=savepath,
  #            check.size=F, token=api_token)

} else {
  print('Initial soil characterization (DP1.10047.001) is already present.')
}

#------------ soilCO2 ------------------------
# download the soilCO2 product
print('------------ soilCO2 ------------------------')
soilCO2 <- loadByProduct(soilCO2ID, site=site,
                         timeIndex=timeIndex, package="basic",
                         startdate=startdate, enddate=enddate,
                         check.size=F, nCores=ncores, token=api_token)

# seperate data by verticalPosition for soilCO2
soilCO2 <- sep_vertical(soilCO2)

# seperate soilCO2 by horizontalPosition
soilCO2 <- sep_horizontal(soilCO2)

# garbage collect, just in case
gc()

#------------ soilH2O ------------------------
print('------------ soilH2O ------------------------')
# download the soilH2O product
soilH2O <- loadByProduct(soilH2OID, site=site,
                         timeIndex=timeIndex, package="basic",
                         startdate=startdate, enddate=enddate,
                         check.size=F, nCores=ncores, token=api_token)

# seperate data by verticalPosition for soilH2O
soilH2O <- sep_vertical(soilH2O)

# seperate soilH2O by horizontalPosition
soilH2O <- sep_horizontal(soilH2O)

# garbage collect, just in case
gc()

#------------- soilT -------------------------
print('------------- soilT -------------------------')
# download the soilT product
soilT <- loadByProduct(soilTID, site=site,
                       timeIndex=timeIndex, package="basic",
                       startdate=startdate, enddate=enddate,
                       check.size=F, nCores=ncores, token=api_token)

# seperate data by verticalPosition for soilT
soilT <- sep_vertical(soilT)

# seperate soilT by horizontalPosition
soilT <- sep_horizontal(soilT)

# garbage collect, just in case
gc()

#------------- precip ------------------------
print('------------- precip -------------------------')
# download the precip product
precip <- loadByProduct(precipID, site=site,
                        timeIndex=timeIndex, package="basic",
                        startdate=startdate, enddate=enddate,
                        check.size=F, nCores=ncores, token=api_token)

# select the needed columns
precip <- precip_prune(precip)

#------------- merge -------------------------
print('------------- merge -------------------------')
# merge each list of dfs containing data from different sensor types
soilCO2 <- merge_dfs_list(soilCO2)
soilH2O <- merge_dfs_list(soilH2O)
soilT   <- merge_dfs_list(soilT)

# merge them all into a big soil df
soil <- soilCO2 %>%
  inner_join(soilH2O, by='timeBgn') %>%
  inner_join(soilT, by='timeBgn')

# remove unused stuff to free memory
rm(soilCO2)
rm(soilH2O)
rm(soilT)
gc()


# merge precip with the soil and flux data
data <- soil %>% inner_join(precip, by='timeBgn')

# make a filename
fname <- paste(savepath, paste0(site, '_', startdate, '_', enddate, '.csv'), sep = "/")

# write to csv
write.csv(data, fname)

# print a nice little message so the user knows something happened
print(paste0('Data written to ', fname))