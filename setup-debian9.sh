#!/bin/bash

if [ ! -e /etc/apt/sources.list.orig ]; then
  mv /etc/apt/sources.list /etc/apt/sources.list.orig
  cat >/etc/apt/sources.list <<EOF
###### Debian Main Repos
deb http://ftp.uk.debian.org/debian/ stretch main non-free

###### Debian Update Repos
#deb http://ftp.uk.debian.org/debian/ stretch-proposed-updates main non-free
deb http://security.debian.org/ stretch/updates main non-free
EOF
fi

apt-get update
apt-get install openssh-server vim git rsync

if [ ! -e ~/scripts ]; then
  cd ~
  git clone https://github.com/Anthchirp/scripts.git
else
  cd ~/scripts
  git pull
fi

cd ~/scripts
./update-ssh-keys.sh
