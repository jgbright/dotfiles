#!/usr/bin/env bash

# Setup dotfiles.

set -e

if [ -z "$DOTFILES_DIR" ]; then
    echo "DOTFILES_DIR is not set." >&2
    exit 1
fi

find "$DOTFILES_DIR" \
    -type f \
    ! -path './.git/*' \
    \( -path '*.sh' -or -path '*.ps1' \) \
    ! -path '*/.dotbot/*' \
    -exec bash -c 'echo "chmod +x $1" && chmod +x "$1"' shell {} \;
