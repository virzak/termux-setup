# termux-setup

Rebuilds my Termux on a fresh install: `$USER`/prompt, sshd and ssh client config,
PowerShell (linux-arm64 in proot-distro Debian) as the default shell, and
[virzak/dotfiles](https://github.com/virzak/dotfiles) with oh-my-posh and a Nerd Font.
Every step is safe to re-run.

## Use

1. Optional: copy `local.env.example` to `local.env` and `ssh_config.local.example` to
   `ssh_config.local`, and fill them in. Both are gitignored.
2. Copy this folder to the phone's Download folder, e.g. `adb push . /sdcard/Download/termux-setup/`.
3. In a local Termux session:

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
| `04-pwsh.sh` | Debian + latest PowerShell, `pwsh` wrapper, DNS for Debian |
| `05-dotfiles.sh` | Clones dotfiles, links configs, oh-my-posh, Terminal-Icons, Meslo Nerd Font, pwsh as default shell |
| `06-shortcuts.sh` | Copies `shortcuts/` to `~/.shortcuts` for Termux:Widget and makes a `hibernate-<host>` shortcut for each of `HIBERNATE_HOSTS` |

If pwsh breaks new sessions: long-press the Termux icon, choose **Failsafe**, then `rm ~/.termux/shell`.
