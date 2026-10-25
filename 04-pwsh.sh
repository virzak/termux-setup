#!/data/data/com.termux/files/usr/bin/bash
# PowerShell has no Android build: install linux-arm64 pwsh inside proot-distro Debian
# and put a `pwsh` wrapper in Termux. Re-run to update PowerShell to the latest release.
set -e
[ -d "$PREFIX/var/lib/proot-distro/installed-rootfs/debian" ] || proot-distro install debian
proot-distro login debian -- bash -euo pipefail -c '
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y curl ca-certificates less locales tzdata git unzip
ICU=$(apt-cache search --names-only "^libicu[0-9]+$" | cut -d" " -f1 | head -1)
apt-get install -y "$ICU"
# Latest version from the releases/latest redirect (no API rate limit).
URL=$(curl -fsSLI -o /dev/null -w "%{url_effective}" https://github.com/PowerShell/PowerShell/releases/latest)
VER=${URL##*/v}
CUR=$(/opt/microsoft/powershell/7/pwsh -NoProfile -c "\$PSVersionTable.PSVersion.ToString()" 2>/dev/null || true)
if [ "$CUR" = "$VER" ]; then
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
cat > "$PREFIX/bin/pwsh" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
case "$PWD" in "$HOME"*) wd="/root${PWD#$HOME}" ;; *) wd=/root ;; esac
exec proot-distro login debian --shared-tmp --termux-home \
  --bind "$PREFIX/etc/proot-resolv.conf:/etc/resolv.conf" \
  --env TERM="${TERM:-xterm-256color}" --env COLORTERM=truecolor \
  --work-dir "$wd" -- /usr/bin/pwsh "$@"
EOF
chmod +x "$PREFIX/bin/pwsh"
pwsh -NoProfile -c '"pwsh $($PSVersionTable.PSVersion) OK"; "github.com -> $([Net.Dns]::GetHostAddresses("github.com"))"' || true
echo PWSH_DONE
