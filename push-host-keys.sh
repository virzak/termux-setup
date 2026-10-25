#!/usr/bin/env bash
# Run on the PC (Git Bash) after 03-ssh.sh has started sshd on the phone.
# Copies the PC's ssh key to Termux so the phone logs in everywhere the PC does.
# Termux ignores the login name, so none is given.
# Usage: bash push-host-keys.sh <phone-ip>
set -e
PHONE=${1:?usage: push-host-keys.sh <phone-ip>}
scp -P 8022 ~/.ssh/id_rsa ~/.ssh/id_rsa.pub "$PHONE:.ssh/"
ssh -p 8022 "$PHONE" 'chmod 600 ~/.ssh/id_rsa*; ssh-keygen -lf ~/.ssh/id_rsa'
