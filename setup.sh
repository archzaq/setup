#!/bin/bash

##############################
# - Setup usual home folders #
# - Install some packages    #
# - Configure neovim         #
# - Other cool things        #
##############################

archInstallArray=("neovim" "neofetch" "htop" "ranger" "wl-clipboard" "flatpak" "git" "remmina")
flatpakInstallArray=("io.gitlab.librewolf-community" "org.signal.Signal" "com.github.tchx84.Flatseal" "com.spotify.Client" "com.brave.Browser" "com.discordapp.Discord")
macOSInstallArray=("gh" "git" "neofetch" "neovim" "node" "ranger" "tmux")
macOSInstallCaskArray=("alacritty" "bitwarden" "discord" "github" "google-chrome" "imazing-profile-editor" "librewolf" "mullvad-browser" "mullvadvpn" "pppc-utility" "rectangle" "rustdesk" "signal" "spotify" "stats" "suspicious-package" "ticktick")
arch=false
fedora=false
macOS=false
scriptDir="$(dirname "$0")"

# Least optimal way to check OS
function check_package_manager() {
    if which pacman >/dev/null 2>&1;
    then
        arch=true
    elif which dnf >/dev/null 2>&1;
    then
        fedora=true
    elif which sysadminctl >/dev/null 2>&1;
    then
        macOS=true
    fi
}

# Install packages from archInstallArray that are not currently installed
function arch_install() {
    sudo pacman -Syyy
    for packageInstall in "${archInstallArray[@]}";
    do
        if ! pacman -Q "$packageInstall" &> /dev/null;
        then
            sudo pacman -S "$packageInstall" --noconfirm
        fi
    done
}

function fedora_install() {
    echo "WIP"
}

# Install homebrew, rosetta if needed, a bunch of brew apps, then setup oh-my-zsh
function macOS_install() {
    # Install homebrew
    if ! command -v brew &> /dev/null;
    then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    if [ $(/usr/bin/uname -p) == 'arm' ];
    then
        (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> /Users/$USER/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
        /usr/sbin/softwareupdate --install-rosetta --agree-to-license
    fi

    # homebrew install applications and casks
    for brewInstall in "${macOSInstallArray[@]}";
    do
        brew install "$brewInstall"
    done

    for caskInstall in "${macOSInstallCaskArray[@]}";
    do
        brew install --cask "$caskInstall"
    done

    # oh-my-zsh setup
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    git clone https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/themes/powerlevel10k
    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/plugins/zsh-syntax-highlighting

    # zshrc setup
    sed -i '' -e 's/^ZSH_THEME="robbyrussell"$/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
    sed -i '' -e 's/^plugins=(git)$/plugins=(git zsh-autosuggestions zsh-syntax-highlighting web-search)/' ~/.zshrc
    echo '# run p10k configure if not already ran' >> ~/.zshrc

    # If alacritty is present, attempt to open it, then open security settings for approval
    if [ -f /opt/homebrew/bin/alacritty ];
    then
        /opt/homebrew/bin/alacritty &
        
        if [[ $(sw_vers -productVersion) < 13.0 ]];
        then
            open "x-apple.systempreferences:com.apple.preference.security"
        else
            open "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension"
        fi
    fi

    # Remove gross bits from the Dock
    cp ~/Library/Preferences/com.apple.dock.plist ~/Libary/Preferences/com.apple.dock.OGbackup.plist
    for i in {1..14};
    do
        /usr/bin/plutil -remove 'persistent-apps.2' ~/Library/Preferences/com.apple.dock.plist
    done

    if [[ ! $(/usr/bin/plutil -lint ~/Library/Preferences/com.apple.dock.plist) == *'OK'* ]];
    then
        mv ~/Library/Preferences/com.apple.dock.plist ~/Library/Preferences/com.apple.dock.failed.plist
        mv ~/Library/Preferences/com.apple.dock.OGbackup.plist ~/Library/Preferences/com.apple.dock.plist
    fi

    /usr/bin/killall Dock
}

# Create common folders
function create_folderz() {
    if [ ! -d ~/Apps ];
    then
        mkdir ~/Apps
    fi

    if [ ! -d ~/.config/nvim ];
    then
        mkdir -p ~/.config/nvim/autoload
        mkdir -p ~/.config/alacritty
    fi

    if [ ! -d ~/Documents/Notes ];
    then
        mkdir -p ~/Documents/Notes
    fi

    if [ ! -d ~/Documents/Scripts ];
    then
        mkdir -p ~/Documents/Scripts
    fi
}

# Install flatpaks from flatpakInstallArray, including rustdesk. LIKELY TO BREAK
function flatpak_install() {
    flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    curl -fLo ~/Apps/rustdesk.flatpak https://github.com/rustdesk/rustdesk/releases/download/1.2.3-1/rustdesk-1.2.3-x86_64.flatpak
    if [ -f ~/Apps/rustdesk.flatpak ];
    then
        flatpak install --user -y ~/Apps/rustdesk.flatpak
    else
        echo "Rustdesk flatpak not installed"
        echo "Check https://github.com/rustdesk/rustdesk/releases/"
        read
    fi

    for pak in "${flatpakInstallArray[@]}";
    do
        flatpak install --user -y flathub "$pak"
    done
}

# Work in progress, similar issue to oh-mh-zsh
function alacritty_compile() {
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    . "$HOME/.cargo/env"
    rustup override set stable
    rustup update stable
    git clone https://github.com/alacritty/alacritty.git --directory ~/Apps/alacritty
    cd ~/Apps/alacritty
    cargo build --release
    sudo cp target/release/alacritty /usr/local/bin
    sudo cp extra/logo/alacritty-term.svg /usr/share/pixmaps/Alacritty.svg
    sudo desktop-file-install extra/linux/Alacritty.desktop
    sudo update-desktop-database
    mkdir -p ~/.bash_completion
    cp extra/completions/alacritty.bash ~/.bash_completion/alacritty
    echo "source ~/.bash_completion/alacritty" >> ~/.bashrc
    cd ~
}

# Setup alacritty configuration file
function alacritty_setup() {
    curl -fLo ~/.config/alacritty/master.zip https://github.com/dracula/alacritty/archive/master.zip
    if [ -f ~/.config/alacritty/master.zip ];
    then
        unzip ~/.config/alacritty/master.zip -d ~/.config/alacritty/
    else
        echo "Alacritty master.zip not found"
    fi
    cp "$scriptDir/alacritty.toml" ~/.config/alacritty/
}

# Setup bashrc/zshrc with alias and editor
function configrc_setup() {
    if [ -f ~/."$1" ];
    then
        echo "alias ls='ls -l --color=auto'" >> ~/."$1"
        echo "alias ll='ls -la --color=auto'" >> ~/."$1"
        echo "alias notes='cd ~/Documents/Notes/ && ls'" >> ~/."$1"
        echo "alias scripts='cd ~/Documents/Scripts/ && ls'" >> ~/."$1"
        echo "export EDITOR=/usr/bin/nvim" >> ~/."$1"
    fi
    source ~/."$1"
}

# Setup neovim configuration file and plugin
function neovim_setup() {
    if [ -f "$scriptDir/init.vim" ];
    then
        cp "$scriptDir/init.vim" ~/.config/nvim/init.vim
    fi
    curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
}

# Do the thing
function main() {
    create_folderz

    check_package_manager

    # If arch, install using pacman and flatpak, then configure bashrc
    if [ "$arch" == true ];
    then
        arch_install
        sudo pacman -S cmake freetype2 fontconfig pkg-config make libxcb libxkbcommon python --noconfirm
        flatpak_install
        configrc_setup bashrc
        # alacritty_compile

    # If fedora, install using dnf and flatpak, then configure bashrc
    elif [ "$fedora" == true ];
    then
        fedora_install
        sudo dnf install -y cmake freetype-devel fontconfig-devel libxcb-devel libxkbcommon-devel g++
        flatpak_install
        configrc_setup bashrc
        # alacritty_compile

    # If macOS, install using brew, then configure zshrc
    elif [ "$macOS" == true ];
    then
        if [ ! -f ~/.zshrc ];
        then
            /usr/bin/touch ~/.zshrc
        fi
        macOS_install
        configrc_setup zshrc
    fi

    neovim_setup
    alacritty_setup

}

main
