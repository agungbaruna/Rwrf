#' This script is used for running the WRF model
#' Make sure You have installed WRF model & WRF Pre-Processing (WPS)
#' In this script, I have installed WRF model in ~/WRF directory
#' I have installed WRF-ARW with GFS input data
#' I can't provide for all WRF simulation, like WRF-Chem, WRF-Fire, and WRF-Hydro in this script

# Export library
library(lubridate, quietly = T)
library(glue, quietly = T)
library(crayon, quietly = T)
library(curl, quietly = T)
library(tmap, quietly = T)
library(sf, quietly = T)

# Who am I?
username <- "rnd-ptmpk"

# Download data before run
source(glue("/home/{username}/WRF-auto/R/gfs-forecast-2.R"))

# rWRF Directory
rWRF_root  <- glue("/home/{username}/WRF-auto")

# Load all function
source(glue("{rWRF_root}/R/namelist-wps.R"))
source(glue("{rWRF_root}/R/namelist-input.R"))

# Before running the WRF simulation, download entire GFS subset data for a specific time period.
# Check the existing data. If exist, download it, else Sleep system about 20 minutes
gfs_dir <- "/media/rnd-ptmpk/MyBook/GFS-Data"
if (!dir.exists(gfs_dir)) dir.create(gfs_dir)

# Download GFS data both forecasts and historical
frcs_days   <- 14
hist_days   <- 5
which_day   <- Sys.Date()
dday        <- 0 # For error
# For forecasts data
date_str    <- as.POSIXct(glue('{which_day - dday} 00:00:00'), tz = "UTC")
date_end    <- as.POSIXct(glue('{which_day - dday + frcs_days} 18:00:00'), tz = "UTC")
# For historical data
date_str_h  <- date_str - hist_days * 24 * 3600
date_end_h  <- date_str - 6 * 3600

date_rng    <- as.numeric(difftime(date_end, date_str, tz = "UTC", units = "hours"))
resolution  <- "1p00" #0p25, 0p50, 1p00
interv      <- 6
issued_time <- 0
iss_time_f  <- sprintf("%.2d", issued_time)
forecast    <- seq(issued_time, date_rng, interv)
forecast    <- sprintf("%.3d", forecast)

# 1. Forecast
gfs_download_aws(date_str, date_end, resolution, interv, gfs_dir, 'forecast')
# 2. Historical
gfs_download_aws(date_str_h, date_end_h, resolution, interv, gfs_dir, 'historical')

###################
# Run WRF Program #
###################
# Where is your WRF & WPS program directory?
wrf_root <- glue("/home/{username}/Documents/iWRF")
wrf_dir <- glue("{wrf_root}/WRF")
wps_dir <- glue("{wrf_root}/WPS")

# Make working directory for linking WRF and WPS program
work_dir <- glue("{rWRF_root}/WRF-sim")

if (!dir.exists(work_dir)) {
  dir.create(work_dir)
  print(glue("Your working directory for simulation at {work_dir}"))
}
setwd(work_dir)

# Run WPS Program
# 1. Create namelist.wps file. This file is saved to simulation folder
namelist.wps(work_dir, date_str_h, date_end, glue("{wrf_root}/WPS_GEOG"), -1.612010, 110.299100)

# 2. Linked all WPS Program
## 2.1. Geogrid
geogrid_exe <- glue('{wps_dir}/geogrid/geogrid.exe {work_dir}/geogrid.exe')
geogrid_pth <- glue('{wps_dir}/geogrid {work_dir}/geogrid')
if (!file.exists(glue('{work_dir}/geogrid.exe'))){
  system(glue("ln -s {geogrid_pth} && ln -s {geogrid_exe}"))
}
## 2.2. Ungrib
system(glue("ln -s {wps_dir}/ungrib/Variable_Tables/Vtable.GFS {work_dir}/Vtable &&
             ln -s {wps_dir}/link_grib.csh {work_dir}/link_grib.csh &&
             ln -s {wps_dir}/ungrib {work_dir}/ungrib &&
             ln -s {wps_dir}/ungrib/ungrib.exe {work_dir}/ungrib.exe"))
## 2.3. Metgrid
system(glue("ln -s {wps_dir}/metgrid {work_dir}/metgrid &&
             ln -s {wps_dir}/metgrid/metgrid.exe {work_dir}/metgrid.exe"))

# 3. Run WPS Program
## 3.1. geogrid.exe
system(glue("{work_dir}/geogrid.exe"))
## 3.2. ungrib.exe
### Link the data
data_dirs_f <- glue("{gfs_dir}/{format(date_str, '%Y%m%d')}_{resolution}/{iss_time_f}")
data_dirs_h <- glue("{gfs_dir}/{format(date_str_h, '%Y%m%d')}_{resolution}/f000")

system(glue('ln -sf {data_dirs_f}/* .'))
system(glue('ln -sf {data_dirs_h}/* .'))
### Run ungrib program
system(glue("{work_dir}/link_grib.csh gfs.t*"))
system(glue("{work_dir}/ungrib.exe"))
## 3.3. metgrid.exe
system(glue("{work_dir}/metgrid.exe"))
## Remove FILE*
system("rm FILE:* GRIBFILE* gfs.t*")



# 4. Run WRF Program
# Linked all WRF program
system(glue("ln -s {wrf_dir}/run/* {work_dir}"))
namelist.input(work_dir, date_str_h, date_end)

# 1. real.exe
cat("Please wait, real.exe is running !!! \n")
system(glue("{work_dir}/real.exe"))

if (!file.exists("wrfbdy_d01") | !file.exists("wrfinput_d01")) {
  stop("Please check rsl.error.000* for any errors !!!")
}

# 2. wrf.exe
t1 <- Sys.time()
cat("Please wait, wrf.exe is running !!! \n")
cat(glue("The simulation start at {t1} \n"))
cat("\n")

system(glue("LD_LIBRARY_PATH=/home/{username}/Documents/iWRF/LIBRARIES/lib:$LD_LIBRARY_PATH {work_dir}/wrf.exe"))

t2 <- Sys.time()
t2_t1 <- difftime(t2, t1, units = "secs")

if (!file.exists(list.files(pattern = "wrfout*")[1])) {
  cat(red("Please check rsl.error.000* for any errors !!!"))
} else {
  cat("\n")
  cat(glue("The simulation was finished at {t2} \n"))
  cat("\n")
  cat(glue("{t2_t1}"))
}

system(glue("echo {t2_t1 + t1} >> /home/{username}/WRF-auto/wrf-time.txt"))
