#!/usr/bin/env bash

############################
###  Author:  Zac Reeves ###
###  Created: 05-20-26   ###
###  Updated: 05-20-26   ###
###  Version: 1.0        ###
############################

set -Eeuo pipefail

readonly scriptDir="$(cd -- "$(dirname -- "$0")" && pwd -P)"
readonly playbookDir="$scriptDir/ansible"
readonly runID="$(date +%Y%m%d-%H%M%S)"

logFile="$HOME/Desktop/device_Setup.log"
extraArgs=()
caffeinatePID=""

usage() {
    cat <<EOF
Usage:
  bash $(basename "$0") [options] [-- <ansible-playbook args>]

Options:
  --logfile <path>      Ansible log path (default: $logFile).
  -h, --help            Show this message.

Anything after a literal "--" is forwarded to ansible-playbook, so
--check, --diff, --tags, --skip-tags, --start-at-task etc. all work:

  bash $(basename "$0") -- --check --diff
  bash $(basename "$0") -- --tags shell,neovim
  bash $(basename "$0") -- --skip-tags gnome
EOF
}

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

detect_os() {
    if [[ -f /usr/bin/pacman ]];
    then
        echo arch
    elif [[ -f /etc/fedora-release ]];
    then
        echo fedora
    elif [[ -f /usr/bin/dnf ]];
    then
        echo rhel
    elif [[ "$(uname -s)" == "Darwin" ]];
    then
        echo macos
    else
        echo unknown
    fi
}

ensure_brew_macos() {
    if command -v brew &>/dev/null;
    then
        return 0
    fi
    log_Message "Installing Homebrew"
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [[ -x /opt/homebrew/bin/brew ]];
    then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
}

ensure_ansible() {
    if command -v ansible-playbook &>/dev/null;
    then
        return 0
    fi
    local os="$1"
    log_Message "Installing ansible-core for $os"
    case "$os" in
        arch)
            sudo pacman -Syyy --noconfirm
            sudo pacman -S --needed --noconfirm ansible
            ;;
        rhel|fedora)
            sudo dnf install -y ansible-core
            ;;
        macos)
            ensure_brew_macos
            brew install ansible
            ;;
        *)
            log_Message "Unsupported OS" "ERROR"
            exit 1
            ;;
    esac
}

install_collections() {
    if [[ -f "$playbookDir/requirements.yml" ]];
    then
        log_Message "Installing required Ansible collections"
        ansible-galaxy collection install --force -r "$playbookDir/requirements.yml" >/dev/null
    fi
}

parse_args() {
    while [[ $# -gt 0 ]];
    do
        case "$1" in
            --logfile)
                shift
                [[ $# -gt 0 ]] || { printf "ERROR: --logfile requires a value\n" >&2; exit 1; }
                logFile="$1"
                ;;
            -h|--help) usage; exit 0 ;;
            --) shift; extraArgs+=("$@"); break ;;
            *)
                printf "ERROR: unknown argument: %s\n" "$1" >&2
                usage
                exit 1
                ;;
        esac
        shift
    done
}

main() {
    parse_args "$@"

    if [[ $EUID -eq 0 ]];
    then
        log_Message "Do not run as root — run as your normal user. Ansible will sudo as needed." "ERROR"
        exit 1
    fi

    local os
    os="$(detect_os)"
    if [[ "$os" == "unknown" ]];
    then
        log_Message "Unable to detect OS" "ERROR"
        exit 1
    fi
    log_Message "Detected OS: $os"

    ensure_ansible "$os"
    install_collections

    mkdir -p "$(dirname "$logFile")" 2>/dev/null || true

    if command -v caffeinate &>/dev/null;
    then
        caffeinate -d -i -s &
        caffeinatePID=$!
        trap '[[ -n "${caffeinatePID:-}" ]] && kill "$caffeinatePID" 2>/dev/null || true' EXIT INT TERM HUP
    fi

    local -a runner=()
    if [[ "$os" != "macos" ]] && command -v systemd-inhibit &>/dev/null;
    then
        runner=(
            systemd-inhibit
            --what=idle:sleep:handle-lid-switch
            --who=device_setup
            --why=provisioning
            --mode=block
            --
        )
    fi

    printf "========================================\n"
    printf "Device Setup\n"
    printf "run_id=%s\n" "$runID"
    printf "os=%s\n" "$os"
    printf "playbook=%s/site.yml\n" "$playbookDir"
    printf "logfile=%s\n" "$logFile"
    printf "========================================\n"

    export ANSIBLE_CONFIG="$playbookDir/ansible.cfg"
    export ANSIBLE_LOG_PATH="$logFile"

    local -a cmd=(
        ansible-playbook
        -i "$playbookDir/inventory"
        "$playbookDir/site.yml"
        --ask-become-pass
    )
    if [[ ${#extraArgs[@]} -gt 0 ]];
    then
        cmd+=( "${extraArgs[@]}" )
    fi

    if [[ ${#runner[@]} -gt 0 ]];
    then
        "${runner[@]}" "${cmd[@]}"
    else
        "${cmd[@]}"
    fi
}

main "$@"
