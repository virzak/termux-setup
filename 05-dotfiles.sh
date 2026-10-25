#!/data/data/com.termux/files/usr/bin/bash
# Termux flavour of virzak/dotfiles setup.sh, with pwsh as the default shell.
set -e
cd ~
if [ -d dotfiles/.git ]; then git -C dotfiles pull --ff-only; else git clone https://github.com/virzak/dotfiles.git; fi

# Relative links so they resolve both in Termux and inside proot (where ~ is /root).
mkdir -p .config/git .config/powershell
ln -sfv dotfiles/.gitconfig .gitconfig
ln -sfv dotfiles/.inputrc .inputrc
ln -sfv dotfiles/.actrc .actrc
ln -sfv dotfiles/.vityusha-ohmyposhv3-v2.json .vityusha-ohmyposhv3-v2.json
ln -sfv dotfiles/difftool.sh difftool.sh
ln -sfv dotfiles/gitconflict.sh gitconflict.sh
ln -sfv ../../dotfiles/.config/git/ignore .config/git/ignore
ln -sfv ../../dotfiles/Microsoft.PowerShell_profile.ps1 .config/powershell/Microsoft.PowerShell_profile.ps1

# Tools the pwsh profile looks for, installed inside Debian where pwsh runs.
proot-distro login debian --termux-home -- bash -euc '
curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d /usr/local/bin
pwsh -NoProfile -c "Set-PSRepository PSGallery -InstallationPolicy Trusted; if (-not (Get-Module -ListAvailable Terminal-Icons)) { Install-Module Terminal-Icons -Scope CurrentUser }"
'

# Nerd font for the oh-my-posh glyphs, only if Termux has no custom font yet.
if [ ! -f ~/.termux/font.ttf ]; then
  mkdir -p ~/.termux
  curl -fLo "$TMPDIR/Meslo.zip" https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/Meslo.zip
  unzip -o -j "$TMPDIR/Meslo.zip" MesloLGMNerdFont-Regular.ttf -d "$TMPDIR"
  mv "$TMPDIR/MesloLGMNerdFont-Regular.ttf" ~/.termux/font.ttf
  rm "$TMPDIR/Meslo.zip"
fi

# Termux runs ~/.termux/shell for every new session. If pwsh ever breaks, long-press the
# Termux icon -> Failsafe for plain bash, then: rm ~/.termux/shell
mkdir -p ~/.termux
ln -sfv "$PREFIX/bin/pwsh" ~/.termux/shell
termux-reload-settings || true
pwsh -NoLogo -c '"profile: $PROFILE"; Get-Command oh-my-posh | % Source; Get-Module -ListAvailable Terminal-Icons | % Version'
echo DOTFILES_DONE
