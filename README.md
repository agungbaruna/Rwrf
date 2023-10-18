# Rwrf: Installing, Simulating, and Visualizing WRF with R

This package is use for installing, running, and visualizing WRF with R Programming Language. You can install [WRF](https://github.com/wrf-model/WRF) and [WPS](https://github.com/wrf-model/WPS) with `install_wrf()` and `install_wps()` in your R terminal, respectively. Before installing WRF, you should install dependencies package to run it, like NetCDF, mpich/openMPI, HDF5, zlib, libpng, and jasper. Luckily, You can install all of them with `install_libraries()` function in this package.

This script was tested on Ubuntu 22.04, Mac M1, and Windows Subsystem Linux with Ubuntu Distro 22.04

> THIS SCRIPT CAN'T RUN ON WINDOWS MACHINE, EXCEPT ON WINDOWS SUBSYSTEM LINUX (WSL)

## How to Use?

### Installing the libraries

### Installing WRF and WPS

### Downloading the mandatory data

This package provide the function that used for downloading the meteorological forcing data, e.g. GFS and ERA5. GFS data can be downloaded from [NOAA server](https://nomads.ncep.noaa.gov) or [AWS Open Data](https://registry.opendata.aws/noaa-gfs-bdp-pds/). You can download the data with `download_gfs()` function. For ERA5, You can download the data with `download_era5()` function.

Additionally, You should download the geographic data like landuse, soil type, and elevation. You can download the data from WRF website [here](https://www2.mmm.ucar.edu/wrf/src/wps_files/geog_high_res_mandatory.tar.gz) manually or with `download_geog()` function.

### Running WRF

### Visualizing WRF
