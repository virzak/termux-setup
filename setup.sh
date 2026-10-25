#!/data/data/com.termux/files/usr/bin/bash
# Fresh-Termux setup for an Android phone: identity, ssh, PowerShell in proot Debian, virzak/dotfiles.
# Run from Termux (after termux-setup-storage):  bash ~/storage/downloads/termux-setup/setup.sh
# Every step is safe to re-run. Run a single step with:  bash setup.sh 04-pwsh.sh
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
export SETUP_DIR="$DIR"
exec > >(tee "$DIR/setup.log") 2>&1

steps=("$@")
[ ${#steps[@]} -eq 0 ] && steps=(01-base.sh 02-identity.sh 03-ssh.sh 04-pwsh.sh 05-dotfiles.sh 06-shortcuts.sh)
for s in "${steps[@]}"; do
  echo; echo "===== $s"
  bash "$DIR/$s"
done
echo; echo SETUP_DONE
echo "Open a new Termux session to get pwsh with your oh-my-posh prompt."
