# Function for installing WRF Model

install_wrf <- function() {
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

  # Download WRF Model from github
  if (!dir.exists(paste0(Sys.getenv('ODIR'), '/WRF'))) {
    system(paste0('git clone https://github.com/wrf-model/WRF ', Sys.getenv('ODIR'), '/WRF'))
  }

  # Open WRF directory
  setwd(paste0(Sys.getenv('ODIR'), '/WRF'))

  # Deep clean for recompiling
  system('./clean -a')

  # Option for specific OS
  # ---- #

  # Installing WRF
  system(paste0("/bin/bash -c ./configure <<< $'35\r1\r'"))
  system("./compile em_real -j 4")

  # Checking programs
  if (file.exists('main/wrf.exe')) {
    message('
    ------------------------------------------------
    !!!!     WRF was installed successfully     !!!!
    ------------------------------------------------
    ')
  }

  # Back to Current Directory
  setwd(cur_dir)
}
