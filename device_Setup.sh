#!/bin/bash

##################################
###   Author: Zac Reeves       ###
### - Setup usual folders      ###
### - Install some packages    ###
### - Configure neovim         ###
##################################

readonly archInstallArray=("alacritty" "fastfetch" "flatpak" "git" "github-cli" "htop" "jq" "man" "neovim" "nodejs" "ranger" "remmina" "tmux" "tree" "tuned" "unzip" "wl-clipboard" "zip")
readonly flatpakInstallArray=("io.gitlab.librewolf-community" "org.signal.Signal" "com.github.tchx84.Flatseal" "com.spotify.Client" "com.brave.Browser" "com.discordapp.Discord")
readonly macOSInstallArray=("fastfetch" "gh" "git" "jq" "neofetch" "neovim" "node" "ranger" "tmux" "tree")
readonly macOSInstallCaskArray=("alacritty" "discord" "firefox" "google-chrome" "imazing-profile-editor" "librewolf" "mullvad-browser" "mullvadvpn" "pppc-utility" "rustdesk" "signal" "spotify" "stats" "suspicious-package" "ticktick")
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

# Check for the current OS
function check_OS() {
    log_Message "OS Version:"
    if [[ -f '/usr/bin/pacman' ]];
    then
        log_Message "Arch Linux"
        osCheck='arch'
    elif [[ -f '/usr/bin/dnf' ]];
    then
        log_Message "Fedora Linux"
        osCheck='fedora'
    elif [[ -f '/usr/sbin/sysadminctl' ]];
    then
        log_Message "macOS"
        osCheck='macOS'
    else
        osCheck='Unknown'
        return 1
    fi
    deviceArch="$(/usr/bin/uname -m)"
    return 0
}

# Create the usual folders in Home directory
function create_Folderz() {
    log_Message "Creating folders in Home directory."
    if [[ ! -d "$userDir/Apps" ]];
    then
        log_Message "Creating Apps folder: $userDir/Apps"
        mkdir "$userDir/Apps"
    else
        log_Message "Apps folder located."
    fi
    if [[ ! -d "$userDir/Github" ]];
    then
        log_Message "Creating Github folder: $userDir/Github"
        mkdir "$userDir/Github"
    else
        log_Message "Github folder located."
    fi

    if [[ ! -d "$userDir/.config/nvim" ]];
    then
        log_Message "Creating Alacritty/Neovim ~/.config folders."
        mkdir -p "$userDir/.config/nvim/autoload"
        mkdir "$userDir/.config/alacritty"
    else
        log_Message "Alacritty/Neovim ~/.config folders located."
    fi
    log_Message "Completed folder creation."
}

# Install packages from archInstallArray that are not currently installed
function arch_PackageInstall() {
    log_Message "Altering pacman.conf."
    if sudo sed -i 's/.*ParallelDownloads.*/ParallelDownloads = 5/g' /etc/pacman.conf;
    then
        log_Message "Set parallel downloads."
        if sudo sed -i '/ParallelDownloads = 5/a ILoveCandy' /etc/pacman.conf;
        then
            log_Message "Set pacman loading icons."
        else
            log_Message "Unable to set pacman loading icons."
        fi
    else
        log_Message "Unable to set parallel downloads."
    fi
    log_Message "Completed altering pacman.conf."
    log_Message "Installing packages with pacman."
    sudo /usr/bin/pacman -Syyy
    for packageInstall in "${archInstallArray[@]}";
    do
        if ! /usr/bin/pacman -Q "$packageInstall" &> /dev/null;
        then
            log_Message "Installing $packageInstall"
            sudo /usr/bin/pacman -S "$packageInstall" --noconfirm
        else
            log_Message "Skipping $packageInstall, already installed."
        fi
    done
    log_Message "Completed installing packages with pacman."
}

# Will install packages from fedoraInstallArray that are not currently installed
function fedora_Install() {
    log_Message "Installing packages with dnf."
    printf "WIP\n"
    log_Message "Completed installing packages with dnf."
}

# Install flatpaks from flatpakInstallArray, including Rustdesk
function flatpak_Install() {
    log_Message "Installing packages with flatpak."
    flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    latestRelease=$(curl -s https://api.github.com/repos/rustdesk/rustdesk/releases/latest | jq -r .tag_name)
    if curl -fLo "$userDir/Apps/rustdesk.flatpak" "https://github.com/rustdesk/rustdesk/releases/download/${latestRelease}/rustdesk-${latestRelease#v}-${deviceArch}.flatpak";
    then
        log_Message "Installing Rustdesk"
        flatpak install --user -y "$userDir/Apps/rustdesk.flatpak"
    else
        log_Message "Unable to install Rustdesk."
    fi
    for pak in "${flatpakInstallArray[@]}";
    do
        log_Message "Installing $pak"
        flatpak install --user -y flathub "$pak"
    done
    log_Message "Completed installing packages with flatpak."
}

# Setup bashrc/zshrc with alias and editor
function configrc_Setup() {
    log_Message "Adding entries to $1."
    if [[ -f "$userDir/.$1" ]];
    then
        printf "alias ll='ls -l --color=auto'\n" >> "$userDir/.$1"
        printf "alias lla='ls -la --color=auto'\n" >> "$userDir/.$1"
        printf "alias scripts='cd ~/Github && ll'\n" >> "$userDir/.$1"
        printf "export EDITOR=/usr/bin/nvim\n" >> "$userDir/.$1"
    fi
    source "$userDir/.$1"
    log_Message "Completed adding entries to $1."
}

# Check for valid icon file, AppleScript dialog boxes will error without it
function icon_Check() {
    log_Message "Checking for icon file for AppleScript dialog windows."
    effectiveIconPath="$defaultIconPath"
    if [[ ! -f "$effectiveIconPath" ]];
    then
        log_Message "Unable to locate SLU icon."
        if [[ -f '/usr/local/bin/jamf' ]];
        then
            log_Message "Attempting icon install via Jamf."
            /usr/local/bin/jamf policy -event SLUFonts
        else
            log_Message "Unable to locate Jamf binary."
        fi
        if [[ ! -f "$effectiveIconPath" ]];
        then
            if [[ -f "$genericIconPath" ]];
            then
                log_Message "Generic icon located."
                effectiveIconPath="$genericIconPath"
            else
                log_Message "Unable to locate generic icon."
                return 1
            fi
        fi
    else
        log_Message "SLU icon located."
    fi
    log_Message "Completed icon file check."
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
    log_Message "Displaying text field dialog."
    while [[ $count -le 10 ]];
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
                log_Message "User responded: $textFieldDialog"
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
                log_Message "User responded: $textFieldDialog"
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
    log_Message "Displaying binary dialog."
    while [[ $count -le 10 ]];
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
                log_Message "User responded: $binDialog"
                return 1
                ;;
            'Timeout')
                log_Message "No response, re-prompting ($count/10)."
                ((count++))
                ;;
            *)
                log_Message "User responded: $binDialog"
                return 0
                ;;
        esac
    done
    return 1
}

# Install homebrew, rosetta if needed, then bunch of brew apps
function macOS_HomebrewInstall() {
    log_Message "Beginning Homebrew installation."
    if ! command -v brew &> /dev/null;
    then
        log_Message "Installing Homebrew."
        if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)";
        then
            log_Message "Completed Homebrew install."
        else
            log_Message "Unable to complete Homebrew install."
        fi
    else
        log_Message "Skipping Homebrew, already installed."
    fi
    if [[ "$deviceArch" == 'arm64' ]];
    then
        log_Message "Setting up Homebrew shell env."
        printf 'eval "$(/opt/homebrew/bin/brew shellenv)"\n' >> "$userDir/.zprofile"
        eval "$(/opt/homebrew/bin/brew shellenv)"
        log_Message "Completed Homebrew shell env setup."
        log_Message "Installing Rosetta."
        if /usr/sbin/softwareupdate --install-rosetta --agree-to-license;
        then
            log_Message "Completed Rosetta install."
        else
            log_Message "Unable to complete Rosetta install."
        fi
    fi
    # Check again for homebrew before using binary
    if command -v brew &>/dev/null;
    then
        log_Message "Installing applications using Homebrew."
        for brewInstall in "${macOSInstallArray[@]}";
        do
            if brew list "$brewInstall" &>/dev/null;
            then
                log_Message "Skipping $brewInstall, already installed."
            else
                log_Message "Installing $brewInstall"
                brew install "$brewInstall"
            fi
        done
        log_Message "Promping to download additional cask applications."
        if binary_Dialog "Would you like to download additional cask applications?";
        then
            for caskInstall in "${macOSInstallCaskArray[@]}";
            do
                if brew list --cask "$caskInstall" &>/dev/null;
                then
                    log_Message "Skipping $caskInstall, already installed"
                else
                    log_Message "Installing $caskInstall"
                    brew install --cask "$caskInstall"
                fi
            done
        else
            log_Message "No additional applications installed."
        fi
        log_Message "Completed Homebrew installation."
    else
        log_Message "Homebrew still not installed."
    fi
}

# Setup macOS zsh plugins and theme
function macOS_Shell() {
    log_Message "Installing oh-my-zsh."
    if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended;
    then
        log_Message "Completed oh-my-zsh install."
    else
        log_Message "Unable to complete oh-my-zsh install."
    fi
    log_Message "Installing powerlevel10k theme."
    if git clone https://github.com/romkatv/powerlevel10k.git "$userDir/.oh-my-zsh/themes/powerlevel10k";
    then
        log_Message "Completed powerlevel10k theme install."
    else
        log_Message "Unable to complete powerlevel10k theme install."
    fi
    log_Message "Installing zsh-autosuggestions plugin."
    if git clone https://github.com/zsh-users/zsh-autosuggestions "$userDir/.oh-my-zsh/plugins/zsh-autosuggestions";
    then
        log_Message "Completed zsh-autosuggestions plugin install."
    else
        log_Message "Unable to complete zsh-autosuggestions plugin install."
    fi
    log_Message "Installing zsh-syntax-highlighting plugin."
    if git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$userDir/.oh-my-zsh/plugins/zsh-syntax-highlighting";
    then
        log_Message "Completed zsh-syntax-highlighting plugin install."
    else
        log_Message "Unable to complete zsh-syntax-highlighting plugin install."
    fi
    log_Message "Setting zsh theme and plugins."
    sed -i '' -e 's/^ZSH_THEME="robbyrussell"$/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$userDir/.zshrc"
    sed -i '' -e 's/^plugins=(git)$/plugins=(git zsh-autosuggestions zsh-syntax-highlighting web-search)/' "$userDir/.zshrc"
    log_Message "Completed zsh configuration."
}

# Setup macOS dock to remove default apps and change orientation
function macOS_Dock() {
    log_Message "Checking Dock configuration."
    dockCheck=$(/usr/bin/defaults read "$userDir/Library/Preferences/com.apple.dock.plist" "persistent-apps" | grep 'file-label')
    dockCount=$(printf "$dockCheck" | grep -c 'file-label')
    if [[ ! "$dockCheck" == *"Alacritty"* ]];
    then
        log_Message "Backing up Dock plist and removing persistent applications."
        cp "$userDir/Library/Preferences/com.apple.dock.plist" "$userDir/Library/Preferences/com.apple.dock.OGbackup.plist"
        for i in $(/usr/bin/seq 3 $dockCount);
        do
            /usr/bin/plutil -remove 'persistent-apps.2' "$userDir/Library/Preferences/com.apple.dock.plist"
        done
        if [[ ! $(/usr/bin/plutil -lint "$userDir/Library/Preferences/com.apple.dock.plist") == *'OK'* ]];
        then
            log_Message "Reverting changes to Dock."
            mv "$userDir/Library/Preferences/com.apple.dock.plist" "$userDir/Library/Preferences/com.apple.dock.failed.plist"
            cp "$userDir/Library/Preferences/com.apple.dock.OGbackup.plist" "$userDir/Library/Preferences/com.apple.dock.plist"
        else
            log_Message "Orientating Dock to the left."
            /usr/bin/defaults write "$userDir/Library/Preferences/com.apple.dock.plist" "orientation" "left"
        fi
    fi
    /usr/bin/killall Dock
    log_Message "Completed Dock configuration."
}

# If alacritty is present, attempt to open it, then open security settings for approval
function macOS_AlacrittySecurity() {
    log_Message "Attempting to open Alacritty to then allow it though Gatekeeper."
    if [[ -d "/Applications/Alacritty.app" ]];
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
        log_Message "Alacritty not installed, installing using Homebrew."
        brew install --cask alacritty
    fi
}

# Setup neovim configuration file and plugin
function neovim_Setup() {
    log_Message "Setting up Neovim."
    if [[ -f "$scriptDir/init.vim" ]];
    then
        log_Message "Copying Neovim config to ~/.config/nvim"
        cp "$scriptDir/init.vim" "$userDir/.config/nvim/init.vim"
    else
        log_Message "Unable to locate Neovim config."
    fi
    log_Message "Installing vim-plug."
    if curl -fLo "$userDir/.config/nvim/autoload/plug.vim" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim;
    then
        log_Message "Completed vim-plug install."
    else
        log_Message "Unable to complete vim-plug install."
    fi
    log_Message "Completed Neovim setup."
}

# Setup alacritty configuration file
function alacritty_Setup() {
    log_Message "Setting up Alacritty."
    if [[ "$osCheck" == 'macOS' ]];
    then
        local fontPath="$userDir/Library/Fonts/Meslo/"
        local fontZIPPath="$userDir/Library/Fonts/Meslo.zip"
    else
        local fontPath="$userDir/.local/share/fonts/Meslo/"
        local fontZIPPath="$userDir/.local/share/fonts/Meslo.zip"
    fi
    if curl -fLo "$fontZIPPath" --create-dirs https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip;
    then
        log_Message "Installing MesloLGL Nerd Font Mono."
        unzip "$fontZIPPath" -d "$fontPath"
    else
        log_Message "Unable to locate MesloLGL Nerd Font Mono."
    fi
    if curl -fLo "$userDir/.config/alacritty/master.zip" https://github.com/dracula/alacritty/archive/master.zip;
    then
        log_Message "Installing Alacritty Dracula theme."
        unzip "$userDir/.config/alacritty/master.zip" -d "$userDir/.config/alacritty/"
    else
        log_Message "Unable to locate Alacritty Dracula theme."
    fi
    if [[ -f "$scriptDir/alacritty.toml" ]];
    then
        log_Message "Copying alacritty.toml to config folder."
        cp "$scriptDir/alacritty.toml" "$userDir/.config/alacritty/"
    else
        log_Message "Unable to copy alacritty.toml to config folder."
    fi
    log_Message "Completed Alacritty setup."
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
        'arch')
            printf "XDG_DATA_DIR=\"/usr/local/share:/usr/share\"\n" | sudo tee -a /etc/environment
            if [[ ! -f "$userDir/.bashrc" ]];
            then
                /usr/bin/touch "$userDir/.bashrc"
            fi
            arch_PackageInstall
            flatpak_Install
            configrc_Setup "bashrc"
            neovim_Setup
            alacritty_Setup
            if $(tuned-adm --version &>/dev/null);
            then
                sudo /usr/bin/systemctl enable tuned --now
                log_Message "Device type:"
                deviceChassis="$(/usr/bin/hostnamectl chassis &>/dev/null)"
                case "$deviceChassis" in
                    'laptop')
                        log_Message "Laptop"
                        log_Message "Setting tuned-adm profile: laptop-battery-powersave"
                        /usr/bin/tuned-adm profile laptop-battery-powersave
                        ;;
                    'desktop')
                        log_Message "Desktop"
                        log_Message "Setting tuned-adm profile: desktop"
                        /usr/bin/tuned-adm profile desktop
                        ;;
                    *)
                        log_Message "Unknown"
                        log_Message "Unable to set tuned-adm profile."
                        ;;
                esac
            fi
            ;;
        'fedora')
            if [[ ! -f "$userDir/.bashrc" ]];
            then
                /usr/bin/touch "$userDir/.bashrc"
            fi
            fedora_Install
            flatpak_Install
            configrc_Setup "bashrc"
            neovim_Setup
            alacritty_Setup
            ;;
        'macOS')
            if ! icon_Check;
            then
                alert_Dialog "Missing required icon files!"
                log_Message "Exiting for no icon."
                exit 1
            fi
            if [[ ! -f "$userDir/.zshrc" ]];
            then
                /usr/bin/touch "$userDir/.zshrc"
            fi
            log_Message "Prompting to name the device."
            if ! textField_Dialog "Please enter your desired device name:";
            then
                log_Message "Device not renamed."
            else
                /usr/sbin/scutil --set ComputerName $textFieldDialog
                /usr/sbin/scutil --set LocalHostName $textFieldDialog
                /usr/sbin/scutil --set HostName $textFieldDialog
                log_Message "Device renamed: $textFieldDialog"
            fi
            macOS_HomebrewInstall
            macOS_Shell
            macOS_Dock
            configrc_Setup "zshrc"
            neovim_Setup
            alacritty_Setup
            macOS_AlacrittySecurity
            ;;
        *)
            log_Message "Unable to determine OS."
            exit 1
            ;;
    esac
    if $(git --version &>/dev/null);
    then
        if git config --global user.email "129307974+archzaq@users.noreply.github.com";
        then
            log_Message "Set Github email."
        else
            log_Message "Unable to set Github email."
        fi
        if git config --global user.name "archzaq";
        then
            log_Message "Set Github user name."
        else
            log_Message "Unable to set Github user name."
        fi
    else
        log_Message "Unable to locate Git command."
    fi
    log_Message "Exiting!"
    exit 0
}

main

