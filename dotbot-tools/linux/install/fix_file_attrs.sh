#!/usr/bin/env bash

# Setup dotfiles.

set -e

if [ -z "$DOTFILES_DIR" ]; then
    echo "DOTFILES_DIR is not set." >&2
    exit 1
fi

bash_args=
if [ -n "$TRACE" ]; then
    bash_args=" -x"
fi

find "$DOTFILES_DIR" -type f ! -path './.git/*' -path '*.sh' -exec bash -c$bash_args 'chmod +x "{}"' \;
find "$DOTFILES_DIR/bin/linux" -type f -exec bash -c$bash_args 'chmod +x "{}"' \;
