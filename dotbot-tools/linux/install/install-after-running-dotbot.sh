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

cleanup() {
    log "Cleaning up..."
    apt_remove_lists
    log "Cleaned up."
}

apt_install() {
    package="${1}"
    command="${2:-$1}"
    if command -v "$command" &>/dev/null; then
        log "Package $package is already installed."
        return
    fi

    apt_get_update

    log "Installing $package..."
    sudo apt-get install -y "$1" --no-install-recommends
    log "Installed $package."
}

install_ohmyzsh() {
    if [ -d "${HOME}/.oh-my-zsh" ]; then
        log "Oh My Zsh already installed."
        return
    fi

    log "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    log "Installed Oh My Zsh."
}

install_ohmyposh() {
    if [ -d "${HOME}/.oh-my-zsh" ]; then
        log "Oh My Zsh already installed."
        return
    fi

    log "Installing Oh My Posh..."

    sudo curl -L https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 -o /usr/local/bin/oh-my-posh
    sudo chmod +x /usr/local/bin/oh-my-posh

    log "Installed Oh My Posh."
}

install_az() {
    if command -v az &>/dev/null; then
        log "Azure CLI already installed."
        return
    fi

    log "Installing Azure CLI..."
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    log "Installed Azure CLI."
}

install_pwsh() {
    if command -v pwsh &>/dev/null; then
        log "Powershell already installed."
        return
    fi

    log "Installing pwsh..."

    # https://learn.microsoft.com/en-us/powershell/scripting/install/install-ubuntu?view=powershell-7.3
    apt_get_update
    sudo apt-get install -y wget apt-transport-https software-properties-common
    wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb"
    sudo dpkg -i packages-microsoft-prod.deb
    sudo apt-get update
    sudo apt-get install -y powershell

    log "Installed pwsh."
}

install_dotnet_sdk_6() {
    if dotnet --list-sdks | grep -E '^6.0.'; then
        log "dotnet-sdk-6.0 already installed."
        return
    fi

    log "Installing dotnet-sdk-6.0..."

    apt_get_update
    sudo apt-get install -y dotnet-sdk-6.0
    log "Installed dotnet-sdk-6.0."
}

install_dotnet_sdk_7() {
    if dotnet --list-sdks | grep -E '^7.0.'; then
        log "dotnet-sdk-7.0 already installed."
        return
    fi

    log "Installing dotnet-sdk-7.0..."

    apt_get_update
    sudo apt-get install -y dotnet-sdk-7.0
    log "Installed dotnet-sdk-7.0."
}

install_dotnet_suggest() {
    if dotnet tool list --global | grep -E '^dotnet-suggest\W+'; then
        log "dotnet-suggest already installed."
        return
    fi

    dotnet tool install --global dotnet-suggest --version 1.1.327201
}

install_lazygit() {
    if command -v lazygit &>/dev/null; then
        log "Lazygit already installed."
        return
    fi

    log "Installing lazygit..."

    temp_dir="$(mktemp --tmpdir --directory lazygit-XXX)"
    pushd "$temp_dir"
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
    popd

    rm -rf "$temp_dir"

    log "Installed lazygit."
}

install_lazydocker() {
    if command -v lazydocker &>/dev/null; then
        log "Lazydocker already installed."
        return
    fi

    log "Installing lazydocker..."
    curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | DIR=/usr/bin bash
    log "Installed lazydocker."
}

install_dive() {
    if command -v dive &>/dev/null; then
        log "Dive already installed."
        return
    fi

    log "Installing dive..."

    temp_file="$(mktemp --tmpdir dive-XXX.deb)"
    curl -Lo "$temp_file" https://github.com/wagoodman/dive/releases/download/v0.9.2/dive_0.9.2_linux_amd64.deb
    sudo apt install "$temp_file"
    rm -f "$temp_file"

    log "Installed dive."
}

install_k9s() {
    if command -v k9s &>/dev/null; then
        log "K9s already installed."
        return
    fi
    log "Installing k9s..."

    curl -sS https://webinstall.dev/k9s | bash

    log "Installed k9s."
}

install_zsh_plugin() {
    repo_url="$1"
    name="${2:-$(basename "$repo_url")}"
    target_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$name"
    if [ -d "$target_dir" ]; then
        log "Zsh $name already installed."
        return
    fi
    log "Installing zsh $name..."

    git clone "$repo_url" "$target_dir"

    log "Installed zsh $name."
}

install_1password_cli() {
    if command -v op &>/dev/null; then
        log "1Password already installed."
        return
    fi
    log "Adding the key for the 1Password Apt repository..."
    curl -sS https://downloads.1password.com/linux/keys/1password.asc |
        sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
    log "Added the key for the 1Password Apt repository."

    log "Adding the 1Password Apt repository..."
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" |
        sudo tee /etc/apt/sources.list.d/1password.list
    log "Added the 1Password Apt repository."

    log "Adding the debsig-verify policy..."
    sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
    curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol |
        sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol
    sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
    curl -sS https://downloads.1password.com/linux/keys/1password.asc |
        sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
    log "Added the debsig-verify policy."

    log "Installing 1password-cli..."
    sudo apt update && sudo apt install 1password-cli
    log "Installed 1password-cli."
}

install_bat() {
    if command -v bat &>/dev/null; then
        log "Bat already installed."
    else
        package=$(mktemp bat-musl_0.22.1_amd64XXX.deb)
        curl -Lo "$package" "https://github.com/sharkdp/bat/releases/download/v0.22.1/bat-musl_0.22.1_amd64.deb"
        sudo dpkg -i "$package"
        rm -rf "$package"
    fi
}

install_fzf() {
    if command -v fzf &>/dev/null; then
        log "Fzf already installed."
    else
        log "Installing fzf..."

        package=$(mktemp -d)
        git clone --depth 1 https://github.com/junegunn/fzf "$package"

        # install docs: https://github.com/junegunn/fzf/blob/master/install#L16-L29
        "$package/install" \
            --all \
            --key-bindings \
            --completion \
            --update-rc

        rm -rf "$package"

        log "Installed fzf."
    fi
}

install_rustup() {
    if command -v rustup &>/dev/null; then
        log "Rust already installed."
        return
    fi

    log "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    log "Installed Rust."
}

install_exa() {
    if command -v exa &>/dev/null; then
        log "Exa already installed."
        return
    fi

    install_rustup

    log "Installing exa..."

    temp_file=$(mktemp --tmpdir exa-XXX.zip)
    EXA_VERSION=$(curl -s "https://api.github.com/repos/ogham/exa/releases/latest" | grep -Po '"tag_name": "v\K[0-9.]+')
    curl -Lo "$temp_file" "https://github.com/ogham/exa/releases/latest/download/exa-linux-x86_64-v${EXA_VERSION}.zip"
    sudo unzip -q "$temp_file" bin/exa -d /usr/local
    rm -f "$temp_file"

    log "Installed exa."
}

main() {
    log "Installing apps..."

    apt_install unzip
    apt_install zsh
    apt_install xdg-utils xdg-open
    apt_install mc
    apt_install zoxide

    # curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash

    install_ohmyzsh
    install_ohmyposh
    install_pwsh
    install_dotnet_sdk_6
    install_dotnet_sdk_7
    install_dotnet_suggest
    install_az
    install_lazygit
    install_lazydocker
    install_dive
    install_k9s
    install_1password_cli
    install_rustup
    install_exa
    install_bat
    # install_fzf

    install_zsh_plugin https://github.com/zsh-users/zsh-autosuggestions
    install_zsh_plugin https://github.com/zsh-users/zsh-syntax-highlighting
    install_zsh_plugin https://github.com/agkozak/zsh-z
    install_zsh_plugin https://github.com/ptavares/zsh-exa
    install_zsh_plugin https://github.com/unixorn/fzf-zsh-plugin

    cleanup

    log "Installed apps."
}

main
