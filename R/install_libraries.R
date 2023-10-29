# Function to install libraries that required for WRF simulation

install_libraries <- function(install_dir = NULL) {
  # Get architecture and os
  arch <- version$arch
  os   <- version$os

  # Get Operating System version
  os_ver <- tolower(osVersion)

  # Check Operating System
  if (!grepl('darwin|linux', os)) {
    stop("You can't install WRF model in Windows OS, except You have installed Windows Subsystem Linux (WSL)")
  }

  # Check the compiler
  cmp <- system('which gcc g++ gfortran make csh m4', intern = T)
  rmp <- c('gcc', '[g++]', 'gfortran', 'make', 'csh', 'm4', 'git')
  if (grepl('ubuntu', os_ver)) {
    for (nc in seq_along(cmp)) {
      if (!grepl(rmp[nc], cmp[nc])) {
        stop(paste0("Please install ", rmp[nc], "with this command: sudo apt install ", rmp[nc], "!!!"))
      } else {next}
    }
  } else if (grepl('macos', os_ver)) {
    # Check homebrew
    brew_path <- system('which brew', T)
    if (!file.exists(brew_path)) {
      stop('Please install Homebrew first!
       You can copy-paste this command to your terminal:
       /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"')
    } else {
      for (nc in seq_along(cmp)) {
        if (!grepl(rmp[nc], cmp[nc])) {
          stop(paste0("Please install ", rmp[nc], "with this command: brew install ", rmp[nc], "!!!"))
        } else {next}
      }
    }
  } else if (grepl('almalinux', os_ver)) {
    for (nc in seq_along(cmp)) {
      if (!grepl(rmp[nc], cmp[nc])) {
        stop(paste0("Please install ", rmp[nc], "with this command: sudo dnf install ", rmp[nc], "!!!"))
      } else {next}
    }
  }

  # Project directory
  proj_dir <- getwd()

  # Select directory You want to install WRF model
  if (is.null(wrf_root)) {
    wrf_root <- Sys.getenv('HOME')
  } else {
    wrf_root <- install_dir
  }
  # if only '~' instead of $HOME, extracting will get error
  if (wrf_root == "~") wrf_root <- Sys.getenv('HOME')

  # Environment Variables
  Sys.setenv(ODIR=paste0(wrf_root, "/WRF-Model"))
  Sys.setenv(PATH=paste0(Sys.getenv('PATH'), ":", Sys.getenv('ODIR'), "/bin"))
  Sys.setenv(LD_LIBRARY_PATH=paste0(Sys.getenv('ODIR'), "/lib:$LD_LIBRARY_PATH"))
  Sys.setenv(LDFLAGS=paste0('-L', Sys.getenv('ODIR'), '/lib'))
  Sys.setenv(CPPFLAGS=paste0('-I', Sys.getenv('ODIR'), '/include'))

  # Print message
  message('
  |----------------------------------------------------------------------|
  | Before running the WRF model, You should install these libraries:    |
  | jasper, libpng, hdf5, pnetcdf, and netcdf.                           |
  | These libraries are HIGHLY RECOMMENDED installed inside your machine |
  |----------------------------------------------------------------------|
  ')

  # Output directory
  outlib_dir <- paste0(wrf_root, "/", "WRF-Model/LIBRARIES")
  if (!dir.exists(outlib_dir)) dir.create(outlib_dir, recursive = TRUE)

  # Downloading the libraries from author Google Drive
  ## Read libraries file from R data sets
  libs <- readRDS('data/requirements.rds')
  for (lib in 1:nrow(libs)){
    # GDrive ID
    id <- paste0('https://drive.google.com/uc?id=', libs[lib, 3])
    # Output filename
    lf <- paste0(outlib_dir, '/', libs[lib, 1])

    # Download file
    if (!file.exists(lf)){
      message(paste0("Downloading ", libs[lib, 1], "file ....\n"))
      download.file(id, lf) # Filename library
    }

    # Extracting file
    if (!dir.exists(paste0(outlib_dir, "/", libs[lib, 2]))) {
      message(paste0("Extracting ", libs[lib, 1], "file .... \n"))
      untar(lf, exdir = outlib_dir, extras = '-z')
    }
  }


  # Steps for installing the libraries
  ## 1. zlib
  setwd(paste0(outlib_dir, "/", libs[8, 2]))
  system(paste0('./configure --prefix=', Sys.getenv('ODIR')))
  system('make check install')
  setwd(proj_dir) # Back to project directory
  if (!file.exists(paste0(Sys.getenv('ODIR'), '/lib/libz.a'))) stop("ERROR. Please check compiler and reinstall zlib!")

  ## 2. openMPI
  setwd(paste0(outlib_dir, "/", libs[6, 2]))
  system(paste0('./configure --prefix=', Sys.getenv('ODIR')))
  system('make && make install')
  setwd(proj_dir) # Back to project directory
  if (!file.exists(paste0(Sys.getenv('ODIR'), '/bin/mpicc'))) stop("ERROR. Please check compiler and reinstall openMPI!")

  ## 3. libpng
  setwd(paste0(outlib_dir, "/", libs[3, 2]))
  system(paste0('CC=', Sys.getenv('ODIR'), '/bin/mpicc ./configure --prefix=', Sys.getenv('ODIR')))
  system('make check install')
  setwd(proj_dir) # Back to project directory
  if (!file.exists(paste0(Sys.getenv('ODIR'), '/lib/libpng.a'))) stop("ERROR. Please check compiler and reinstall libpng!")

  ## 4. jasper
  setwd(paste0(outlib_dir, "/", libs[2, 2]))
  if (grepl('aarch64', arch)) {
    system('wget -N -O acaux/config.guess "http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD"')
    system('wget -N -O acaux/config.sub "http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD"')
  }
  system(paste0('CC=', Sys.getenv('ODIR'), '/bin/mpicc ./configure --prefix=', Sys.getenv('ODIR')))
  system('make check install')
  setwd(proj_dir) # Back to project directory
  if (!file.exists(paste0(Sys.getenv('ODIR'), '/lib/libjasper.a'))) stop("ERROR. Please check compiler and reinstall jasper!")

  ## 5. hdf5
  setwd(paste0(outlib_dir, "/", libs[1, 2]))
  system(paste0('CC=', Sys.getenv('ODIR'), '/bin/mpicc', ' FC=', Sys.getenv('ODIR'), '/bin/mpifort ./configure --prefix=', Sys.getenv('ODIR'), ' --enable-fortran --enable-parallel'))
  system('make && make install')
  setwd(proj_dir) # Back to project directory
  if (!file.exists(paste0(Sys.getenv('ODIR'), '/lib/libhdf5_hl.a'))) stop("ERROR. Please check compiler and reinstall hdf5!")

  ## 6. pnetcdf
  setwd(paste0(outlib_dir, "/", libs[7, 2]))
  system(paste0('CC=', Sys.getenv('ODIR'), '/bin/mpicc', ' FC=', Sys.getenv('ODIR'), '/bin/mpifort ./configure --prefix=', Sys.getenv('ODIR'), ' --enable-shared'))
  system('make && make install')
  setwd(proj_dir) # Back to project directory
  if (!file.exists(paste0(Sys.getenv('ODIR'), '/lib/libpnetcdf.a'))) stop("ERROR. Please check compiler and reinstall pnetcdf!")

  ## 7. netcdf-c
  setwd(paste0(outlib_dir, "/", libs[5, 2]))
  system(paste0('CC=', Sys.getenv('ODIR'), '/bin/mpicc ./configure --prefix=', Sys.getenv('ODIR'), ' --enable-pnetcdf --disable-dap --enable-parallel-tests'))
  system('make && make install')
  setwd(proj_dir) # Back to project directory
  if (!file.exists(paste0(Sys.getenv('ODIR'), '/lib/libnetcdf.a'))) stop("ERROR. Please check compiler and reinstall netcdf-c!")

  ## 8. netcdf-fortran
  setwd(paste0(outlib_dir, "/", libs[4, 2]))
  system(paste0('CC=', Sys.getenv('ODIR'), '/bin/mpicc', ' FC=', Sys.getenv('ODIR'), '/bin/mpifort ./configure --prefix=', Sys.getenv('ODIR')))
  system('make && make install')
  setwd(proj_dir) # Back to project directory
  if (!file.exists(paste0(Sys.getenv('ODIR'), '/lib/libnetcdff.a'))) stop("ERROR. Please check compiler and reinstall netcdf-fortran!")

  # Finish
  message('
    ------------------------------------------------
    !!!!  Packages were installed successfully  !!!
    ------------------------------------------------

    You can install WRF and WPS programs with this R function:
    WRF => install_wrf()
    WPS => install_wps()
  ')
}
