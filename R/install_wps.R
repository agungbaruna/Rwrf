# Function for installing WRF Pre-Processing tools (WPS)

install_wps <- function() {
  # Current directory
  cur_dir <- getwd()

  # Select directory You want to install WRF model
  wrf_root <- rstudioapi::selectDirectory()

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

  # Option for specific OS
  # ---- #

  # Installing WPS
  system(paste0("/bin/bash -c ./configure <<< $'19\r'")) # 3 for Ubuntu
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
    message('
    ------------------------------------------------
    !!!!     Error. Please check the log file   !!!!
    ------------------------------------------------
    ')
  }

  # Back to Current Directory
  setwd(cur_dir)
}