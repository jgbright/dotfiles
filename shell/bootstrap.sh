path_prepend "$HOME/.local/bin-xplat"
path_prepend "$HOME/.local/bin"
path_prepend "$HOME/.dotfiles/bin"

pwsh "$HOME/.dotfiles/bin-xplat/configure-git.ps1"
