# This script is used for downloading Global Forecast System data at AWS Open Data: https://noaa-gfs-bdp-pds.s3.amazonaws.com
# These data were available from 26 February 2021 until present
# If You want more, You can visit https://rda.ucar.edu with other data sources

# Require Library
if (!requireNamespace('glue', quietly = T) &
    !requireNamespace('curl', quietly = T) &
    !requireNamespace('httr', quietly = T)) {
  stop("Please install glue, curl, and httr packages!")
} else {
  library(glue); library(crayon)
  library(curl); library(httr)
}

gfs_download_aws <- function(date_str, date_end = NULL,
                             res = '1p00',
                             interval = NULL,
                             gfs_out_dir,
                             type,
                             use_wgrib2 = FALSE) {
  # url
  url_ <- "https://noaa-gfs-bdp-pds.s3.amazonaws.com"

  # Requirements for choosing type of download ----
  # 1. If type is empty
  if (missing(type)) stop("You should choose 'forecast' or 'historical'")
  # 2. If directory for downloaded is empty
  if (missing(gfs_out_dir)) {
    gfs_out_dir <- Sys.getenv('HOME')
    message(glue('Files will be downloaded at {green(gfs_out_dir)}'))
  }
  # 3. Check grid resolution data
  if (res != "0p25" & res != "0p50" & res != "1p00") {
    stop(cat(red("Grid data resolution must be '0p25' (0.25 deg), '0p50' (0.50 deg), or '1p00' (1.00 deg)!", "\n")))
  }
  # 4. Check start date & end date
  date_str <- as.POSIXct(date_str, tz = "UTC")
  yy1 <- format(date_str, "%Y")
  mm1 <- format(date_str, "%m")
  dd1 <- format(date_str, "%d")
  HH1 <- format(date_str, "%H")
  if (!missing(date_end)) {
    date_end <- as.POSIXct(date_end, tz = "UTC")
    yy2 <- format(date_end, "%Y")
    mm2 <- format(date_end, "%m")
    dd2 <- format(date_end, "%d")
    HH2 <- format(date_end, "%H")
    # Check date
    if (date_end < date_str) stop("END_DATE should larger than START_DATE !!!")
  }

  # 5. Make sure date_end and interval not empty
  if (missing(date_end)) stop('date_end cannot empty !!!!')
  if (!missing(interval)) {
    interval <- as.integer(interval)
  } else {stop('interval cannot empty !!!!')}

  # 6. Output folder for saving the downloaded files
  ofold <- glue("{gfs_out_dir}/{yy1}{mm1}{dd1}_{res}")

  # 7. Issued hour same as hour of date_str
  issued_hour <- sprintf('%.2d', as.numeric(HH1))

  # 8. If using wgrib2 for subsetting
  wgrib2_path <- glue('{gfs_out_dir}/wgrib2')

  # Downloading process
  # 1. type == 'forecast'
  if (type == 'forecast'){

    # difference time between start date and end date for downloading forecast data
    diff_time <- difftime(date_end, date_str, units = "hours")
    if (diff_time > 384) {stop(cat(red("Maximum forecast up to 384 hours!","\n")))}

    # check if forecast time > 0
    forecast <- as.integer(diff_time)

    if (forecast == 0 & interval != 0) {
      cat(red(glue("You just download 1 data at {date_str}"), "\n"))
      frc_range <- sprintf("%.3d", forecast)
    } else if (interval == 0) {
      stop(cat(red("interval must be 1, 3, 6, or 12!", "\n")))
    } else {
      if ((res == "0p50" | res == "1p00") & interval == 1){
        stop(cat(red("interval must be 3, 6, or 12!", "\n")))
      } else {
        frc_range <- seq(0, forecast, interval)
        frc_range <- sprintf("%.3d", frc_range)
      }
    }

    # Check folder output
    if (!dir.exists(ofold)) {
      dir.create(ofold)
      dir.create(glue("{ofold}/{HH1}"))
    } else if (dir.exists(ofold) & !dir.exists(glue("{ofold}/{HH1}"))) {
      dir.create(glue("{ofold}/{HH1}"))
    }

    # there are some changing of the destination folder before 23 March 2021
    if (as.Date(date_str) <= as.Date("2021-03-22")){
      # print information
      print(glue("You will download GFS data with {res} deg from {date_str} {HH1}:00 to
             {date_end} {HH2}:00 UTC with {forecast} hours forecast time
             with issued time {issued_hour}.

             Your data directory: {ofold}/{HH1}"))
      # without atmos folder
      for (frc in frc_range) {
        durl1 <- glue("{url_}/gfs.{yy1}{mm1}{dd1}/{issued_hour}/gfs.t{issued_hour}z.pgrb2.{res}.f{frc}")
        outf  <- glue("{ofold}/{HH1}/gfs.t{issued_hour}z.{yy1}{mm1}{dd1}.pgrb2.{res}.f{frc}")
        head1 <- HEAD(durl1)
        # check the data. If exists, download it, else sleep the system about 3600 s / 1 hour
        repeat {
          if (head1$status_code != 200) {
            print(glue("File gfs.t{issued_hour}z.pgrb2.{res}.f{frc} is not exist. Try 1 hour later !"))
            Sys.sleep(3600)
          } else {
            if (!file.exists(outf)){
              print(glue(green('Downloading ... gfs.t{issued_hour}z.{yy1}{mm1}{dd1}.pgrb2.{res}.f{frc}')))
              curl_download(durl1, outf, quiet = FALSE)
              if (file.exists(wgrib2_path) & use_wgrib2){
                system(glue("{wgrib2_path} {outf} -small_grib 90:150 -12:12 {ofold}/{HH1}/gfs.t{issued_hour}z.{yy1}{mm1}{dd1}.pgrb2.subset.{res}.f{frc}"))
              }
            } else {
              print(glue(green('Files have been downloaded at {ofold}/{HH1}/gfs.t{issued_hour}z.{yy1}{mm1}{dd1}.pgrb2.{res}.f{frc}')))
              break
            }
          }
        }
      }
    } else {
      # with atmos folder
      for (frc in frc_range) {
        durl2 <- glue("{url_}/gfs.{yy1}{mm1}{dd1}/{issued_hour}/atmos/gfs.t{issued_hour}z.pgrb2.{res}.f{frc}")
        outf  <- glue("{ofold}/{HH1}/gfs.t{issued_hour}z.{yy1}{mm1}{dd1}.pgrb2.{res}.f{frc}")
        head2 <- HEAD(durl2)
        # check the data. If exists, download it, else sleep the system about 3600 s / 1 hour
        repeat {
          if (head2$status_code != 200) {
            print(glue("File gfs.t{issued_hour}z.pgrb2.{res}.f{frc} is not exist. Try 1 hour later !"))
            Sys.sleep(3600)
          } else {
            if (!file.exists(outf)) {
              print(glue(green('Downloading ... gfs.t{issued_hour}z.{yy1}{mm1}{dd1}.pgrb2.{res}.f{frc}')))
              curl_download(durl2, outf, quiet = FALSE)
              if (file.exists(wgrib2_path) & use_wgrib2){
                system(glue("{wgrib2_path} {outf} -small_grib 90:150 -12:12 {ofold}/{HH1}/gfs.t{issued_hour}z.{yy1}{mm1}{dd1}.pgrb2.subset.{res}.f{frc}"))
              }
            } else {
              print(glue(green('Files have been downloaded at {ofold}/{HH1}/gfs.t{issued_hour}z.{yy1}{mm1}{dd1}.pgrb2.{res}.f{frc}')))
              break
            }
          }
        }
      }
    }
  }

  # 2. type == 'historical'
  if (type == 'historical') {
    # Difference time between start date and end date for downloading historical data using *f000
    # diff_time <- difftime(date_end, date_str, units = "hours")

    # Make new seq date-time
    sequ_time <- seq(as.POSIXct(date_str, tz = 'UTC'),
                     as.POSIXct(date_end, tz = 'UTC'),
                     by = glue('{interval} hours'))

    yy3 <- format(sequ_time, "%Y")
    mm3 <- format(sequ_time, "%m")
    dd3 <- format(sequ_time, "%d")
    HH3 <- format(sequ_time, "%H")

    # Check folder output
    if (!dir.exists(ofold)) {
      dir.create(ofold)
      dir.create(glue('{ofold}/f000'))
    } else if (dir.exists(ofold) & !dir.exists(glue("{ofold}/f000"))) {
      dir.create(glue("{ofold}/f000"))
    }

    # print information
    print(glue("You will download GFS data with {res} deg from {date_str} {HH3[1]}:00 to
             {date_end} {HH3[length(HH3)]}:00 UTC with {interval} hours interval
             with issued time {unique(HH3)}.

             Your data directory: {ofold}/f000"))

    # there are some changing of the destination folder before 23 March 2021
    if (as.Date(date_str[1]) <= as.Date("2021-03-22")){
      # without atmos folder
      for (hst in seq_along(sequ_time)) {
        # https://noaa-gfs-bdp-pds.s3.amazonaws.com/gfs.20230101/00/atmos/gfs.t00z.pgrb2.1p00.f000
        durl1 <- glue("{url_}/gfs.{yy3[hst]}{mm3[hst]}{dd3[hst]}/{HH3[hst]}/gfs.t{HH3[hst]}z.pgrb2.{res}.f000")
        outf  <- glue("{ofold}/f000/gfs.t{HH3[hst]}z.{yy3[hst]}{mm3[hst]}{dd3[hst]}.pgrb2.{res}.f000")
        head1 <- HEAD(durl1, timeout(60))
        # check the data. If exists, download it, else sleep the system about 3600 s / 1 hour
        repeat {
          if (head1$status_code != 200) {
            glue("File gfs.t{HH3[hst]}z.pgrb2.{res}.f000 is not exist. Try 1 hour later !")
            Sys.sleep(3600)
          } else {
            if (!file.exists(outf)){
              print(glue(green('Downloading ... gfs.t{HH3[hst]}z.{yy3[hst]}{mm3[hst]}{dd3[hst]}.pgrb2.{res}.f000')))
              curl_download(durl1, outf, quiet = FALSE)
              if (file.exists(wgrib2_path) & use_wgrib2){
                system(glue("{wgrib2_path} {outf} -small_grib 90:150 -12:12 {ofold}/f000/gfs.t{HH3[hst]}z.{yy3[hst]}{mm3[hst]}{dd3[hst]}.pgrb2.subset.{res}.f000"))
              } else {
                print(glue(green('Files have been downloaded at {ofold}/f000/gfs.t{HH3[hst]}z.{yy3[hst]}{mm3[hst]}{dd3[hst]}.pgrb2.{res}.f000')))
                break
              }
            }
          }
        }
      }
    } else {
      # with atmos folder
      for (hst in seq_along(sequ_time)) {
        durl2 <- glue("{url_}/gfs.{yy3[hst]}{mm3[hst]}{dd3[hst]}/{HH3[hst]}/atmos/gfs.t{HH3[hst]}z.pgrb2.{res}.f000")
        outf  <- glue("{ofold}/f000/gfs.t{HH3[hst]}z.{yy3[hst]}{mm3[hst]}{dd3[hst]}.pgrb2.{res}.f000")
        head2 <- HEAD(durl2, timeout(60))
        # check the data. If exists, download it, else sleep the system about 3600 s / 1 hour
        repeat {
          if (head2$status_code != 200) {
            glue("File gfs.t{HH3[hst]}z.pgrb2.{res}.f000 is not exist. Try 1 hour later !")
            Sys.sleep(3600)
          } else {
            if (!file.exists(outf)) {
              print(glue(green('Downloading ... gfs.t{HH3[hst]}z.{yy3[hst]}{mm3[hst]}{dd3[hst]}.pgrb2.{res}.f000')))
              curl_download(durl2, outf, quiet = FALSE)
              if (file.exists(wgrib2_path) & use_wgrib2) {
                system(glue("{wgrib2_path} {outf} -small_grib 90:150 -12:12 {ofold}/f000/gfs.t{HH3[hst]}z.{yy3[hst]}{mm3[hst]}{dd3[hst]}.pgrb2.subset.{res}.f000"))
              }
            } else {
              print(glue(green('Files have been downloaded at {ofold}/f000/gfs.t{HH3[hst]}z.{yy3[hst]}{mm3[hst]}{dd3[hst]}.pgrb2.{res}.f000')))
              break
            }
          }
        }
      }
    }
  }
}
