# Function to extract WRF output into raster dataset

# Require Library
if (!requireNamespace('ncdf4', quietly = T) &
    !requireNamespace('raster', quietly = T)) {
  stop("Please install ncdf4 and raster!")
} else {
  library(ncdf4)
  library(raster)
}

wrfout_raster <- function(wrfout.file, var.name, timezone = "UTC", nlev = 1) {

  # Open data
  wrf.file <- nc_open(wrfout.file)

  #Location
  XLAT  <- ncvar_get(wrf.file, "XLAT")
  XLONG <- ncvar_get(wrf.file, "XLONG")

  #Check dimension of geographic location
  if (length(dim(XLAT)) == 2){
    XLAT <- XLAT[1,]
    XLONG <- XLONG[,1]
  } else {
    XLAT <- XLAT[1,,1]
    XLONG <- XLONG[,1,1]
  }

  #Time
  XTIME <- ncvar_get(wrf.file, "XTIME")
  if (nlev == 1){

    if (var.name == "rain"){
      #Variable for estimated surface rainfall
      nc.var <- ncvar_get(wrf.file, "RAINC") + ncvar_get(wrf.file, "RAINNC")
      rain <- array(dim = c(length(XLONG), length(XLAT), length(XTIME)))
      rain[,,1] <- nc.var[,,1]

      counter = 1
      for (waktu in seq_along(XTIME)+1){
        rain[,,waktu] <- nc.var[,,waktu] - nc.var[,,counter]

        if (waktu == length(XTIME)){
          break
        } else {
          counter <- counter + 1
        }
      }
      nc.var <- rain

    } else if (var.name == "ws"){ # Wind speed at 10 m
      u10 <- ncvar_get(wrf.file, "U10")^2
      v10 <- ncvar_get(wrf.file, "V10")^2

      nc.var <- sqrt(u10 + v10)
      nc.var <- nc.var*3.6

    } else if (var.name == "wdir") {
      u10 <- ncvar_get(wrf.file, "U10")
      v10 <- ncvar_get(wrf.file, "V10")

      nc.var <- atan2(v10, -u10) * 180 / pi + 90
      nc.var[nc.var < 0] <- nc.var[nc.var < 0] + 360

    } else if (var.name == "wdir_met") {
      u10 <- ncvar_get(wrf.file, "U10")
      v10 <- ncvar_get(wrf.file, "V10")

      nc.var <- (180 / pi * atan2(-u10, -v10)) + 180

    } else if (var.name == "rh"){ # Relative humidity at 2 m
      psfc <- ncvar_get(wrf.file, "PSFC")
      t2   <- ncvar_get(wrf.file, "T2")
      qv2  <- ncvar_get(wrf.file, "Q2")

      #Calculate saturated water vapor pressure
      es <- 6.1094 * exp(17.625 * (t2 - 273)/(t2 - 273 + 243.04))
      #Calculate saturated mixing ratio
      ws <- 0.622*es/((psfc/100) - es)
      #Calculate relative humidity
      rh <- qv2/ws*100

      nc.var <- rh

    } else if (var.name == "tc"){ # Near-surface air temperature
      nc.var <- ncvar_get(wrf.file, "T2") - 273.15

    } else if (var.name == "tskc"){# Land surface temperature
      nc.var <- ncvar_get(wrf.file, "TSK") - 273.15

    } else if (var.name == "sh"){# Specific humidity
      nc.var <- ncvar_get(wrf.file, "Q2")
      nc.var <- nc.var/(1+nc.var)

    } else {
      #Other Variable
      nc.var <- ncvar_get(wrf.file, var.name)
    }

    # Make a raster for 3D
    ## Check if XTIME == 1
    if (length(XTIME) == 1) {
      w.r   <- raster(nrows = length(XLAT), ncols = length(XLONG),
                     xmn = min(XLONG), xmx = max(XLONG), ymn = min(XLAT), ymx = max(XLAT))
      w.r[] <- as.vector(nc.var)
      w.r   <- flip(w.r, "y")
    } else {
      w.r   <- brick(nrows = length(XLAT), ncols = length(XLONG), nl = length(XTIME),
                     xmn = min(XLONG), xmx = max(XLONG), ymn = min(XLAT), ymx = max(XLAT))
      w.r[] <- nc.var
      w.r   <- flip(w.r, "y")
    }

  } else {
    #Make a raster for 4D
    nc.var <- ncvar_get(wrf.file, var.name)[,,nlev,]
    w.r    <- brick(nrows = length(XLAT), ncols = length(XLONG), nl = length(XTIME),
                    xmn = min(XLONG), xmx = max(XLONG), ymn = min(XLAT), ymx = max(XLAT))
    w.r[] <- nc.var
    w.r   <- flip(w.r, "y")
  }

  #Get Global Attribute
  glo <- ncatt_get(wrf.file, 0)

  #Simulation Start Date
  xt <- glo$SIMULATION_START_DATE
  xt <- as.POSIXct(xt, format = "%Y-%m-%d_%H:%M:%S", tz = timezone)

  #Assign time format
  xtt <- as.POSIXct(XTIME * 60, format = "%Y-%m-%d %H:%M:%S", origin = xt, tz = timezone)
  w.r <- setZ(w.r, xtt)

  #Return the raster
  return(w.r)
}
