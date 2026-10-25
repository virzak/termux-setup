#!/data/data/com.termux/files/usr/bin/bash
# Packages everything else needs. Upgrade first: installing onto a stale base pulls a new
# libcurl against an old openssl and git's https helper fails to link.
set -e
# apt-get, not pkg: pkg shells out to curl, which is exactly what breaks.
apt-get update
yes | apt-get -y -o Dpkg::Options::=--force-confold full-upgrade
pkg install -y openssh git curl unzip proot-distro
