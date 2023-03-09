#!/usr/bin/env bash

# Install dotfiles for the current user with symlinks to files in this directory.

set -e

git clone git@github.com:jgbright/dotfiles.git ~/.dotfiles
~/.dotfiles/install
