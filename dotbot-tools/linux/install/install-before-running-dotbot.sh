#!/usr/bin/env bash

# Setup dotfiles.

set -e

if [ "$(id -u)" -eq 0 ]; then
    echo "This script should not be run as root." >&2
    exit 1
fi

script_name="$(basename -- "${BASH_SOURCE[0]}")"
log_context="${script_name%.*}"

log() {
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[${timestamp}] [${log_context}]: ${1}"
}

apt_get_update() {
    if [ -z "$(ls -A /var/lib/apt/lists)" ]; then
        if command -v sudo &>/dev/null; then
            log "Updating apt lists with sudo..."
            sudo apt-get update
        else
            log "Updating apt lists without sudo..."
            apt-get update
        fi

        log "Updated apt lists."
    fi
}

apt_remove_lists() {
    sudo rm -rf /var/lib/apt/lists/*
}

apt_install() {
    package="${1}"
    command="${2:-$1}"
    if command -v "$command" &>/dev/null; then
        log "Package $package is already installed."
    else
        apt_get_update
        log "Installing $package..."
        sudo apt-get install -y "$1" --no-install-recommends
        log "Installed $package."
    fi
}

main() {
    log "Installing dotbot prerequisites..."

    apt_remove_lists
    apt_install sudo
    apt_install git-all git

    log "Installed dotbot prerequisites."
}

main
