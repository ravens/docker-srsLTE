FROM ubuntu:16.04
MAINTAINER Yan Grunenberger <yan@grunenberger.net>
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update
RUN apt-get -yq dist-upgrade 
RUN apt-get -yq install autoconf build-essential libusb-1.0-0-dev cmake wget pkg-config libboost-all-dev python-dev python-cheetah git subversion python-software-properties

# Dependencies for UHD image downloader script
RUN apt-get -yq install python-mako python-requests 

# Fetching the uhd 3.010.001 driver for our USRP SDR card 
RUN wget http://files.ettus.com/binaries/uhd/uhd_003.010.001.001-release/uhd-3.10.1.1.tar.gz && tar xvzf uhd-3.10.1.1.tar.gz && cd UHD_3.10.1.1_release && mkdir build && cd build && cmake ../ && make && make install && ldconfig && python /usr/local/lib/uhd/utils/uhd_images_downloader.py

# dependencies
RUN apt-get -qy install libfftw3-dev libmbedtls-dev libboost-all-dev libconfig++-dev libsctp-dev

# volk
WORKDIR /root
RUN wget http://libvolk.org/releases/volk-1.3.tar.gz
RUN tar xvzf volk-1.3.tar.gz && cd /root/volk-1.3 && mkdir build && cd build && cmake ../ && make install 
RUN ldconfig && volk_profile

# Fetch package
WORKDIR /root
RUN git clone https://github.com/srsLTE/srsLTE.git
WORKDIR /root/srsLTE
RUN mkdir build &&cd build && cmake ../ && make srsenb

# config
WORKDIR /root/srsLTE/build/srsenb/src 
RUN cp ../../../srsenb/*.example .  
RUN mv sib.conf.example sib.conf  
RUN mv rr.conf.example rr.conf  
RUN mv enb.conf.example enb.conf  
RUN mv drb.conf.example drb.conf 
RUN sed -i "s/0x19B/0xe00/g" enb.conf
RUN sed -i "s/phy_cell_id = 1/phy_cell_id = 2/g" enb.conf
RUN sed -i "s/mcc = 001/mcc = 901/g" enb.conf
RUN sed -i "s/mnc = 01/mnc = 55/g" enb.conf
RUN sed -i "s/mme_addr = 127.0.1.100/mme_addr = 192.168.42.108/g" enb.conf
RUN sed -i "s/gtp_bind_addr = 127.0.1.1/gtp_bind_addr = 192.168.42.10/g" enb.conf
RUN sed -i "s/dl_earfcn = 3400/dl_earfcn = 2525/g" enb.conf
RUN sed -i "s/tx_gain = 70/tx_gain = 90/g" enb.conf
RUN sed -i "s/rx_gain = 50/rx_gain = 120/g" enb.conf
RUN sed -i "s/n_prb = 25/n_prb = 25/g" enb.conf
RUN sed -i "s/tac = 0x0007/tac = 0x0008/g" enb.conf

ENTRYPOINT /root/srsLTE/build/srsenb/src/srsenb --enb.name=srstid01 enb.conf

