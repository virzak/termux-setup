#!/data/data/com.termux/files/usr/bin/bash
# sshd on 8022 for the PC, ssh client config, and a key for outgoing logins.
# Personal values come from local.env and ssh_config.local (gitignored, see *.example).
set -e
DIR="${SETUP_DIR:-$(cd "$(dirname "$0")" && pwd)}"
[ -f "$DIR/local.env" ] && . "$DIR/local.env"
mkdir -p ~/.ssh && chmod 700 ~/.ssh

# Let the PC log in to the phone: ssh -p 8022 <phone-ip> (Termux ignores the login name)
touch ~/.ssh/authorized_keys
if [ -n "$PC_KEY" ]; then
  grep -qF "$PC_KEY" ~/.ssh/authorized_keys || echo "$PC_KEY" >> ~/.ssh/authorized_keys
else
  echo "PC_KEY not set in local.env; add the PC's public key to ~/.ssh/authorized_keys yourself."
fi
chmod 600 ~/.ssh/authorized_keys

# Client config: rewrite the managed block each run. Host * comes last so per-host User lines win.
touch ~/.ssh/config
sed -i '/^# >>> termux-setup/,/^# <<< termux-setup/d' ~/.ssh/config
{
  echo '# >>> termux-setup (managed by 03-ssh.sh; edits inside this block are overwritten)'
  [ -f "$DIR/ssh_config.local" ] && cat "$DIR/ssh_config.local" && echo
  if [ -n "$USER_NAME" ]; then
    echo '# default login name for every host (ssh ignores $USER and would send u0_aNNN)'
    echo 'Host *'
    echo "    User $USER_NAME"
  fi
  echo '# <<< termux-setup'
} >> ~/.ssh/config
chmod 600 ~/.ssh/config

pgrep -x sshd >/dev/null || sshd
echo "sshd on port 8022. Phone IP(s):"
ip -4 addr 2>/dev/null | grep -o 'inet [0-9.]*' | grep -v 127.0.0.1 || true

# The phone uses the PC's own id_rsa for outgoing logins. Copy it over ssh, never via /sdcard:
[ -f ~/.ssh/id_rsa ] || echo "No ~/.ssh/id_rsa yet. From the PC run: bash push-host-keys.sh <phone-ip>"
