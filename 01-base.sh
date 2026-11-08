#!/data/data/com.termux/files/usr/bin/bash
# Packages everything else needs. Upgrade first: installing onto a stale base pulls a new
# libcurl against an old openssl and git's https helper fails to link.
set -e
# Pin the official repo (packages-cf.termux.dev). Otherwise pkg picks a random community
# mirror, and nothing checks that it is current: one was 10 months stale, missing whole
# packages (dotnet10.0). Same effect as choosing "default" in termux-change-repo.
M=$PREFIX/etc/termux
rm -rf "$M/chosen_mirrors"   # may be a directory if several mirrors were chosen
ln -s "$M/mirrors/default" "$M/chosen_mirrors"
. "$M/mirrors/default"
echo "deb $MAIN stable main" > "$PREFIX/etc/apt/sources.list"
# apt-get, not pkg: pkg shells out to curl, which is exactly what breaks.
apt-get update
yes | apt-get -y -o Dpkg::Options::=--force-confold full-upgrade
pkg install -y openssh git curl unzip proot-distro
