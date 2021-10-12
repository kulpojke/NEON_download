FROM rocker/r-base:4.1.0

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
RUN R -e   "install.packages('BiocManager'); \
    install.packages('devtools'); \
    devtools::install_version('neonUtilities', '2.1.2'); \
    install.packages('raster'); \
    install.packages('rgdal'); \
    install.packages('parallel')"

# make working directory 
WORKDIR /work

# copy files
COPY file.sh /
COPY file.R /

# change permisions 
WORKDIR /
RUN  chmod -R 777 /

ENTRYPOINT ["/file.sh"]






