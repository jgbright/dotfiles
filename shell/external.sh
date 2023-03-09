# # pip should only run if there is a virtualenv currently activated
# export PIP_REQUIRE_VIRTUALENV=true

# # Cache pip-installed packages to avoid re-downloading
# export PIP_DOWNLOAD_CACHE=$HOME/.pip/cache

# # Python startup file
# export PYTHONSTARTUP=$HOME/.pythonrc

# # Vagrant
# export VAGRANT_DISABLE_VBOXSYMLINKCREATE=1

# # Docker
# export DOCKER_SCAN_SUGGEST=false

export DOTFILES_DIR="$HOME/.dotfiles"

export MANPAGER="sh -c 'col -bx | bat -l man -p'"

export POSH_THEMES_PATH="$HOME/.poshthemes"
