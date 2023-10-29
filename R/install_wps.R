# Function for installing WRF Pre-Processing tools (WPS)

install_wps <- function(install_dir = NULL) {
  # Current directory
  cur_dir <- getwd()

  # Select directory You want to install WRF model. Default: $HOME
  if (is.null(install_dir)) {
    wrf_root <- Sys.getenv("HOME")
  }

  # Environment Variables
  Sys.setenv(ODIR=paste0(wrf_root, "/WRF-Model"))
  Sys.setenv(PATH=paste0(Sys.getenv('ODIR'), "/bin:", Sys.getenv('PATH')))
  Sys.setenv(LD_LIBRARY_PATH=paste0(Sys.getenv('ODIR'), "/lib:$LD_LIBRARY_PATH"))
  Sys.setenv(LDFLAGS=paste0('-L', Sys.getenv('ODIR'), '/lib'))
  Sys.setenv(CPPFLAGS=paste0('-I', Sys.getenv('ODIR'), '/include'))
  Sys.setenv(NETCDF=Sys.getenv('ODIR'))
  Sys.setenv(PNETCDF=Sys.getenv('ODIR'))
  Sys.setenv(HDF5=Sys.getenv('ODIR'))
  Sys.setenv(PHDF5=Sys.getenv('ODIR'))
  Sys.setenv(JASPERLIB=paste0(Sys.getenv('ODIR'), "/lib"))
  Sys.setenv(JASPERINC=paste0(Sys.getenv('ODIR'), "/include"))

  # Download WRF Model from github
  if (!dir.exists(paste0(Sys.getenv('ODIR'), '/WPS'))) {
    system(paste0('git clone https://github.com/wrf-model/WPS ', Sys.getenv('ODIR'), '/WPS'))
  }

  # Open WRF directory
  setwd(paste0(Sys.getenv('ODIR'), '/WPS'))

  # Deep clean for recompiling
  system('./clean -a')

  # Option for specific OS. Automatically chose dmpar
  # Get Operating System version
  os_ver <- tolower(osVersion)
  if (grepl('mac', os_ver)) {
    conf_opt <- 19
  } else if (grepl('ubuntu|almalinux', os_ver)) {
    conf_opt <- 3
  }

  # Installing WPS
  system(paste0("/bin/bash -c ./configure <<< ", "$'", conf_opt, "\r'"))
  # Add -lgomp lib to configure.wps
  system("sed -i.change -r 's/-lnetcdff -lnetcdf/-lnetcdf -lnetcdff -lgomp/g' configure.wps && ./compile")

  # Checking programs
  if (file.exists('geogrid.exe')) {
    message('
    ------------------------------------------------
    !!!!     WPS was installed successfully     !!!!
    ------------------------------------------------
    ')
  } else {
    stop('
    ------------------------------------------------
    !!!!  Error. Please check log in terminal   !!!!
    ------------------------------------------------
    ')
  }

  # Back to Current Directory
  setwd(cur_dir)
}
