#!/bin/bash

##################################
###   Author: Zac Reeves	   ###
### - Setup usual folders	   ###
### - Install some packages    ###
### - Configure neovim		   ###
##################################

readonly archInstallArray=("alacritty" "dmenu" "fastfetch" "flatpak" "git" "github-cli" "htop" "i3-wm" "i3lock" "i3status" "jq" "man" "neovim" "nitrogen" "nodejs" "ranger" "remmina" "shutter" "tmux" "tree" "tuned" "unzip" "wl-clipboard" "zip")
readonly flatpakInstallArray=("com.brave.Browser" "com.discordapp.Discord" "com.github.tchx84.Flatseal" "io.gitlab.librewolf-community" "com.rustdesk.RustDesk" "org.signal.Signal" "com.spotify.Client")
readonly macOSInstallArray=("fastfetch" "gh" "git" "jq" "neofetch" "neovim" "node" "ranger" "tmux" "tree")
readonly macOSInstallCaskArray=("alacritty" "discord" "firefox" "google-chrome" "imazing-profile-editor" "librewolf" "mullvadvpn" "pppc-utility" "rustdesk" "signal" "spotify" "stats" "suspicious-package" "ticktick")
readonly rhelInstallArray=("cargo" "cmake" "curl" "freetype-devel" "fontconfig-devel" "libxcb-devel" "libxkbcommon-devel" "git" "neovim" "tmux" "tree" "unzip" "vim-enhanced")
readonly scriptDir="$(dirname "$0")"
readonly userDir="$HOME"
readonly genericIconPath='/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/Everyone.icns'
readonly dialogTitle='Device Setup'
readonly logFile="$userDir/Desktop/device_Setup.log"

# Append current status to log file
function log_Message() {
    local message="$1"
    local type="${2:-Log}"
    local timestamp="$(date "+%F %T")"
    if [[ -w "$logFile" ]];
    then
        printf "%s: %s %s\n" "$type" "$timestamp" "$message" | tee -a "$logFile"
    else
        printf "%s: %s %s\n" "$type" "$timestamp" "$message"
    fi
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
		if [[ -f '/etc/fedora-release' ]];
		then
			log_Message "Fedora Linux"
			osCheck='fedora'
		else
			log_Message "RHEL Linux"
			osCheck='rhel'
		fi
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
function create_GeneralFolders() {
	log_Message "Creating folders in Home directory"
	if [[ ! -d "$userDir/Apps" ]];
	then
		log_Message "Creating Apps folder: $userDir/Apps"
		mkdir "$userDir/Apps"
	else
		log_Message "Apps folder located"
	fi
	if [[ ! -d "$userDir/Github" ]];
	then
		log_Message "Creating Github folder: $userDir/Github"
		mkdir "$userDir/Github"
	else
		log_Message "Github folder located"
	fi
	if [[ ! -d "$userDir/.config/nvim" ]];
	then
		log_Message "Creating Alacritty/Neovim ~/.config folders"
		mkdir -p "$userDir/.config/nvim/autoload"
		mkdir "$userDir/.config/alacritty"
	else
		log_Message "Alacritty/Neovim ~/.config folders located"
	fi
	log_Message "Completed folder creation"
}

function arch_ConfigFiles() {
	local pacmanConf='/etc/pacman.conf'
	if [ -f "$pacmanConf" ];
	then
		log_Message "Attempting to alter pacman.conf"
		if sudo sed -i 's/.*ParallelDownloads.*/ParallelDownloads = 5/g' $pacmanConf;
		then
			log_Message "Set parallel downloads"
			if grep -q 'ILoveCandy' "$pacmanConf";
			then
				log_Message "Pacman loading icons already set"
			elif sudo sed -i '/ParallelDownloads = 5/a ILoveCandy' $pacmanConf;
			then
				log_Message "Set pacman loading icons"
			else
				log_Message "Unable to set pacman loading icons" "WARN"
			fi
		else
			log_Message "Unable to set parallel downloads" "WARN"
		fi
		log_Message "Completed altering pacman.conf"
	else
		log_Message "Unable to locate pacman.conf at $pacmanConf" "WARN"
	fi

	if [[ ! -d "$userDir/.config/i3" ]];
	then
		log_Message "Creating i3 folder: $userDir/.config/i3"
		mkdir "$userDir/.config/i3"
		mkdir "$userDir/.config/i3status"
	else
		log_Message "i3 folder located"
	fi

	local i3Conf="$userDir/.config/i3/config"
	if [ -f "$i3Conf" ];
	then
		log_Message "Attempting to alter i3 config"
		if sudo sed -i 's/set $mod Mod.*/set $mod Mod4/g' $i3Conf;
		then
			log_Message 'Set $mod to Mod4'
			if grep -q 'nitrogen --restore' "$i3Conf";
			then
				log_Message "Nitrogen restore already set"
			elif sudo sed -i '/set $mod Mod4/a exec --no-startup-id /usr/bin/nitrogen --restore' $i3Conf;
			then
				log_Message "Set Nitrogen to restore"
			else
				log_Message "Unable to set Nitrogen to restore" "WARN"
			fi
		else
			log_Message 'Unable to set $mod' "WARN"
		fi

		if sudo sed -i 's/font pango.*/font pango:monospace 10/g' $i3Conf;
		then
			log_Message "Title bar font size changed to 10"
		else
			log_Message "Unable to change title bar font size" "WARN"
		fi

		if sudo sed -i 's/bindsym $mod+Return exec.*/bindsym $mod+Return exec alacritty/g' $i3Conf;
		then
			log_Message "Changed terminal keybind to open Alacritty"
		else
			log_Message "Unable to change terminal keybind to Alacritty" "WARN"
		fi

		if sudo sed -i 's/bindsym $mod+Shift+q kill/bindsym $mod+q kill/g' $i3Conf;
		then
			log_Message "Changed kill keybind to Super+Q"
		else
			log_Message "Unable to change kill keybind" "WARN"
		fi
	else
		log_Message "Unable to locate i3 config at $i3Conf" "WARN"
		if [[ -f "$scriptDir/config" ]];
		then
			log_Message "Copying i3 config to ~/.config/i3"
			cp "$scriptDir/config" "$userDir/.config/i3/config"
		else
			log_Message "Unable to locate i3 config at $scriptDir" "WARN"
		fi
	fi
}

# Install packages from archInstallArray that are not currently installed
function arch_PackageInstall() {
	log_Message "Beginning package install with pacman"
	sudo /usr/bin/pacman -Syyy
	for packageInstall in "${archInstallArray[@]}";
	do
		if ! /usr/bin/pacman -Q "$packageInstall" &> /dev/null;
		then
			log_Message "Installing $packageInstall"
			sudo /usr/bin/pacman -S "$packageInstall" --noconfirm
		else
			log_Message "Skipping $packageInstall, already installed"
		fi
	done
	log_Message "Completed installing packages with pacman"
}

# Will install packages from fedoraInstallArray that are not currently installed
function fedora_Install() {
	log_Message "Beginning package install with dnf"
	printf "WIP\n"
	log_Message "Completed installing packages with dnf"
}

function rhel_ConfigFiles() {
	local dnfConf='/etc/dnf/dnf.conf'
	if [ -f "$dnfConf" ];
	then
		log_Message "Attempting to alter dnf.conf"
		if grep -q '^max_parallel_downloads' "$dnfConf";
		then
			log_Message "Parallel downloads already set"
		elif printf 'max_parallel_downloads=10\n' | sudo tee -a "$dnfConf" > /dev/null;
		then
			log_Message "Set parallel downloads"
		else
			log_Message "Unable to set parallel downloads" "WARN"
		fi
		if grep -q '^fastestmirror' "$dnfConf";
		then
			log_Message "Fastestmirror already set"
		elif printf 'fastestmirror=True\n' | sudo tee -a "$dnfConf" > /dev/null;
		then
			log_Message "Set fastestmirror"
		else
			log_Message "Unable to set fastestmirror" "WARN"
		fi
		log_Message "Completed altering dnf.conf"
	else
		log_Message "Unable to locate dnf.conf at $dnfConf" "WARN"
	fi

	log_Message "Checking EPEL repository"
	if /usr/bin/rpm -q epel-release &>/dev/null;
	then
		log_Message "EPEL already enabled"
	else
		local rhelMajor="$(/usr/bin/rpm -E %rhel)"
		log_Message "Installing EPEL repository for EL${rhelMajor}"
		if sudo /usr/bin/dnf install --nogpgcheck -y "https://dl.fedoraproject.org/pub/epel/epel-release-latest-${rhelMajor}.noarch.rpm";
		then
			log_Message "Completed installing EPEL repository"
		else
			log_Message "Unable to install EPEL repository" "WARN"
		fi
	fi

	log_Message "Checking CRB repository"
	if /usr/bin/dnf repolist enabled 2>/dev/null | grep -qi 'crb\|codeready';
	then
		log_Message "CRB already enabled"
	elif [[ -x '/usr/bin/crb' ]];
	then
		log_Message "Enabling CRB via crb"
		if sudo /usr/bin/crb enable;
		then
			log_Message "Completed enabling CRB"
		else
			log_Message "Unable to enable CRB" "WARN"
		fi
	elif [[ -x '/usr/sbin/subscription-manager' ]];
	then
		log_Message "Enabling CRB via subscription-manager"
		if sudo /usr/sbin/subscription-manager repos --enable "codeready-builder-for-rhel-$(/usr/bin/rpm -E %rhel)-$(/usr/bin/uname -m)-rpms";
		then
			log_Message "Completed enabling CRB"
		else
			log_Message "Unable to enable CRB" "WARN"
		fi
	else
		log_Message "Unable to locate crb or subscription-manager to enable CRB" "WARN"
	fi

	log_Message "Checking RPM Fusion repositories"
	if /usr/bin/rpm -q rpmfusion-free-release &>/dev/null && /usr/bin/rpm -q rpmfusion-nonfree-release &>/dev/null;
	then
		log_Message "RPM Fusion already enabled"
	else
		local rhelMajor="$(/usr/bin/rpm -E %rhel)"
		log_Message "Installing RPM Fusion (free + nonfree) for EL${rhelMajor}"
		if sudo /usr/bin/dnf install --nogpgcheck -y \
			"https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-${rhelMajor}.noarch.rpm" \
			"https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-${rhelMajor}.noarch.rpm";
		then
			log_Message "Completed installing RPM Fusion"
		else
			log_Message "Unable to install RPM Fusion" "WARN"
		fi
	fi
}

# Install packages from rhelInstallArray that are not currently installed
function rhel_PackageInstall() {
	log_Message "Beginning package install with dnf"
	for packageInstall in "${rhelInstallArray[@]}";
	do
		if ! /usr/bin/rpm -q "$packageInstall" &> /dev/null;
		then
			log_Message "Installing $packageInstall"
			sudo /usr/bin/dnf install -y "$packageInstall"
		else
			log_Message "Skipping $packageInstall, already installed"
		fi
	done
	log_Message "Completed installing packages with dnf"
}

# Build and install Alacritty from source
function rhel_AlacrittySrcInstall() {
	log_Message "Beginning Alacritty source build"
	if command -v alacritty &>/dev/null;
	then
		log_Message "Alacritty already installed"
		return 0
	fi

	local buildDir="$userDir/Github/alacritty"
	if [[ -d "$buildDir" ]];
	then
		log_Message "Alacritty repo already cloned"
	else
		log_Message "Cloning Alacritty repository"
		if ! git clone https://github.com/alacritty/alacritty.git "$buildDir";
		then
			log_Message "Unable to clone Alacritty repository" "WARN"
			return 1
		fi
	fi

	log_Message "Installing Development Tools group"
	if ! sudo /usr/bin/dnf groupinstall -y "Development Tools";
	then
		log_Message "Unable to install Development Tools" "WARN"
		return 1
	fi

	log_Message "Building Alacritty"
	if ! cargo build --release --manifest-path "$buildDir/Cargo.toml";
	then
		log_Message "Unable to build Alacritty" "WARN"
		return 1
	fi

	log_Message "Installing Alacritty binary"
	if sudo cp "$buildDir/target/release/alacritty" /usr/local/bin/;
	then
		log_Message "Copied alacritty to /usr/local/bin"
	else
		log_Message "Unable to copy alacritty to /usr/local/bin" "WARN"
		return 1
	fi

	log_Message "Installing Alacritty desktop entry"
	if [[ -f "$buildDir/extra/logo/alacritty-term.svg" ]];
	then
		sudo cp "$buildDir/extra/logo/alacritty-term.svg" /usr/share/pixmaps/Alacritty.svg
	fi
	if [[ -f "$buildDir/extra/linux/Alacritty.desktop" ]];
	then
		sudo desktop-file-install "$buildDir/extra/linux/Alacritty.desktop"
		sudo update-desktop-database
		log_Message "Installed desktop entry"
	else
		log_Message "Unable to locate desktop entry file" "WARN"
	fi

	log_Message "Installing Alacritty terminfo"
	if ! infocmp alacritty &>/dev/null;
	then
		if [[ -f "$buildDir/extra/alacritty.info" ]];
		then
			sudo tic -xe alacritty,alacritty-direct "$buildDir/extra/alacritty.info"
			log_Message "Installed terminfo"
		else
			log_Message "Unable to locate terminfo file" "WARN"
		fi
	else
		log_Message "Terminfo already installed"
	fi

	log_Message "Completed Alacritty source build"
}

# Install flatpaks from flatpakInstallArray, including Rustdesk
function flatpak_Install() {
	log_Message "Beginning install with flatpak"
	flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
	for flatpak in "${flatpakInstallArray[@]}";
	do
		if flatpak list --app --columns=application | grep -q "$flatpak";
		then
			log_Message "Skipping $flatpak, already installed"
		else
			log_Message "Installing $flatpak"
			flatpak install --user -y flathub "$flatpak"
		fi
	done
	log_Message "Completed installing packages with flatpak"
}

# Setup bashrc/zshrc with alias and editor
function configrc_Setup() {
	log_Message "Adding entries to $1"
	if [[ -f "$userDir/.$1" ]];
	then
		grep -q "alias ll='ls -l --color=auto'" "$userDir/.$1" || printf "alias ll='ls -l --color=auto'\n" >> "$userDir/.$1"
		grep -q "alias lla='ls -la --color=auto'" "$userDir/.$1" || printf "alias lla='ls -la --color=auto'\n" >> "$userDir/.$1"
		grep -q "alias scripts='cd ~/Github && ll'" "$userDir/.$1" || printf "alias scripts='cd ~/Github && ll'\n" >> "$userDir/.$1"
		grep -q "export EDITOR=/usr/bin/nvim" "$userDir/.$1" || printf "export EDITOR=/usr/bin/nvim\n" >> "$userDir/.$1"
		grep -q "export TERMINAL=/usr/local/bin/alacritty" "$userDir/.$1" || printf "export TERMINAL=/usr/local/bin/alacritty\n" >> "$userDir/.$1"
	else
		log_Message "Unable to locate $1" "WARN"
	fi
	source "$userDir/.$1"
	log_Message "Completed adding entries to $1"
}

# Check for valid icon file, AppleScript dialog boxes will error without it
function check_Icon() {
	if [[ -f "$genericIconPath" ]];
	then
		log_Message "Generic icon found"
		activeIcon="$genericIconPath"
		return 0
	else
		log_Message "Generic icon not found" "ERROR"
		return 1
	fi
}

# AppleScript - Create alert dialog window
function alert_Dialog() {
	local promptString="$1"
	log_Message "Displaying alert dialog"
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
			log_Message "Unable to show alert dialog" "WARN"
			;;
		'Timeout')
			log_Message "Alert timed out" "WARN"
			;;
		*)
			log_Message "Continued through alert dialog"
			;;
	esac
}

# AppleScript - Text field dialog prompt for inputting information
function textField_Dialog() {
	local promptString="$1"
	local count=1
	log_Message "Displaying text field dialog"
	while [[ $count -le 10 ]];
	do
		textFieldDialog=$(/usr/bin/osascript <<OOP
		try
			set promptString to "$promptString"
			set iconPath to "$activeIcon"
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
				log_Message "No response, re-prompting ($count/10)" "WARN"
				((count++))
				;;
			'')
				log_Message "Nothing entered in text field"
				alert_Dialog "Please enter something"
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
	log_Message "Displaying binary dialog"
	while [[ $count -le 10 ]];
	do
		binDialog=$(/usr/bin/osascript <<OOP
		try
			set promptString to "$promptString"
			set iconPath to "$activeIcon"
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
				log_Message "No response, re-prompting ($count/10)" "WARN"
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
	log_Message "Beginning Homebrew installation"
	if ! command -v brew &> /dev/null;
	then
		log_Message "Installing Homebrew"
		if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)";
		then
			log_Message "Completed Homebrew install"
		else
			log_Message "Unable to complete Homebrew install" "WARN"
		fi
	else
		log_Message "Skipping Homebrew, already installed"
	fi
	if [[ "$deviceArch" == 'arm64' ]];
	then
		log_Message "Setting up Homebrew shell env"
		grep -q 'brew shellenv' "$userDir/.zprofile" 2>/dev/null || printf 'eval "$(/opt/homebrew/bin/brew shellenv)"\n' >> "$userDir/.zprofile"
		eval "$(/opt/homebrew/bin/brew shellenv)"
		log_Message "Completed Homebrew shell env setup"
		log_Message "Installing Rosetta"
		if /usr/sbin/softwareupdate --install-rosetta --agree-to-license;
		then
			log_Message "Completed Rosetta install"
		else
			log_Message "Unable to complete Rosetta install" "WARN"
		fi
	fi
	if command -v brew &>/dev/null;
	then
		log_Message "Beginning package install using Homebrew"
		for brewInstall in "${macOSInstallArray[@]}";
		do
			if brew list "$brewInstall" &>/dev/null;
			then
				log_Message "Skipping $brewInstall, already installed"
			else
				log_Message "Installing $brewInstall"
				brew install "$brewInstall"
			fi
		done
		log_Message "Promping to download additional cask applications"
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
			log_Message "No additional applications installed"
		fi
		log_Message "Completed Homebrew installation"
	else
		log_Message "Homebrew still not installed" "WARN"
	fi
}

# Setup macOS zsh plugins and theme
function macOS_Shell() {
	if [[ -d "$userDir/.oh-my-zsh" ]];
	then
		log_Message "oh-my-zsh already installed"
	else
		log_Message "Installing oh-my-zsh"
		if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended;
		then
			log_Message "Completed oh-my-zsh install"
		else
			log_Message "Unable to complete oh-my-zsh install" "WARN"
		fi
	fi
	if [[ -d "$userDir/.oh-my-zsh/themes/powerlevel10k" ]];
	then
		log_Message "powerlevel10k theme already installed"
	else
		log_Message "Installing powerlevel10k theme"
		if git clone https://github.com/romkatv/powerlevel10k.git "$userDir/.oh-my-zsh/themes/powerlevel10k";
		then
			log_Message "Completed powerlevel10k theme install"
		else
			log_Message "Unable to complete powerlevel10k theme install" "WARN"
		fi
	fi
	if [[ -d "$userDir/.oh-my-zsh/plugins/zsh-autosuggestions" ]];
	then
		log_Message "zsh-autosuggestions plugin already installed"
	else
		log_Message "Installing zsh-autosuggestions plugin"
		if git clone https://github.com/zsh-users/zsh-autosuggestions "$userDir/.oh-my-zsh/plugins/zsh-autosuggestions";
		then
			log_Message "Completed zsh-autosuggestions plugin install"
		else
			log_Message "Unable to complete zsh-autosuggestions plugin install" "WARN"
		fi
	fi
	if [[ -d "$userDir/.oh-my-zsh/plugins/zsh-syntax-highlighting" ]];
	then
		log_Message "zsh-syntax-highlighting plugin already installed"
	else
		log_Message "Installing zsh-syntax-highlighting plugin"
		if git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$userDir/.oh-my-zsh/plugins/zsh-syntax-highlighting";
		then
			log_Message "Completed zsh-syntax-highlighting plugin install"
		else
			log_Message "Unable to complete zsh-syntax-highlighting plugin install" "WARN"
		fi
	fi
	log_Message "Setting zsh theme and plugins"
	sed -i '' -e 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$userDir/.zshrc"
	sed -i '' -e 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting web-search)/' "$userDir/.zshrc"
	log_Message "Completed zsh configuration"
}

# Setup macOS dock to remove default apps and change orientation, then change menu bar spacing
function macOS_DocknMenuBar() {
	log_Message "Checking Dock configuration"
	dockCheck=$(/usr/bin/defaults read "$userDir/Library/Preferences/com.apple.dock.plist" "persistent-apps" | grep 'file-label')
	dockCount=$(printf "$dockCheck" | grep -c 'file-label')
	if [[ ! "$dockCheck" == *"Alacritty"* ]];
	then
		log_Message "Backing up Dock plist and removing persistent applications"
		cp "$userDir/Library/Preferences/com.apple.dock.plist" "$userDir/Library/Preferences/com.apple.dock.OGbackup.plist"
		for i in $(/usr/bin/seq 3 $dockCount);
		do
			/usr/bin/plutil -remove 'persistent-apps.2' "$userDir/Library/Preferences/com.apple.dock.plist"
		done
		if [[ ! $(/usr/bin/plutil -lint "$userDir/Library/Preferences/com.apple.dock.plist") == *'OK'* ]];
		then
			log_Message "Reverting changes to Dock"
			mv "$userDir/Library/Preferences/com.apple.dock.plist" "$userDir/Library/Preferences/com.apple.dock.failed.plist"
			cp "$userDir/Library/Preferences/com.apple.dock.OGbackup.plist" "$userDir/Library/Preferences/com.apple.dock.plist"
		else
			log_Message "Orientating Dock to the left"
			/usr/bin/defaults write "$userDir/Library/Preferences/com.apple.dock.plist" "orientation" "left"
		fi
	fi
	/usr/bin/killall Dock
	log_Message "Completed Dock configuration"
	log_Message "Setting Menu Bar icon spacing"
	if /usr/bin/defaults -currentHost write -globalDomain NSStatusItemSpacing -int 10;
	then
		log_Message "Successfully set Menu Bar icon spacing"
		log_Message "Setting Menu Bar icon selection spacing"
		if /usr/bin/defaults -currentHost write -globalDomain NSStatusItemSelectionPadding -int 8;
		then
			log_Message "Successfully set Menu Bar icon selection spacing"
		else
			log_Message "Unable to set Menu Bar icon selection spacing" "WARN"
		fi
	else
		log_Message "Unable to set Menu Bar icon spacing" "WARN"
	fi
}

# If alacritty is present, attempt to open it, then open security settings for approval
function macOS_AlacrittySecurity() {
	log_Message "Attempting to open Alacritty to then allow it though Gatekeeper"
	if [[ -d "/Applications/Alacritty.app" ]];
	then
		log_Message "Opening Alacritty"
		/usr/bin/open /Applications/Alacritty.app &
		log_Message "Opening Privacy & Security Settings"
		if [[ $(sw_vers -productVersion) < 13.0 ]];
		then
			open "x-apple.systempreferences:com.apple.preference.security"
		else
			open "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension"
		fi
	else
		log_Message "Alacritty not installed, installing using Homebrew"
		brew install --cask alacritty
	fi
}

# Setup neovim configuration file and plugin
function neovim_Setup() {
	log_Message "Setting up Neovim"
	if [[ -f "$scriptDir/init.vim" ]];
	then
		if cmp -s "$scriptDir/init.vim" "$userDir/.config/nvim/init.vim";
		then
			log_Message "Neovim config already up to date"
		else
			log_Message "Copying Neovim config to ~/.config/nvim"
			cp "$scriptDir/init.vim" "$userDir/.config/nvim/init.vim"
		fi
	else
		log_Message "Unable to locate Neovim config" "WARN"
	fi
	if [[ -f "$userDir/.config/nvim/autoload/plug.vim" ]];
	then
		log_Message "vim-plug already installed"
	else
		log_Message "Installing vim-plug"
		if curl -fLo "$userDir/.config/nvim/autoload/plug.vim" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim;
		then
			log_Message "Completed vim-plug install"
		else
			log_Message "Unable to complete vim-plug install" "WARN"
		fi
	fi
	if command -v nvim &>/dev/null;
	then
		if nvim -c 'PlugInstall|q';
		then
			log_Message "Neovim plugins installed"
		else
			log_Message "Unable to install Neovim plugins, install plugins manually" "WARN"
			log_Message ":PlugInstall"
		fi
		
		if nvim -c 'CocInstall -sync coc-sh coc-clangd coc-sourcekit|q';
		then
			log_Message "Neovim extensions installed"
		else
			log_Message "Unable to install Neovim extensions, add extensions manually" "WARN"
			log_Message ":CocInstall coc-sh coc-clangd coc-sourcekit"
		fi
	else
		log_Message "Unable to locate nvim, add nvim plugins and extensions manually" "WARN"
		log_Message ":PlugInstall"
		log_Message ":CocInstall coc-sh coc-clangd coc-sourcekit"
	fi
	log_Message "Completed Neovim setup"
}

# Setup alacritty configuration file
function alacritty_Setup() {
	log_Message "Setting up Alacritty"
	if [[ "$osCheck" == 'macOS' ]];
	then
		local fontPath="$userDir/Library/Fonts/Meslo/"
		local fontZIPPath="$userDir/Library/Fonts/Meslo.zip"
	else
		local fontPath="$userDir/.local/share/fonts/Meslo/"
		local fontZIPPath="$userDir/.local/share/fonts/Meslo.zip"
	fi
	if [[ -d "$fontPath" ]] && ls "$fontPath"/*.ttf &>/dev/null;
	then
		log_Message "MesloLGL Nerd Font Mono already installed"
	elif curl -fLo "$fontZIPPath" --create-dirs https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip;
	then
		log_Message "Installing MesloLGL Nerd Font Mono"
		unzip -o "$fontZIPPath" -d "$fontPath"
	else
		log_Message "Unable to locate MesloLGL Nerd Font Mono" "WARN"
	fi
	if [[ -d "$userDir/.config/alacritty/alacritty-master" ]];
	then
		log_Message "Alacritty Dracula theme already installed"
	elif curl -fLo "$userDir/.config/alacritty/master.zip" https://github.com/dracula/alacritty/archive/master.zip;
	then
		log_Message "Installing Alacritty Dracula theme"
		unzip -o "$userDir/.config/alacritty/master.zip" -d "$userDir/.config/alacritty/"
	else
		log_Message "Unable to locate Alacritty Dracula theme" "WARN"
	fi
	if [[ -f "$scriptDir/alacritty.toml" ]];
	then
		if cmp -s "$scriptDir/alacritty.toml" "$userDir/.config/alacritty/alacritty.toml";
		then
			log_Message "alacritty.toml already up to date"
		else
			log_Message "Copying alacritty.toml to config folder"
			cp "$scriptDir/alacritty.toml" "$userDir/.config/alacritty/"
		fi
	else
		log_Message "Unable to copy alacritty.toml to config folder" "WARN"
	fi
	log_Message "Completed Alacritty setup"
}

function main() {
    if command -v /usr/bin/caffeinate &>/dev/null;
    then
        /usr/bin/caffeinate -d &
        caffeinatePID=$!
        trap "kill $caffeinatePID" EXIT INT TERM HUP
    fi

    if [[ -w "$logFile" ]];
    then
        printf "Log: $(date "+%F %T") Beginning Device Setup script\n" | tee "$logFile"
    else
        printf "Log: $(date "+%F %T") Beginning Device Setup script\n"
    fi

	if ! check_OS;
	then
		log_Message "Unable to determine OS" "ERROR"
		exit 1
	fi

	create_GeneralFolders

	case "$osCheck" in
		'arch')
			grep -q 'XDG_DATA_DIR' /etc/environment 2>/dev/null || printf "XDG_DATA_DIR=\"/usr/local/share:/usr/share\"\n" | sudo tee -a /etc/environment
			if [[ ! -f "$userDir/.bashrc" ]];
			then
				/usr/bin/touch "$userDir/.bashrc"
			fi
			arch_ConfigFiles
			arch_PackageInstall
			flatpak_Install
			configrc_Setup "bashrc"
			neovim_Setup
			alacritty_Setup
			if tuned-adm --version &>/dev/null;
			then
				log_Message "Checking device type to set tuned-adm profile"
				sudo /usr/bin/systemctl enable tuned --now
				log_Message "Device type:"
				deviceChassis="$(/usr/bin/hostnamectl chassis 2>/dev/null)"
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
						log_Message "Unable to set tuned-adm profile" "WARN"
						;;
				esac
				log_Message "Completed setting tuned-adm profile"
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
		'rhel')
			if [[ ! -f "$userDir/.bashrc" ]];
			then
				/usr/bin/touch "$userDir/.bashrc"
			fi
			rhel_ConfigFiles
			rhel_PackageInstall
            rhel_AlacrittySrcInstall
			configrc_Setup "bashrc"
			neovim_Setup
			alacritty_Setup
			;;
		'macOS')
			if ! check_Icon;
			then
				alert_Dialog "Missing required icon file!"
				log_Message "Exiting for no icon" "ERROR"
				exit 1
			fi
			if [[ ! -f "$userDir/.zshrc" ]];
			then
				/usr/bin/touch "$userDir/.zshrc"
			fi
			log_Message "Prompting to name the device"
			if ! textField_Dialog "Please enter your desired device name:";
			then
				log_Message "Device not renamed" "WARN"
			else
				/usr/sbin/scutil --set ComputerName "$textFieldDialog"
				/usr/sbin/scutil --set LocalHostName "$textFieldDialog"
				/usr/sbin/scutil --set HostName "$textFieldDialog"
				log_Message "Device renamed: $textFieldDialog"
			fi
			macOS_HomebrewInstall
			macOS_Shell
			macOS_DocknMenuBar
			configrc_Setup "zshrc"
			neovim_Setup
			alacritty_Setup
			macOS_AlacrittySecurity
			;;
		*)
			log_Message "Unable to determine OS" "ERROR"
			exit 1
			;;
	esac
	log_Message "Setting Github email and name"
	if git --version &>/dev/null;
	then
        if git config --global user.email "129307974+archzaq@users.noreply.github.com";
		then
			log_Message "Set Github email"
		else
			log_Message "Unable to set Github email" "WARN"
		fi
		if git config --global user.name "archzaq";
		then
			log_Message "Set Github user name"
		else
			log_Message "Unable to set Github user name" "WARN"
		fi
        if git config --global gpg.format ssh;
        then
            log_Message "Set Github signing to SSH"
        else
            log_Message "Unable to set Github signing to SSH" "WARN"
        fi
        if git config --global user.signingkey ~/.ssh/id_ed25519.pub;
        then
            log_Message "Set Github signing key"
        else
            log_Message "Unable to set Github signing key" "WARN"
        fi
	else
		log_Message "Unable to locate Git command" "WARN"
	fi
    log_Message "Create an SSH key with ssh-keygen -t ed25519 -C 'name'"
    log_Message "Add the key to your keychain with ssh-add ~/.ssh/id_ed25519"
    log_Message "Add public SSH key to Github signing"
    log_Message "Clone repo with git clone git@github.com:repo/repo.git"
	log_Message "Exiting!"
	exit 0
}

main

