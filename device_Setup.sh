#!/bin/bash

##################################
###   Author: Zac Reeves       ###
### - Setup usual folders      ###
### - Install some packages    ###
### - Configure neovim         ###
##################################

archInstallArray=("alacritty" "fastfetch" "flatpak" "git" "htop" "jq" "neovim" "nodejs" "ranger" "remmina" "tmux" "unzip" "wl-clipboard" "zip")
flatpakInstallArray=("io.gitlab.librewolf-community" "org.signal.Signal" "com.github.tchx84.Flatseal" "com.spotify.Client" "com.brave.Browser" "com.discordapp.Discord")
macOSInstallArray=("fastfetch" "gh" "git" "jq" "neofetch" "neovim" "node" "ranger" "tmux" "tree")
macOSInstallCaskArray=("alacritty" "discord" "google-chrome" "imazing-profile-editor" "librewolf" "mullvad-browser" "mullvadvpn" "pppc-utility" "rustdesk" "signal" "spotify" "stats" "suspicious-package" "ticktick")
readonly scriptDir="$(dirname "$0")"
readonly userDir="$HOME"
readonly defaultIconPath='/usr/local/jamfconnect/SLU.icns'
readonly genericIconPath='/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/Everyone.icns'
readonly dialogTitle='Device Setup'
readonly logPath="$userDir/Desktop/device_Setup.log"

# Append current status to log file
function log_Message() {
    printf "Log: $(date "+%F %T") %s\n" "$1" | tee -a "$logPath"
}

# Least optimal way to check OS
function check_OS() {
    if [[ -f '/usr/bin/pacman' ]];
    then
        log_Message "Using Arch Linux."
        osCheck='arch'
    elif [[ -f '/usr/bin/dnf' ]];
    then
        log_Message "Using Fedora Linux."
        osCheck='fedora'
    elif [[ -f '/usr/sbin/sysadminctl' ]];
    then
        log_Message "Using macOS."
        osCheck='macOS'
    else
        osCheck='Unknown'
        return 1
    fi
    return 0
}

# Create the usual folders
function create_Folderz() {
    if [ ! -d "$userDir/Apps" ];
    then
        log_Message "Creating Apps folder."
        mkdir "$userDir/Apps"
    fi
    if [ ! -d "$userDir/.config/nvim" ];
    then
        log_Message "Creating Neovim and Alacritty config folders."
        mkdir -p "$userDir/.config/nvim/autoload"
        mkdir -p "$userDir/.config/alacritty"
    fi
}

# Install packages from archInstallArray that are not currently installed
function arch_Install() {
    sudo pacman -Syyy
    for packageInstall in "${archInstallArray[@]}";
    do
        if ! pacman -Q "$packageInstall" &> /dev/null;
        then
            log_Message "Installing $packageInstall"
            sudo pacman -S "$packageInstall" --noconfirm
        fi
    done
}

# Will install packages from fedoraInstallArray that are not currently installed
function fedora_Install() {
    echo "WIP"
}

# Install flatpaks from flatpakInstallArray, including rustdesk
function flatpak_Install() {
    flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    latestRelease=$(curl -s https://api.github.com/repos/rustdesk/rustdesk/releases/latest | jq -r .tag_name)
    curl -fLo "$userDir/Apps/rustdesk.flatpak" "https://github.com/rustdesk/rustdesk/releases/download/${latestRelease}/rustdesk-${latestRelease#v}-x86_64.flatpak"
    if [ -f "$userDir/Apps/rustdesk.flatpak" ];
    then
        log_Message "Installing Rustdesk flatpak."
        flatpak install --user -y "$userDir/Apps/rustdesk.flatpak"
    else
        log_Message "Rustdesk flatpak not installed"
    fi
    for pak in "${flatpakInstallArray[@]}";
    do
        log_Message "Installing $pak flatpak."
        flatpak install --user -y flathub "$pak"
    done
}

# Setup bashrc/zshrc with alias and editor
function configrc_Setup() {
    if [ -f "$userDir/.$1" ];
    then
        printf "alias ll='ls -l --color=auto'" >> "$userDir/.$1"
        printf "alias lla='ls -la --color=auto'" >> "$userDir/.$1"
        printf "alias scripts='cd ~/OneDrive\ -\ Saint\ Louis\ University/_JAMF/Scripts && ls'" >> "$userDir/.$1"
        printf "export EDITOR=/usr/bin/nvim" >> "$userDir/.$1"
        log_Message "Created a couple alias in $1."
    fi
    source "$userDir/.$1"
}

# Check for valid icon file, AppleScript dialog boxes will error without it
function icon_Check() {
    effectiveIconPath="$defaultIconPath"
    if [[ ! -f "$effectiveIconPath" ]];
    then
        log_Message "No SLU icon found."
        if [[ -f '/usr/local/bin/jamf' ]];
        then
            log_Message "Attempting icon install via Jamf."
            /usr/local/bin/jamf policy -event SLUFonts
        else
            log_Message "No Jamf binary found."
        fi
        if [[ ! -f "$effectiveIconPath" ]];
        then
            if [[ -f "$genericIconPath" ]];
            then
                log_Message "Generic icon found."
                effectiveIconPath="$genericIconPath"
            else
                log_Message "Generic icon not found."
                return 1
            fi
        fi
    else
        log_Message "SLU icon found."
    fi
    return 0
}

# AppleScript - Create alert dialog window
function alert_Dialog() {
    local promptString="$1"
    log_Message "Displaying alert dialog."
    alertDialog=$(/usr/bin/osascript <<OOP
    try
        set promptString to "$promptString"
        set choice to (display alert promptString as critical buttons "OK" default button 1 giving up after 900)
        if (gave up of choice) is true then
            return "Timeout"
        else
            return (button returned of choice)
        end if
    on error
        return "Error"
    end try
OOP
    )
    case "$alertDialog" in
        'Error')
            log_Message "Unable to show alert dialog."
            ;;
        'Timeout')
            log_Message "Alert timed out."
            ;;
        *)
            log_Message "Continued through alert dialog."
            ;;
    esac
}

# AppleScript - Text field dialog prompt for inputting information
function textField_Dialog() {
    local promptString="$1"
    local count=1
    while [ $count -le 10 ];
    do
        textFieldDialog=$(/usr/bin/osascript <<OOP
        try
            set promptString to "$promptString"
            set iconPath to "$effectiveIconPath"
            set dialogTitle to "$dialogTitle"
            set dialogResult to (display dialog promptString buttons {"Cancel", "OK"} default button "OK" with answer default answer "" with icon POSIX file iconPath with title dialogTitle giving up after 900)
            set buttonChoice to button returned of dialogResult
            if buttonChoice is equal to "OK" then
                return text returned of dialogResult
            else
                return "Timeout"
            end if
        on error
            return "Cancel"
        end try
OOP
        )
        case "$textFieldDialog" in
            'Cancel')
                log_Message "User responded with: $textFieldDialog"
                return 1
                ;;
            'Timeout')
                log_Message "No response, re-prompting ($count/10)."
                ((count++))
                ;;
            '')
                log_Message "Nothing entered in text field."
                alert_Dialog "Please enter something."
                ;;
            *)
                log_Message "User responded with: $textFieldDialog"
                return 0
                ;;
        esac
    done
    return 1
}

# AppleScript - Informing the user and giving them two choices
function binary_Dialog() {
    local promptString="$1"
    local count=1
    while [ $count -le 10 ];
    do
        binDialog=$(/usr/bin/osascript <<OOP
        try
            set promptString to "$promptString"
            set iconPath to "$effectiveIconPath"
            set dialogTitle to "$dialogTitle"
            set dialogResult to (display dialog promptString buttons {"Cancel", "OK"} default button "OK" with icon POSIX file iconPath with title dialogTitle giving up after 900)
            set buttonChoice to button returned of dialogResult
            if buttonChoice is equal to "" then
                return "Timeout"
            else
                return buttonChoice
            end if
        on error
            return "Cancel"
        end try
OOP
        )
        case "$binDialog" in
            'Cancel')
                log_Message "User responded with: $binDialog"
                return 1
                ;;
            'Timeout')
                log_Message "No response, re-prompting ($count/10)."
                ((count++))
                ;;
            *)
                log_Message "User responded with: $binDialog"
                return 0
                ;;
        esac
    done
    return 1
}

# Install homebrew, rosetta if needed, a bunch of brew apps, then setup oh-my-zsh
function macOS_Install() {
    # Install homebrew
    if ! command -v brew &> /dev/null;
    then
        log_Message "Homebrew not installed, installing homebrew."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # Check device architecture
    if [ $(/usr/bin/uname -p) == 'arm' ];
    then
        log_Message "Architecture: arm"
        log_Message "Finishing Homebrew install and installing Rosetta."
        printf 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$userDir/.zprofile"
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
                log_Message "$brewInstall already installed."
            else
                brew install "$brewInstall"
                log_Message "Installed $brewInstall using Homebrew."
            fi
        done

        # Ask to install additional apps
        if binary_Dialog "Would you like to download additional Applications?";
        then
            for caskInstall in "${macOSInstallCaskArray[@]}";
            do
                if brew list --cask "$caskInstall" &>/dev/null;
                then
                    log_Message "$caskInstall already installed"
                else
                    brew install --cask "$caskInstall"
                    log_Message "Installed $caskInstall using Homebrew."
                fi
            done
        else
            log_Message "No additional applications installed."
        fi
    fi

    # oh-my-zsh setup
    log_Message "Installing oh-my-zsh."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    git clone https://github.com/romkatv/powerlevel10k.git "$userDir/.oh-my-zsh/themes/powerlevel10k"
    git clone https://github.com/zsh-users/zsh-autosuggestions "$userDir/.oh-my-zsh/plugins/zsh-autosuggestions"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$userDir/.oh-my-zsh/plugins/zsh-syntax-highlighting"

    # zshrc setup
    log_Message "Setting zsh theme and plugins."
    sed -i '' -e 's/^ZSH_THEME="robbyrussell"$/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$userDir/.zshrc"
    sed -i '' -e 's/^plugins=(git)$/plugins=(git zsh-autosuggestions zsh-syntax-highlighting web-search)/' "$userDir/.zshrc"

    # If alacritty is present, attempt to open it, then open security settings for approval
    if [ -f /opt/homebrew/bin/alacritty ];
    then
        log_Message "Opening Alacritty."
        /usr/bin/open /Applications/Alacritty.app &
        log_Message "Opening Privacy & Security Settings."
        if [[ $(sw_vers -productVersion) < 13.0 ]];
        then
            open "x-apple.systempreferences:com.apple.preference.security"
        else
            open "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension"
        fi
    else
        brew install --cask alacritty
        log_Message "Installing Alacritty using Homebrew."
    fi

    # Remove gross bits from the Dock
    log_Message "Checking Dock for Alacritty."
    customDockCheck=$(/usr/bin/defaults read "$userDir/Library/Preferences/com.apple.dock.plist" "persistent-apps" | grep 'file-label')
    dockCount=$(printf "$customDockCheck" | grep -c 'file-label')
    if [[ ! "$customDockCheck" == *"Alacritty"* ]];
    then
        log_Message "Alacritty not found in Dock."
        cp "$userDir/Library/Preferences/com.apple.dock.plist" "$userDir/Library/Preferences/com.apple.dock.OGbackup.plist"
        for i in $(/usr/bin/seq 3 $dockCount);
        do
            /usr/bin/plutil -remove 'persistent-apps.2' "$userDir/Library/Preferences/com.apple.dock.plist"
        done

        if [[ ! $(/usr/bin/plutil -lint "$userDir/Library/Preferences/com.apple.dock.plist") == *'OK'* ]];
        then
            mv "$userDir/Library/Preferences/com.apple.dock.plist" "$userDir/Library/Preferences/com.apple.dock.failed.plist"
            cp "$userDir/Library/Preferences/com.apple.dock.OGbackup.plist" "$userDir/Library/Preferences/com.apple.dock.plist"
        fi
        /usr/bin/killall Dock
    fi
}

# Setup neovim configuration file and plugin
function neovim_Setup() {
    log_Message "Setting up Neovim."
    if [ -f "$scriptDir/init.vim" ];
    then
        cp "$scriptDir/init.vim" "$userDir/.config/nvim/init.vim"
    else
        log_Message "Unable to locate Neovim config."
    fi
    log_Message "Installing vim-plug."
    curl -fLo "$userDir/.config/nvim/autoload/plug.vim" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
}

# Setup alacritty configuration file
function alacritty_Setup() {
    log_Message "Setting up Alacritty."
    curl -fLo "$userDir/.config/alacritty/master.zip" https://github.com/dracula/alacritty/archive/master.zip
    if [ -f "$userDir/.config/alacritty/master.zip" ];
    then
        unzip "$userDir/.config/alacritty/master.zip" -d "$userDir/.config/alacritty/"
    else
        log_Message "Alacritty master.zip not found."
    fi

    curl -fLo "$userDir/Library/Fonts/Meslo.zip" --create-dirs https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip   
    if [ -f "$userDir/Library/Fonts/Meslo.zip" ];
    then
        unzip "$userDir/Library/Fonts/Meslo.zip" -d "$userDir/Library/Fonts/Meslo/"
    else
        log_Message "Meslo font pack not found."
    fi
    
    if [[ -f "$scriptDir/alacritty.toml" ]];
    then
        cp "$scriptDir/alacritty.toml" "$userDir/.config/alacritty/"
    else
        log_Message "Alacritty config not found."
    fi
}

function main() {
    printf "Log: $(date "+%F %T") Beginning Device Setup script.\n" | tee "$logPath"

    if ! check_OS;
    then
        log_Message "Unable to determine OS."
        exit 1
    fi

    create_Folderz

    case "$osCheck" in
        # If Arch, install using pacman and flatpak, then configure bashrc
        'arch')
            printf "XDG_DATA_DIR=\"/usr/local/share:/usr/share\"" | sudo tee -a /etc/environment
            if [ ! -f "$userDir/.bashrc" ];
            then
                /usr/bin/touch "$userDir/.bashrc"
            fi
            arch_Install
            flatpak_Install
            configrc_Setup "bashrc"
            ;;

        # If Fedora, install using dnf and flatpak, then configure bashrc
        'fedora')
            if [ ! -f "$userDir/.bashrc" ];
            then
                /usr/bin/touch "$userDir/.bashrc"
            fi
            fedora_Install
            flatpak_Install
            configrc_Setup "bashrc"
            ;;

        # If macOS, install using brew, then configure zshrc
        'macOS')
            if ! icon_Check;
            then
                alert_Dialog "Missing required icon files!"
                log_Message "Exiting for no icon."
                exit 1
            fi

            if [ ! -f "$userDir/.zshrc" ];
            then
                /usr/bin/touch "$userDir/.zshrc"
            fi

            if ! textField_Dialog "Please enter your desired device name:";
            then
                log_Message "Device not renamed."
            else
                /usr/sbin/scutil --set ComputerName $textFieldDialog
                /usr/sbin/scutil --set LocalHostName $textFieldDialog
                /usr/sbin/scutil --set HostName $textFieldDialog
                log_Message "Device renamed to $textFieldDialog"
            fi

            macOS_Install
            configrc_Setup "zshrc"
            ;;
        *)
            log_Message "Unable to determine OS."
            exit 1
            ;;
    esac

    neovim_Setup
    alacritty_Setup
}

main

