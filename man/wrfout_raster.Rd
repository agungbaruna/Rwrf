\name{wrfout_raster}
\alias{wrfout_raster}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
Read WRF output into raster
}
\description{
This function is used for extracting the WRF output which has netcdf format file into raster data.
This function uses raster (Hijmans et al. 2022) and ncdf4 packages (Pierce 20xx).
}
\usage{
wrfout_raster(wrfout.file, var.name, timezone = "UTC", nlev = 1)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{wrfout.file}{
    string. WRF output file
  }
  \item{var.name}{
    string. WRF variables
  }
  \item{timezone}{
    string. timezone, default UTC.
  }
  \item{nlev}{
    integer. default to 1 if the variable has vertical variation,
    e.g. `T` (air temperature) or `SOILTEMP` (soil temperature)
  }
}
\details{
The explanation of diagnostic and original variables (e.g. rainfall, relative humidity, etc)
}
\value{
Describe the value returned
If it is a LIST, use
\item{comp1 }{Description of 'comp1'}
\item{comp2 }{Description of 'comp2'}
...
}
\references{
%% ~put references to the literature/web site here ~
}
\author{
Agung Baruna Setiawan Noor <nooragung97@gmail.com>
}
\note{
%%  ~~further notes~~
}

%% ~Make other sections like Warning with \section{Warning }{....} ~

\seealso{
%% ~~objects to See Also as \code{\link{help}}, ~~~
}
\examples{
##---- Should be DIRECTLY executable !! ----
##-- ==>  Define data, use random,
##--	or do  help(data=index)  for the standard data sets.

## The function is currently defined as
function (x)
{
  }
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory (show via RShowDoc("KEYWORDS")):
% \keyword{ ~kwd1 }
% \keyword{ ~kwd2 }
% Use only one keyword per line.
% For non-standard keywords, use \concept instead of \keyword:
% \concept{ ~cpt1 }
% \concept{ ~cpt2 }
% Use only one concept per line.
