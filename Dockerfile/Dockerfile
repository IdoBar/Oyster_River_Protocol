# syntax=docker/dockerfile:1
FROM ubuntu:22.04
LABEL authors="Matthew MacManes (Matthew.MacManes@unh.edu), Ido Bar (i.bar@griffith.edu.au)"

#########
### Working dir
#########
RUN	mkdir build
WORKDIR /build

#########
### Setup the environment
#########
ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en

#########
### Aptitude packages
#########
RUN apt update \
    && apt -y upgrade \
    && apt install -y --reinstall language-pack-en \
    && locale-gen en_US.UTF-8 \
    && apt install -y build-essential git-all cmake python3 autoconf libbz2-dev liblzma-dev libxml2-dev libz-dev curl wget sudo nano \
    && apt -y autoremove


#########
### Create user orp
#########
RUN useradd -r -s /bin/bash -U -m -d /home/orp -p '' orp

#########
### Setup the user environment
########
ENV HOME=/home/orp
RUN usermod -aG sudo orp \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

#########
### Oyster River Protocol (ORP)
#########
WORKDIR /home/orp
USER orp
RUN git config --global core.compression 0 \
    && git clone --depth=1 http://github.com/idobar/Oyster_River_Protocol.git \
    && cd /home/orp/Oyster_River_Protocol \
    && git fetch --depth=10 && git fetch --depth=50 && git fetch --depth=100 \
    && git fetch --depth=500 && git fetch --unshallow \
    && sudo make 


#########
### Path
#########
RUN echo 'PATH=$PATH:/home/orp/Oyster_River_Protocol/software/anaconda/install/bin' >> /home/orp/.profile \
    && echo 'PATH=$PATH:/home/orp/Oyster_River_Protocol/software/OrthoFinder/orthofinder' >> /home/orp/.profile \
    && echo 'PATH=$PATH:/home/orp/Oyster_River_Protocol/software/orp-transrate' >> /home/orp/.profile \
    && echo "unset -f which" >> /home/orp/.profile \
    && /bin/bash -c "source /home/orp/.profile"
ENV PATH="/home/orp/Oyster_River_Protocol/software/transabyss:/home/orp/Oyster_River_Protocol/software/anaconda/install/bin:/home/orp/Oyster_River_Protocol/software/orp-transrate:/home/orp/Oyster_River_Protocol/software/OrthoFinder/orthofinder:/home/orp/Oyster_River_Protocol/software/anaconda/install/bin:${PATH}"

#########
### Clean up
#########
USER root
WORKDIR /
RUN rm -rf /build

#########
### Setup init workspace
#########
WORKDIR $HOME
USER root
RUN chown -R orp:orp  /home/orp/Oyster_River_Protocol/busco_dbs/
USER orp
RUN /bin/bash -c "source /home/orp/.profile" \
    && /bin/bash -c "source /home/orp/Oyster_River_Protocol/software/anaconda/install/etc/profile.d/conda.sh"
