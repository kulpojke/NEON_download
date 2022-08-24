FROM rocker/geospatial:4.2

# install apt packages
RUN apt-get update 

# install R packages
RUN R -e "install.packages('devtools'); \
          install.packages('neonUtilities')"

# make working directory
WORKDIR /work