#!/data/data/com.termux/files/usr/bin/bash
# Home-screen shortcuts for Termux:Widget (install it from F-Droid, same source as Termux).
# Plain files in shortcuts/ are copied as-is; *.template files are filled in per host from local.env.
set -e
DIR="${SETUP_DIR:-$(cd "$(dirname "$0")" && pwd)}"
[ -f "$DIR/local.env" ] && . "$DIR/local.env"
# Termux:Widget refuses shortcut folders other apps could write to.
mkdir -p ~/.shortcuts && chmod 700 ~/.shortcuts
for f in "$DIR"/shortcuts/*; do
  case "$f" in *.template) continue ;; esac
  install -m 700 "$f" ~/.shortcuts/
done
for host in $HIBERNATE_HOSTS; do
  sed "s/@HOST@/$host/g" "$DIR/shortcuts/hibernate.template" > ~/.shortcuts/"hibernate-$host"
  chmod 700 ~/.shortcuts/"hibernate-$host"
done
ls -l ~/.shortcuts
