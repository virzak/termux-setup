#!/data/data/com.termux/files/usr/bin/bash
# Termux runs as u0_aNNN and that can't change; make $USER and the bash prompt say USER_NAME.
# The prompt's host part is DEVICE_NAME from local.env, else the phone's model (e.g. sm-s918w).
set -e
DIR="${SETUP_DIR:-$(cd "$(dirname "$0")" && pwd)}"
[ -f "$DIR/local.env" ] && . "$DIR/local.env"
DEVICE_NAME="${DEVICE_NAME:-$(getprop ro.product.model | tr '[:upper:] ' '[:lower:]-')}"

touch ~/.bashrc
# Drop the unmarked block older versions of this script appended.
sed -i '/^# --- identity ---$/,/^PS1=/d' ~/.bashrc
sed -i '/^# >>> termux-setup identity/,/^# <<< termux-setup identity/d' ~/.bashrc
if [ -z "$USER_NAME" ]; then
  echo "USER_NAME not set in local.env; keeping Termux's default identity."
  exit 0
fi
cat >> ~/.bashrc <<EOF
# >>> termux-setup identity
export USER=$USER_NAME
export LOGNAME=$USER_NAME
PS1='$USER_NAME@$DEVICE_NAME:\w\\$ '
# <<< termux-setup identity
EOF
tail -5 ~/.bashrc
