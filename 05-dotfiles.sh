#!/data/data/com.termux/files/usr/bin/bash
# Run virzak/dotfiles' own setup.sh inside proot Debian, where pwsh lives, then make pwsh the
# default shell. setup.sh handles Termux itself (relative links, ~/.termux/font.ttf, no ~/.bashrc edits).
set -e
cd ~
if [ -d dotfiles/.git ]; then git -C dotfiles pull --ff-only; else git clone https://github.com/virzak/dotfiles.git; fi

# Inside the distro Termux's home is /root.
proot-distro login debian --termux-home -- bash /root/dotfiles/setup.sh
termux-reload-settings || true
pwsh -NoLogo -c '"profile: $PROFILE"; Get-Command oh-my-posh | % Source; Get-Module -ListAvailable Terminal-Icons | % Version'
echo DOTFILES_DONE
