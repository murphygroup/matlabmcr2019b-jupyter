FROM ubuntu:18.04 as intermediate

###############################################################################################
MAINTAINER Ivan E. Cao-Berg <icaoberg@andrew.cmu.edu>
LABEL Description="Ubuntu 18.04 + MATLAB MCR 2019b + Jupyter NoteBook"
LABEL Vendor="Murphy Lab in the Computational Biology Department at Carnegie Mellon University"
LABEL Web="http://murphylab.cbd.cmu.edu"
LABEL Version="2019b"
###############################################################################################

###############################################################################################
# UPDATE OS AND INSTALL TOOLS
USER root
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends apt-utils
RUN apt-get install -y build-essential git \
    unzip \
    xorg \
    wget \
    tree \
    pandoc \
    curl \
    vim
RUN apt-get upgrade -y
###############################################################################################

###############################################################################################
# INSTALL MATLAB MCR 2019b
USER root
RUN mkdir /mcr-install && \
    mkdir /opt/mcr
RUN cd /mcr-install && \
    wget -nc https://ssd.mathworks.com/supportfiles/downloads/R2019b/Release/5/deployment_files/installer/complete/glnxa64/MATLAB_Runtime_R2019b_Update_5_glnxa64.zip && \
    echo "Unzipping container" && \
    unzip -q MATLAB_Runtime_R2019b_Update_5_glnxa64.zip && \
    ./install -destinationFolder /opt/mcr -agreeToLicense yes -mode silent && \
    cd / && \
    echo "Removing temporary files" && \
    rm -rvf mcr-install
###############################################################################################

###############################################################################################
FROM jupyter/scipy-notebook
COPY --from=intermediate /opt/mcr /opt/mcr
###############################################################################################

###############################################################################################
USER root
RUN conda install --quiet --yes \
  git \
  pip \
  Shapely && \
  conda clean --all -f -y && \
  pip install aicsimageio
###############################################################################################

###############################################################################################
# CONFIGURE ENVIRONMENT VARIABLES FOR MCR
USER root
RUN mv -v /opt/mcr/v97/sys/os/glnxa64/libstdc++.so.6 /opt/mcr/v97/sys/os/glnxa64/libstdc++.so.6.old
ENV LD_LIBRARY_PATH /opt/mcr/v97/runtime/glnxa64:/opt/mcr/v97/bin/glnxa64:/opt/mcr/v97/sys/os/glnxa64
ENV XAPPLRESDIR /opt/mcr/v97/X11/app-defaults
###############################################################################################

###############################################################################################
# CONFIGURE ENVIRONMENT
ENV DEBIAN_FRONTEND noninteractive
ENV SHELL /bin/bash
ENV USERNAME murphylab
ENV UID 1001
RUN useradd -m -s /bin/bash -N -u $UID $USERNAME
RUN if [ ! -d /home/$USERNAME/ ]; then mkdir /home/$USERNAME/; fi
###############################################################################################
