# Device Setup

Idempotent setup script for macOS, Arch Linux, RHEL/clones, and Fedora (WIP) devices.

## What it does

- **Packages** — Installs CLI tools and apps via pacman, Homebrew, and Flatpak
- **Shell** — Configures bashrc/zshrc with aliases, editor, and oh-my-zsh
- **Neovim** — Copies config, installs vim-plug and plugins, sets up Coc extensions
- **Alacritty** — Installs MesloLGL Nerd Font, Dracula theme, and config
- **i3** — Sets keybinds, mod key, font size, and Nitrogen wallpaper restore
- **System** — Parallel downloads in pacman, tuned-adm power profiles, XDG paths, Git 
- **macOS extras** — Device rename, Homebrew, Rosetta, Dock cleanup, menu bar spacing

## Usage

```bash
./device_Setup.sh
```

A log file is written to `~/Desktop/device_Setup.log`.

## Included configs

| File | Description |
|---|---|
| `init.vim` | Neovim config with Dracula theme, vim-plug plugins, and Coc extensions |
| `alacritty.toml` | Alacritty config with MesloLGL Nerd Font, Dracula theme, 98% opacity |
| `config` | i3 window manager config template |

## Supported platforms

| OS | Package manager | Status |
|---|---|---|
| Arch Linux | pacman + flatpak | Supported |
| macOS | Homebrew | Supported |
| RHEL / Rocky / AlmaLinux / CentOS | dnf | Supported (config-focused) |
| Fedora | dnf + flatpak | WIP |
