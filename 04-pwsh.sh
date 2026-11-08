#!/data/data/com.termux/files/usr/bin/bash
# PowerShell has no Android build: install linux-arm64 pwsh inside proot-distro Debian
# and put a `pwsh` wrapper in Termux. Re-run to update PowerShell to the latest release.
set -e
# Ask proot-distro rather than test a path: v5 moved installs from installed-rootfs/ to containers/.
proot-distro login debian -- true >/dev/null 2>&1 || proot-distro install debian
proot-distro login debian -- bash -euo pipefail -c '
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y curl ca-certificates less locales tzdata git unzip iputils-ping
ICU=$(apt-cache search --names-only "^libicu[0-9]+$" | cut -d" " -f1 | head -1)
apt-get install -y "$ICU"
# Latest version from the releases/latest redirect (no API rate limit), else from the API.
URL=$(curl -fsSLI -o /dev/null -w "%{url_effective}" https://github.com/PowerShell/PowerShell/releases/latest || true)
case "$URL" in */tag/v*) VER=${URL##*/v} ;; *) VER= ;; esac
[ -n "$VER" ] || VER=$(curl -fsSL https://api.github.com/repos/PowerShell/PowerShell/releases/latest | sed -n "s/.*\"tag_name\": *\"v\([^\"]*\)\".*/\1/p" || true)
CUR=$(/opt/microsoft/powershell/7/pwsh -NoProfile -c "\$PSVersionTable.PSVersion.ToString()" 2>/dev/null || true)
if [ -z "$VER" ]; then
  [ -n "$CUR" ] || { echo "Cannot reach GitHub to find the PowerShell version" >&2; exit 1; }
  echo "GitHub unreachable; keeping PowerShell $CUR"
elif [ "$CUR" = "$VER" ]; then
  echo "PowerShell $VER already installed"
else
  echo "PowerShell ${CUR:-none} -> $VER"
  # Unpack next to the old install and swap, so a failed download leaves pwsh working.
  rm -rf /opt/microsoft/powershell/7.new && mkdir -p /opt/microsoft/powershell/7.new
  curl -fL "https://github.com/PowerShell/PowerShell/releases/download/v$VER/powershell-$VER-linux-arm64.tar.gz" | tar xz -C /opt/microsoft/powershell/7.new
  chmod +x /opt/microsoft/powershell/7.new/pwsh
  rm -rf /opt/microsoft/powershell/7 && mv /opt/microsoft/powershell/7.new /opt/microsoft/powershell/7
fi
ln -sf /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh
pwsh -NoProfile -c "\$PSVersionTable | Out-String"
'

# Debian can't see Android's DNS and proot-distro fills in public servers with no search
# domain, so bare LAN names fail. Use DNS_SERVER/DNS_SEARCH from local.env when set.
# Away from home the LAN server times out after ~1s and lookups fall back to 1.1.1.1.
DIR="${SETUP_DIR:-$(cd "$(dirname "$0")" && pwd)}"
[ -f "$DIR/local.env" ] && . "$DIR/local.env"
{
  [ -n "$DNS_SEARCH" ] && echo "search $DNS_SEARCH"
  [ -n "$DNS_SERVER" ] && echo "nameserver $DNS_SERVER"
  echo "nameserver 1.1.1.1"
  echo "options timeout:1 attempts:1"
} > "$PREFIX/etc/proot-resolv.conf"

# Termux home is bound to /root inside the distro; start pwsh in the matching folder.
# Absolute paths: sshd started from the Failsafe session hands its children a bare PATH.
cat > "$PREFIX/bin/pwsh" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Android has no /usr, so this exists only inside the distro: don't nest proot-distro.
[ -x /usr/bin/pwsh ] && exec /usr/bin/pwsh "$@"
P=/data/data/com.termux/files/usr
case "$PWD" in "$HOME"*) wd="/root${PWD#$HOME}" ;; *) wd=/root ;; esac
exec "$P/bin/proot-distro" login debian --shared-tmp --termux-home \
  --bind "$P/etc/proot-resolv.conf:/etc/resolv.conf" \
  --env TERM="${TERM:-xterm-256color}" --env COLORTERM=truecolor \
  --work-dir "$wd" -- /usr/bin/pwsh "$@"
EOF
chmod +x "$PREFIX/bin/pwsh"

# Termux's login runs ~/.termux/shell for app sessions and for sshd. Interactive sessions get
# pwsh; commands (ssh host cmd, scp, sftp, rsync) get bash, skipping the slow proot start and
# its pwsh-syntax quirks.
cat > "$PREFIX/bin/termux-login-shell" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
P=/data/data/com.termux/files/usr
export PATH="$P/bin:${PATH:-/system/bin}"
# Android kills Termux in the background; bring sshd back with the next session. Done here,
# before pwsh enters proot, so sshd never ends up running inside the distro.
pgrep -x sshd >/dev/null || sshd
for a in "$@"; do [ "$a" = -c ] && exec "$P/bin/bash" "$@"; done
exec "$P/bin/pwsh" "$@"
EOF
chmod +x "$PREFIX/bin/termux-login-shell"
# If pwsh ever breaks, long-press the Termux icon -> Failsafe, then: rm ~/.termux/shell
mkdir -p ~/.termux
ln -sfv "$PREFIX/bin/termux-login-shell" ~/.termux/shell
pwsh -NoProfile -c '"pwsh $($PSVersionTable.PSVersion) OK"; "github.com -> $([Net.Dns]::GetHostAddresses("github.com"))"' || true
echo PWSH_DONE
