# termux-setup

Rebuilds my Termux on a fresh install: `$USER`/prompt, sshd and ssh client config,
PowerShell (linux-arm64 in proot-distro Debian) as the default shell, and
[virzak/dotfiles](https://github.com/virzak/dotfiles) with oh-my-posh and a Nerd Font.
Every step is safe to re-run.

## Fresh device: manual steps

Things the scripts can't do for you, in order:

1. **Install Termux from [F-Droid](https://f-droid.org/packages/com.termux/)**, not Google Play (the
   Play build is outdated). Add-ons such as Termux:Widget must come from the same source.
2. **Turn on developer options** to copy files with adb: Settings > About > tap *Build number*
   seven times. Then either enable *USB debugging* and plug in, or use *Wireless debugging*:

   ```sh
   adb pair <ip>:<pairing-port> <code>   # "Pair device with pairing code" screen
   adb connect <ip>:<port>               # port from the main Wireless debugging screen
   ```

   The wireless port changes whenever wireless debugging is toggled or Wi-Fi drops.
3. **Let Termux run in the background**: Settings > Apps > Termux > Battery > *Unrestricted*.
   Otherwise Android kills Termux and sshd within minutes of the screen going off.
4. **Grant storage access** once, in Termux: `termux-setup-storage`, then tap *Allow*. This
   creates `~/storage/downloads`, which the steps below read from.

Optional, to reach the device over SSH before running the full setup (for example to drive it
from the PC): push your public key with `adb push ~/.ssh/id_rsa.pub /sdcard/Download/pc.pub`, then
in Termux:

```sh
ln -sf $PREFIX/etc/termux/mirrors/default $PREFIX/etc/termux/chosen_mirrors
pkg install -y openssh && mkdir -p ~/.ssh && cat ~/storage/downloads/pc.pub >> ~/.ssh/authorized_keys && sshd
```

The first line pins the official package server; Termux otherwise picks a random mirror, which
can be months out of date. sshd listens on port 8022 and ignores the login name.

## Use

1. Optional: copy `local.env.example` to `local.env` and `ssh_config.local.example` to
   `ssh_config.local`, and fill them in. Both are gitignored.
2. Copy this folder to the device's Download folder, e.g. `adb push . /sdcard/Download/termux-setup/`.
3. In Termux's bash, locally or over SSH, but not from pwsh (it runs inside proot, and
   `proot-distro` can't nest):

   ```sh
   termux-setup-storage
   bash ~/storage/downloads/termux-setup/setup.sh
   ```

   Run single steps with `bash setup.sh 05-dotfiles.sh`. Output goes to `setup.log`.
4. Optional, from the PC once sshd is up: `bash push-host-keys.sh <phone-ip>` copies the PC's
   `id_rsa` to the phone over ssh.

| Step | Does |
|---|---|
| `01-base.sh` | Full upgrade, then openssh, git, curl, unzip, proot-distro |
| `02-identity.sh` | `$USER` and a `<user>@<device>` bash prompt from `USER_NAME` and `DEVICE_NAME` (default: phone model) |
| `03-ssh.sh` | PC key in `authorized_keys`, managed `~/.ssh/config` block, starts sshd on 8022 |
| `04-pwsh.sh` | Debian + latest PowerShell, `pwsh` wrapper, DNS for Debian; makes pwsh the default shell (SSH commands, scp and sftp use bash); every new session restarts sshd if Android killed it |
| `05-dotfiles.sh` | Clones dotfiles and runs its `setup.sh` inside Debian (links, oh-my-posh, Terminal-Icons, Nerd Font) |
| `06-shortcuts.sh` | Copies `shortcuts/` to `~/.shortcuts` for Termux:Widget and makes a `hibernate-<host>` shortcut for each of `HIBERNATE_HOSTS` |

For the `06-shortcuts.sh` shortcuts, install **Termux:Widget** from F-Droid and add its widget to
the home screen.

If pwsh breaks new sessions: long-press the Termux icon, choose **Failsafe**, then `rm ~/.termux/shell`.
Failsafe has no Termux `PATH`; start with `export PATH=/data/data/com.termux/files/usr/bin:$PATH`.
