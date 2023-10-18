#' This script is used for generate namelist.wps for each parameters
#'
#'
#'
#'
# Require Library
if (!requireNamespace('glue', quietly = T)) {
  stop("Please install glue!")
} else {
  library(glue)
}

gen_namelist_wps <- function(work_dir, date_str, date_end, geog_data_path, ref_lat, ref_lon) {
  if (!file.exists(glue("{work_dir}/namelist.wps"))){
    outfile <- file(glue("{work_dir}/namelist.wps"))
  } else {
    system(glue("mv {work_dir}/namelist.wps {work_dir}/namelist.wps.old"))
    outfile <- file(glue("{work_dir}/namelist.wps"))
  }

  # change date_str and date_end format
  date_str <- as.POSIXct(date_str, tz = "UTC")
  date_end <- as.POSIXct(date_end, tz = "UTC")

  yy1 <- format(date_str, "%Y"); yy2 <- format(date_end, "%Y")
  mm1 <- format(date_str, "%m"); mm2 <- format(date_end, "%m")
  dd1 <- format(date_str, "%d"); dd2 <- format(date_end, "%d")
  HH1 <- format(date_str, "%H"); HH2 <- format(date_end, "%H")

  writeLines(c(
    "&share",
    "wrf_core    = 'ARW',",
    glue("max_dom     = 2,"),
    glue("start_year  = {yy1}, {yy1},"),
    glue("start_month = {mm1}, {mm1},"),
    glue("start_day   = {dd1}, {dd1},"),
    glue("start_hour  = {HH1}, {HH1},"),
    glue("end_year    = {yy2}, {yy2},"),
    glue("end_month   = {mm2}, {mm2},"),
    glue("end_day     = {dd2}, {dd2},"),
    glue("end_hour    = {HH2}, {HH2},"),
    glue("interval_seconds = 21600,"),    # Perlu ditentukan lagi
    "io_form_geogrid = 2",
    "/",

    "&geogrid",
    "parent_id         =   1,   1,",
    glue("parent_grid_ratio =   1,   5,"),
    glue("i_parent_start    =   1,  17,"),
    glue("j_parent_start    =   1,  18,"),
    glue("e_we              =  50,  86,"),
    glue("e_sn              =  50,  86,"),
    "geog_data_res     = 'modis2021','modis2021',",
    glue("dx                = 10000,"),
    glue("dy                = 10000,"),
    "map_proj          = 'mercator',",
    glue("ref_lat           = {ref_lat},"),
    glue("ref_lon           = {ref_lon},"),
    glue("truelat1          = {ref_lat},"),
    glue("geog_data_path    = '{geog_data_path}'"),
    "/",

    "&ungrib",
    "out_format = 'WPS',",
    "prefix     = 'FILE',",
    "/",

    "&metgrid",
    "fg_name        = 'FILE'",
    "io_form_metgrid = 2,",
    "/"),
    outfile)

  close(outfile)
}
