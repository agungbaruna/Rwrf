# This script for getting the location parameters to determine
# domain for namelist.wps
# Just for ONE request

src_data <- Sys.getenv("DATA")

library(jsonlite, quietly = TRUE)
library(glue, quietly = TRUE)
library(googledrive, quietly = TRUE)
library(raster, quietly = TRUE, warn.conflicts = FALSE)

# Download data

# Read JSON DATA
dats <- fromJSON(src_data)

# -------------------------------------------------------------
# ------------------ GET LOCATION PARAMETERS ------------------
# -------------------------------------------------------------

# domain parameters
dom <- dats$domain
res <- as.integer(dats$resolution[1]) # in km
# grid edge
xmn <- as.double(dom$minLon)[1]
xmx <- as.double(dom$maxLon)[1]
ymn <- as.double(dom$minLat)[1]
ymx <- as.double(dom$maxLat)[1]
# Calculate the center of coarse/parent domain
ref_lon <- (xmx + xmn) / 2
ref_lat <- (ymx + ymn) / 2
# Menentukan batas daerah dengan Menggambar polygon dari domain ke-n sampai domain ke-1
old_poly <- Polygon(cbind(c(xmn, xmx, xmx, xmn, xmn),
                          c(ymn, ymn, ymx, ymx, ymn)))
buff <- 0.5 # dalam derajat. untuk domain ke-2 = 0.5 derajat dan domain ke-1 = 2 * buff(domain ke-1)
if (res < 10) {
  old_poly <- Polygons(list(old_poly), "D02")
  old_poly <- SpatialPolygons(list(old_poly))
  # Make coarse domain
  new_poly <- Polygon(cbind(c(xmn - buff, xmx + buff, xmx + buff, xmn - buff, xmn - buff),
                            c(ymn - buff, ymn - buff, ymx + buff, ymx + buff, ymn - buff)))
  new_poly <- Polygons(list(new_poly), "D01")
  new_poly <- SpatialPolygons(list(new_poly), proj4string = crs(raster()))
  # Determine grid edge for coarse domain
  xmn_c <- xmin(new_poly)
  xmx_c <- xmax(new_poly)
  ymn_c <- ymin(new_poly)
  ymx_c <- ymax(new_poly)
} else {
  xmn_c <- xmn
  xmx_c <- xmx
  ymn_c <- ymn
  ymx_c <- ymx
}

# Menentukan jumlah grid pada domain ke-X (contoh domain ke-3)
## Variabel resolusi per grid untuk domain ke-X
if (res == 2) {
  dx_dy <- c(10000, 2000)
  ## i_parent_start dan j_parent_start
  i_parent_start <- c(1, 18)
  j_parent_start <- c(1, 18)
  ## Mengambil niilai e_we dan e_sn
  e_we <- floor(c(xmx_c - xmn_c + 2, xmx - xmn) * 111000 / dx_dy)
  e_sn <- floor(c(ymx_c - ymn_c + 2, ymx - ymn) * 111000 / dx_dy)
  ## parent_grid_ratio
  parent_grid_ratio <- dx_dy[1] / dx_dy
} else if (res == 5) {
  dx_dy <- c(15000, 5000)
  ## i_parent_start dan j_parent_start
  i_parent_start <- c(1, 18)
  j_parent_start <- c(1, 18)
  ## Mengambil niilai e_we dan e_sn
  e_we <- floor(c(xmx_c - xmn_c + 2, xmx - xmn) * 111000 / dx_dy)
  e_sn <- floor(c(ymx_c - ymn_c + 2, ymx - ymn) * 111000 / dx_dy)
  ## parent_grid_ratio
  parent_grid_ratio <- dx_dy[1] / dx_dy
} else {
  dx_dy <- res * 1000
  ## i_parent_start dan j_parent_start
  i_parent_start <- c(1)
  j_parent_start <- c(1)
  ## Mengambil niilai e_we dan e_sn
  e_we <- floor(c(xmx_c - xmn_c) * 111000 / dx_dy)
  e_sn <- floor(c(ymx_c - ymn_c) * 111000 / dx_dy)
  ## parent_grid_ratio
  parent_grid_ratio <- dx_dy / dx_dy
}


## Modifikasi e_we dan e_sn untuk disesuaikan dengan parent_grid_ratio.
## Rumus: e_we or e_sn = (parent_grid_ratio * N + 1)
if (length(parent_grid_ratio) > 1) {
  for (ndom in 2:length(e_we)) {
    while ((e_we[ndom] - 1) %% parent_grid_ratio[ndom] != 0) {
      e_we[ndom] <- e_we[ndom] - 1
    }
    while ((e_sn[ndom] - 1) %% parent_grid_ratio[ndom] != 0) {
      e_sn[ndom] <- e_sn[ndom] - 1
    }
  }
}

# ---------------------------------------------------------
# ------------------ GET TIME PARAMETERS ------------------
# ---------------------------------------------------------

# time parameters
stim <- dats$simulationDate
start_date <- paste0(stim$startDate, " ", stim$startHours, ":00:00")
start_date <- as.POSIXct(start_date, tz = "UTC", format = "%Y-%m-%d %H:%M:%S")

end_date <- paste0(stim$endDate, " ", stim$endHours, ":00:00")
end_date <- as.POSIXct(end_date, tz = "UTC", format = "%Y-%m-%d %H:%M:%S")

# Condition if time range <= 6 hour,
# the simulation start time need to be substract 24 hour before start time
time_range <- end_date - start_date
if (as.integer(time_range) <= 6) {
  start_date <- start_date - 24 * 60 * 60
}

# convert start_date and end_date to character
start_date <- format(start_date, format = "%Y-%m-%d_%H:%M:%S")
end_date <- format(end_date, format = "%Y-%m-%d_%H:%M:%S")

# Summary to generate namelist.wps
summ_namelist_wps <- list(max_dom = length(dx_dy),
                          start_date = start_date,
                          end_date = end_date,
                          ref_lat = ref_lat,
                          ref_lon = ref_lon,
                          e_we = e_we,
                          e_sn = e_sn,
                          dx = dx_dy[1],
                          dy = dx_dy[1],
                          parent_grid_ratio = parent_grid_ratio,
                          i_parent_start = i_parent_start,
                          j_parent_start = j_parent_start)

# ---------------------------------------------------------
# ----------------- GENERATE NAMELIST.WPS -----------------
# ---------------------------------------------------------

out_txt    <- file("namelist.wps")

## Write to file
if (summ_namelist_wps$max_dom == 2) {
  writeLines(c(
    "&share",
    "wrf_core = 'ARW',",
    glue("max_dom = 2,"),
    glue("start_date = '{start_date}', '{start_date}',"),
    glue("end_date = '{end_date}', '{end_date}',"),
    glue("interval_seconds = 21600,"),    # Perlu ditentukan lagi
    "io_form_geogrid = 2",
    "/",
    "\n",

    "&geogrid",
    "parent_id         =   1,   1,",
    glue("parent_grid_ratio =   1, {summ_namelist_wps$parent_grid_ratio[2]},"),
    glue("i_parent_start    =   1, {summ_namelist_wps$i_parent_start[2]},"),
    glue("j_parent_start    =   1, {summ_namelist_wps$j_parent_start[2]},"),
    glue("e_we              =  {summ_namelist_wps$e_we[1]},  {summ_namelist_wps$e_we[2]},"),
    glue("e_sn              =  {summ_namelist_wps$e_sn[1]},  {summ_namelist_wps$e_sn[2]},"),
    "geog_data_res = 'default','default',",
    glue("dx = {summ_namelist_wps$dx},"),
    glue("dy = {summ_namelist_wps$dy},"),
    "map_proj = 'mercator',",
    glue("ref_lat   = {summ_namelist_wps$ref_lat},"),
    glue("ref_lon   = {summ_namelist_wps$ref_lon},"),
    glue("truelat1  = {summ_namelist_wps$ref_lat},"),
    "geog_data_path = '/media/absen/hdd/WRF/WPS_GEOG/'",
    "/",
    "\n",

    "&ungrib",
    "out_format = 'WPS',",
    "prefix = 'FILE',",
    "/",
    "\n",

    "&metgrid",
    "fg_name = 'FILE'",
    "io_form_metgrid = 2,",
    "/"), out_txt)
} else {
  writeLines(c(
    "&share",
    "wrf_core = 'ARW',",
    glue("max_dom = 1,"),
    glue("start_date = '{start_date}',"),
    glue("end_date = '{end_date}',"),
    glue("interval_seconds = 21600,"),    # Perlu ditentukan lagi
    "io_form_geogrid = 2",
    "/",
    "\n",

    "&geogrid",
    "parent_id         =   1,   ",
    glue("parent_grid_ratio =   1,"),
    glue("i_parent_start    =   1,"),
    glue("j_parent_start    =   1,"),
    glue("e_we              =  {summ_namelist_wps$e_we[1]},"),
    glue("e_sn              =  {summ_namelist_wps$e_sn[1]},"),
    "geog_data_res = 'default',",
    glue("dx = {summ_namelist_wps$dx},"),
    glue("dy = {summ_namelist_wps$dy},"),
    "map_proj = 'mercator',",
    glue("ref_lat   = {summ_namelist_wps$ref_lat},"),
    glue("ref_lon   = {summ_namelist_wps$ref_lon},"),
    glue("truelat1  = {summ_namelist_wps$ref_lat},"),
    "geog_data_path = '/media/absen/hdd/WRF/WPS_GEOG/'",
    "/",
    "\n",

    "&ungrib",
    "out_format = 'WPS',",
    "prefix = 'FILE',",
    "/",
    "\n",

    "&metgrid",
    "fg_name = 'FILE'",
    "io_form_metgrid = 2,",
    "/"), out_txt)
}

close(out_txt)
