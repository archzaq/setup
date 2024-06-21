#!/bin/bash

##################################
###   Author: Zac Reeves       ###
### - Setup usual home folders ###
### - Install some packages    ###
### - Configure neovim         ###
### - Other cool things        ###
##################################

archInstallArray=("alacritty" "fastfetch" "flatpak" "git" "htop" "neovim" "nodejs" "ranger" "remmina" "tmux" "unzip" "wl-clipboard" "zip")
flatpakInstallArray=("io.gitlab.librewolf-community" "org.signal.Signal" "com.github.tchx84.Flatseal" "com.spotify.Client" "com.brave.Browser" "com.discordapp.Discord")
macOSInstallArray=("fastfetch" "gh" "git" "jq" "neofetch" "neovim" "node" "ranger" "tmux")
macOSInstallCaskArray=("alacritty" "discord" "github" "google-chrome" "imazing-profile-editor" "librewolf" "mullvad-browser" "mullvadvpn" "pppc-utility" "rectangle" "rustdesk" "signal" "spotify" "stats" "suspicious-package" "ticktick")
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

function macOS_Rename() {
    deviceName=$(osascript <<OOP
    set deviceName to (display dialog "Please enter your desired device name" buttons {"Cancel", "OK"} default button "OK" default answer "" with title "Device Naming" giving up after 900)
	    if button returned of deviceName is equal to "OK" then
	        return text returned of deviceName
	    else
	        return ""
	    end if
OOP
    )
    if [[ $? != 0 ]];
    then
        echo "Selected cancel"
        return 0
	elif [[ -z "$deviceName" ]];
	then
        echo "No name entered"
        macOS_Rename
    else
        /usr/sbin/scutil --set ComputerName $deviceName
        /usr/sbin/scutil --set LocalHostName $deviceName
        /usr/sbin/scutil --set HostName $deviceName
        return 0
    fi
}

# Install homebrew, rosetta if needed, a bunch of brew apps, then setup oh-my-zsh
function macOS_install() {
    # Install homebrew
    if ! command -v brew &> /dev/null;
    then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # Check device architecture
    if [ $(/usr/bin/uname -p) == 'arm' ];
    then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        /usr/sbin/softwareupdate --install-rosetta --agree-to-license
    fi

    # Check again for homebrew before using binary
    if command -v brew &>/dev/null;
    then
        # Homebrew install applications and casks
        for brewInstall in "${macOSInstallArray[@]}";
        do
            if brew list "$brewInstall" &>/dev/null;
            then
                echo "$brewInstall already installed"
            else
                brew install "$brewInstall"
            fi
        done

        # Ask to install additional apps
        if user_Prompt;
        then
            for caskInstall in "${macOSInstallCaskArray[@]}";
            do
                if brew list --cask "$caskInstall" &>/dev/null;
                then
                    echo "$caskInstall already installed"
                else
                    brew install --cask "$caskInstall"
                fi
            done
        fi
    fi

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
    else
        brew install --cask alacritty
    fi

    # Remove gross bits from the Dock
    customDockCheck=$(/usr/bin/defaults read ~/Library/Preferences/com.apple.dock.plist persistent-apps | grep 'file-label')
    dockCount=$(echo "$customDockCheck" | grep -c 'file-label')

    if [[ ! "$customDockCheck" == *"Alacritty"* ]];
    then
        cp ~/Library/Preferences/com.apple.dock.plist ~/Library/Preferences/com.apple.dock.OGbackup.plist
        for i in $(/usr/bin/seq 3 $dockCount);
        do
            /usr/bin/plutil -remove 'persistent-apps.2' ~/Library/Preferences/com.apple.dock.plist
        done

        if [[ ! $(/usr/bin/plutil -lint ~/Library/Preferences/com.apple.dock.plist) == *'OK'* ]];
        then
            mv ~/Library/Preferences/com.apple.dock.plist ~/Library/Preferences/com.apple.dock.failed.plist
            cp ~/Library/Preferences/com.apple.dock.OGbackup.plist ~/Library/Preferences/com.apple.dock.plist
        fi
        
        /usr/bin/killall Dock
    fi

    if macOS_Rename;
    then
        echo "Device renamed to $deviceName"
    fi
}

# Dialog box to inform user of the overall process taking place
function user_Prompt() {
    userPrompt=$(osascript <<OOP
    set userPrompt to (display dialog "Would you like to install additional apps?" buttons {"Cancel", "Continue"} default button "Continue" with title "Additional Applications" giving up after 900)
    if button returned of userPrompt is equal to "Continue" then
        return "Continue"
    else
        return "timeout"
    end if
OOP
    )
    if [[ $? != 0 ]];
    then
        echo "Log: User selected cancel"
        return 1
    elif [[ "$userPrompt" == 'Continue' ]];
    then
        echo "Log: User selected \"Continue\" to download additional apps"
        return 0
    else
        echo "Log: Reprompting with dialog box"
        user_Prompt
    fi
}

# Create my common folders
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

# Setup alacritty configuration file
function alacritty_setup() {
    curl -fLo ~/.config/alacritty/master.zip https://github.com/dracula/alacritty/archive/master.zip
    if [ -f ~/.config/alacritty/master.zip ];
    then
        unzip ~/.config/alacritty/master.zip -d ~/.config/alacritty/
    else
        echo "Alacritty master.zip not found"
    fi

    curl -fLo ~/Library/Fonts/Meslo.zip --create-dirs https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip   
    if [ -f ~/Library/Fonts/Meslo.zip ];
    then
        unzip ~/Library/Fonts/Meslo.zip -d ~/Library/Fonts/Meslo/
    else
        echo "Meslo font pack not found"
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
        echo "alias scripts='cd ~/OneDrive\ -\ Saint\ Louis\ University/_JAMF/Scripts && ls'" >> ~/."$1"
        echo "alias neofetch=\"echo 'did you mean fastfetch?'\"" >> ~/."$1"
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
        echo "XDG_DATA_DIR=\"/usr/local/share:/usr/share\"" | sudo tee -a /etc/environment
        arch_install
        flatpak_install
        configrc_setup bashrc

    # If fedora, install using dnf and flatpak, then configure bashrc
    elif [ "$fedora" == true ];
    then
        fedora_install
        flatpak_install
        configrc_setup bashrc

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

