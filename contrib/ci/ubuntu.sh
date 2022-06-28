#!/bin/sh
set -e
set -x

#clone test firmware if necessary
. ./contrib/ci/get_test_firmware.sh

#check for and install missing dependencies
./contrib/ci/fwupd_setup_helpers.py install-dependencies --yes -o ubuntu

#evaluate using Ubuntu's buildflags
#evaluate using Debian/Ubuntu's buildflags
#disable link time optimization, Ubuntu currently only sets it for GCC
export DEB_BUILD_MAINT_OPTIONS="optimize=-lto"
eval "$(dpkg-buildflags --export=sh)"
#filter out -Bsymbolic-functions
LDFLAGS=$(dpkg-buildflags --get LDFLAGS | sed "s/-Wl,-Bsymbolic-functions\s//")
export LDFLAGS

root=$(pwd)
rm -rf ${root}/build
mkdir -p ${root}/build
chown nobody build ${root}/subprojects
echo "###############################"
PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
echo "pkg_config_path: " $PKG_CONFIG_PATH
echo "find:"
find . -name *tss2-esys*
sudo apt update
sudo apt install -yq autoconf autoconf-archive automake build-essential g++ gcc libc6-dev git libssl-dev libtool m4 net-tools pkg-config libjson-c-dev libcurl4-openssl-dev iproute2 uthash-dev
sudo apt install libtss2-esys0 tss2 -yq


git clone https://github.com/tpm2-software/tpm2-tss.git /tmp/tpm2-tss
LD_LIBRARY_PATH=/usr/local/lib
cd /tmp/tpm2-tss
./bootstrap
PKG_CONFIG_PATH=/usr/local/lib/pkgconfig ./configure --with-udevrulesdir=/etc/udev/rules.d --with-udevrulesprefix=70- --sysconfdir=/etc --localstatedir=/var --runstatedir=/run
make -j$(nproc)
sudo make install


echo "###############################"
sudo -u nobody meson build
#build with clang
sudo -u nobody ninja -C ${root}/build test -v

#make docs available outside of docker
ninja -C ${root}/build install -v
