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
export REAL_DOTFILES_DIR="$(dirname "$(realpath "$0")")"
export REAL_DOTFILES_DIR2="$( cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P )"

# get script path
# https://stackoverflow.com/a/246128/1123955
# https://stackoverflow.com/a/4774063/1123955
# https://stackoverflow.com/a/4774063/1123955




export MANPAGER="sh -c 'col -bx | bat -l man -p'"
