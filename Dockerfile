FROM ubuntu:22.04

RUN mkdir -p /openwrt

WORKDIR /openwrt

RUN apt update

RUN apt install -y build-essential clang flex bison g++ gawk \
    # gcc-multilib g++-multilib gettext git libncurses5-dev libssl-dev \
    gettext git libncurses5-dev libssl-dev \
    python3-setuptools rsync swig unzip zlib1g-dev file wget

RUN useradd -m openwrt

RUN echo "root:123321" | chpasswd

WORKDIR /home/openwrt/

COPY . /home/openwrt/

RUN chown -R openwrt:openwrt /home/openwrt/

USER openwrt

ENTRYPOINT [ "bash" ]