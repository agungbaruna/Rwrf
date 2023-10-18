#' This script is used for generate namelist.input for each parameters
#'
#'
#'
# Require Library
if (!requireNamespace('glue', quietly = T)) {
  stop("Please install glue!")
} else {
  library(glue)
}

gen_namelist_input <- function(work_dir, date_str, date_end, hist_int = 60) {
  if (!file.exists(glue("{work_dir}/namelist.input"))) {
    outfile <- file(glue("{work_dir}/namelist.input"))
  } else {
    system(glue("mv {work_dir}/namelist.input {work_dir}/namelist.input.old"))
    outfile <- file(glue("{work_dir}/namelist.input"))
  }

  # change date_str and date_end format
  date_str <- as.POSIXct(date_str, tz = "UTC")
  date_end <- as.POSIXct(date_end, tz = "UTC")

  yy1 <- format(date_str, "%Y"); yy2 <- format(date_end, "%Y")
  mm1 <- format(date_str, "%m"); mm2 <- format(date_end, "%m")
  dd1 <- format(date_str, "%d"); dd2 <- format(date_end, "%d")
  HH1 <- format(date_str, "%H"); HH2 <- format(date_end, "%H")

  # parameter run_days & run_hours
  run_days  <- difftime(as.Date(date_end), as.Date(date_str), units = "days")
  run_hours <- as.numeric(HH2) - as.numeric(HH1)

  writeLines(c(
    "&time_control",
    glue("run_days           = {run_days},"),
    glue("run_hours          = {run_hours},"),
    glue("start_year         = {yy1}, {yy1},"),
    glue("start_month        = {mm1}, {mm1},"),
    glue("start_day          = {dd1}, {dd1},"),
    glue("start_hour         = {HH1}, {HH1},"),
    glue("end_year           = {yy2}, {yy2},"),
    glue("end_month          = {mm2}, {mm2},"),
    glue("end_day            = {dd2}, {dd2},"),
    glue("end_hour           = {HH2}, {HH2},"),
    glue("interval_seconds   = 21600,"),
    glue("input_from_file    = .true., .true.,"),
    glue("history_interval   = {hist_int}, {hist_int},"),
    glue("frames_per_outfile = 1000, 1000,"),
    glue("restart            = .false.,"),
    glue("restart_interval   = 7200,"),
    glue("io_form_history    = 2,"),
    glue("io_form_input      = 2,"),
    glue("io_form_boundary   = 2,"),
    glue("io_form_restart    = 2,"),
    "/",

    "&domains",
    glue("time_step              =   60,"),
    glue("num_metgrid_levels     =  34,"),
    glue("num_metgrid_soil_levels=   4,"),
    glue("max_dom                =   2,"),
    glue("e_we                   =   50,  86,"),
    glue("e_sn                   =   50,  86,"),
    glue("e_vert                 =  33,  33,"),
    glue("p_top_requested        =  5000,"),
    glue("dx                     = 10000,"),
    glue("dy                     = 10000,"),
    glue("grid_id                =   1,  2,"),
    glue("parent_id              =   0,  1,"),
    glue("i_parent_start         =   1,  17,"),
    glue("j_parent_start         =   1,  18,"),
    glue("parent_grid_ratio      =   1,  5,"),
    glue("parent_time_step_ratio =   1,  5,"),
    glue("feedback               =   0,"),
    glue("smooth_option          =   0,"),
    "/",

    "&physics",
    glue("physics_suite                  = 'TROPICAL',"),
    glue("mp_physics                     = -1,    -1,"),
    glue("cu_physics                     = -1,     0,"),
    glue("ra_lw_physics                  = -1,    -1,"),
    glue("ra_sw_physics                  = -1,    -1,"),
    glue("bl_pbl_physics                 = -1,    -1,"),
    glue("sf_sfclay_physics              = -1,    -1,"),
    glue("sf_surface_physics             = -1,    -1,"),
    glue("radt                           = 10,    10,"),
    glue("bldt                           =  0,     0,"),
    glue("cudt                           =  0,     0,"),
    glue("icloud                         =  1,"       ),
    glue("num_land_cat                   = 18,"       ),
    glue("sf_urban_physics               =  0,     0,"),
    "/",

    "&fdda",
    "/",

    "&dynamics",
    glue("hybrid_opt                          = 2,"),
    glue("w_damping                           = 0,"),
    glue("diff_opt                            = 2,      2,"),
    glue("km_opt                              = 4,      4,"),
    glue("diff_6th_opt                        = 0,      0,"),
    glue("diff_6th_factor                     = 0.12,   0.12,"),
    glue("base_temp                           = 290."),
    glue("damp_opt                            = 3,"),
    glue("zdamp                               = 5000.,  5000.,"),
    glue("dampcoef                            = 0.2,    0.2,"),
    glue("khdif                               = 0,      0,"),
    glue("kvdif                               = 0,      0,"),
    glue("non_hydrostatic                     = .true., .true.,"),
    glue("moist_adv_opt                       = 1,      1,"),
    glue("scalar_adv_opt                      = 1,      1,"),
    glue("gwd_opt                             = 1,      0,"),
    "/",

    "&bdy_control",
    glue("spec_bdy_width                 = 5,"),
    glue("specified                      = .true."),
    "/",

    "&grib2",
    "/",

    "&namelist_quilt",
    glue("nio_tasks_per_group = 0,"),
    glue("nio_groups          = 1,"),
    "/"
  ),
  outfile)

  close(outfile)
}
