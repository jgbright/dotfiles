path_append "$HOME/.dotfiles/bin"
path_prepend "$HOME/.local/bin-linux"
path_prepend "$HOME/.local/bin"

eval "${DOTFILES_DIR}/dotbot-tools/bootstrap-shell-xplat.ps1"
