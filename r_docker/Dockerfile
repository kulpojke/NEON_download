FROM rocker/r-base:4.1.2

# install apt packages
RUN apt-get update \
    && apt install -y \
    parallel \
    software-properties-common \
    apt-utils \
    libgdal-dev \
    libgeos++-dev \
    libudunits2-dev \
    libproj-dev \
    libx11-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libfreetype6-dev \
    libnode-dev \
    libxt-dev \
    libfftw3-dev

# install R packages
RUN R -e "install.packages('BiocManager'); \
    install.packages('devtools'); \
    install.packages('neonUtilities'); \
    install.packages('raster'); \
    install.packages('rgdal'); \
    install.packages('parallel'); \
    BiocManager::install('rhdf5')"

# make working directory
WORKDIR /work








