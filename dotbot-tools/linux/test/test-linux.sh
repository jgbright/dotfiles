#!/usr/bin/env bash

set -ex

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dockerfile="$script_dir/Dockerfile.test"

docker build --no-cache -f $dockerfile -t jgbright-dotfiles .

docker run -it --rm \
    -v $PWD:/workspace \
    -v $PWD:/home/jason/.dotfiles \
    --name ubuntu-dotfiles \
    -v ~/.ssh:/home/jason/.ssh \
    -t jgbright-dotfiles:latest
    # $(docker build -q -f $dockerfile .)
    # $(docker build -q -f $dockerfile .)
    # --user ubuntu \

# jgbright-dotfiles

# curl -s https://raw.githubusercontent.com/jgbright/dotfiles/main/install-remote.sh | bash