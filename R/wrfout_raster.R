# Function to extract WRF output into raster dataset

# Require Library
if (!requireNamespace('ncdf4', quietly = T) &
    !requireNamespace('terra', quietly = T)) {
  stop("Please install ncdf4 and terra!")
} else {
  library(ncdf4)
  library(terra)
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

    if (var.name == "rain" & length(XTIME) > 1){
      #Variable for estimated surface rainfall
      nc.var <- ncvar_get(wrf.file, "RAINC") + ncvar_get(wrf.file, "RAINNC")
      rain <- array(dim = c(length(XLONG), length(XLAT), length(XTIME)))
      rain[, , 1] <- nc.var[, , 1]

      counter = 1
      for (nt in seq_along(XTIME) + 1){
        rain[ , , nt] <- nc.var[ , , nt] - nc.var[ , , counter]

        if (nt == length(XTIME)){
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
      nc.var <- nc.var * 3.6

    } else if (var.name == "wdir") {
      u10 <- ncvar_get(wrf.file, "U10")
      v10 <- ncvar_get(wrf.file, "V10")

      nc.var <- atan2(v10, -u10) * 180 / pi + 90
      nc.var[nc.var < 0] <- nc.var[nc.var < 0] + 360

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
      nc.var <- nc.var / (1 + nc.var)

    } else {
      #Other Variable
      nc.var <- ncvar_get(wrf.file, var.name)
    }

    # Make a raster for 3D
    ## Check if XTIME == 1
    if (length(XTIME) == 1) {
      w.r   <- rast(nrows = length(XLAT), ncols = length(XLONG),
                    xmin = min(XLONG), xmax = max(XLONG), ymin = min(XLAT), ymax = max(XLAT))
      w.r[] <- as.vector(nc.var)
      w.r   <- flip(w.r, "vertical")
    } else {
      w.r   <- rast(nrows = length(XLAT), ncols = length(XLONG), nlyrs = length(XTIME),
                    xmin = min(XLONG), xmax = max(XLONG), ymin = min(XLAT), ymax = max(XLAT))
      w.r[] <- nc.var
      w.r   <- flip(w.r, "vertical")
    }

  } else {
    #Make a raster for 4D
    nc.var <- ncvar_get(wrf.file, var.name)[,,nlev,]
    w.r    <- rast(nrows = length(XLAT), ncols = length(XLONG), nlyrs = length(XTIME),
                    xmin = min(XLONG), xmax = max(XLONG), ymin = min(XLAT), ymax = max(XLAT))
    w.r[] <- nc.var
    w.r   <- flip(w.r, "vertical")
  }

  #Get Global Attribute
  glo <- ncatt_get(wrf.file, 0)

  #Simulation Start Date
  xt <- glo$SIMULATION_START_DATE
  xt <- as.POSIXct(xt, format = "%Y-%m-%d_%H:%M:%S", tz = timezone)

  #Assign time format
  xtt <- as.POSIXct(XTIME * 60, format = "%Y-%m-%d %H:%M:%S", origin = xt, tz = timezone)
  time(w.r) <- xtt

  #Return the raster
  return(w.r)
}
wrfout_raster('inst/extdata/wrfout_d02_2022-01-02_02:00:00', 'ws') |> plot()
