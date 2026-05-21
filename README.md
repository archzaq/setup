# Device Setup

Idempotent setup for macOS, Arch Linux, RHEL/clones, and Fedora

## Usage

```bash
./device_Setup.sh
```

The bootstrap runs as your user, installs `ansible-core` via the native package manager (`pacman`/`dnf`/`brew`), pulls required collections, and runs `ansible/site.yml` against `localhost`.

Logs are written to `~/Desktop/device_Setup.log`.

### Common flags

Anything after `--` is forwarded to `ansible-playbook`.

```bash
./device_Setup.sh -- --check --diff             # dry run
./device_Setup.sh -- --tags shell,neovim        # only listed roles
./device_Setup.sh -- --skip-tags gnome,flatpaks # exclude roles
./device_Setup.sh -- -e install_casks=false     # override a variable
./device_Setup.sh --logfile /tmp/setup.log      # change log path
```

## What it does

| Role | Applies to | Behavior |
|---|---|---|
| `common` | all | `~/Apps`, `~/GitHub`, `~/.config/{nvim,alacritty}`, rc file, git identity |
| `repos` | linux | pacman / dnf tuning, EPEL / CRB / RPM Fusion |
| `packages` | linux | pacman / dnf install lists |
| `flatpaks` | arch, fedora | Flathub user remote + app list |
| `macos` | macOS | Homebrew + casks, Rosetta (arm64), Dock cleanup, menu bar spacing, hostname, Gatekeeper open |
| `shell` | all | aliases via `blockinfile`, oh-my-zsh + powerlevel10k + plugins on macOS |
| `neovim` | all | `init.vim`, vim-plug, `:PlugInstall`, `:CocInstall` |
| `alacritty` | all | MesloLGL Nerd Font, Dracula theme, `alacritty.toml`; source build on RHEL |
| `i3` | arch | `~/.config/i3/config` template (only installed if no config exists) |
| `tuned` | arch | chassis-aware power profile |
| `gnome` | rhel, fedora | dconf keybindings, custom Alacritty launcher |

## Supported platforms

| OS | Package manager | Status |
|---|---|---|
| Arch Linux | pacman + flatpak | Supported |
| macOS | Homebrew | Supported |
| RHEL / Rocky / AlmaLinux / CentOS Stream | dnf | Supported |
| Fedora | dnf + flatpak | Supported |

## Layout

```
device_Setup.sh
ansible/
├── ansible.cfg
├── inventory                # localhost
├── requirements.yml         # community.general, ansible.posix
├── site.yml                 # OS detection + role list
├── group_vars/all.yml       # git identity, install_casks, macos_device_name
└── roles/
    ├── common/              # cross-OS basics
    ├── repos/{arch,rhel,fedora}.yml
    ├── packages/{arch,rhel,fedora}.yml + vars/
    ├── flatpaks/
    ├── macos/{homebrew,packages,dock,hostname,alacritty_security}.yml
    ├── shell/{aliases,zsh}.yml
    ├── neovim/       files/init.vim
    ├── alacritty/    files/alacritty.toml
    ├── i3/           files/i3-config
    ├── tuned/
    └── gnome/
```

## Variables to override

Set in `ansible/group_vars/all.yml` or pass via `-e key=value`:

| Variable | Default | Purpose |
|---|---|---|
| `git_user_email` | (personal) | global `user.email` |
| `git_user_name` | (personal) | global `user.name` |
| `git_signing_key` | `~/.ssh/id_ed25519.pub` | global `user.signingkey` |
| `install_casks` | `true` | install Homebrew casks (macOS) |
| `macos_device_name` | `""` (prompted on macOS only) | leave blank to skip `scutil` rename |

