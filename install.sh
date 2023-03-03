#!/usr/bin/env bash

# Install dotfiles from this script's directory.  Make sure this is where you
# want the dotfiles to be installed.  Symlinks will be created to the files 
# in this directory.

set -e

CONFIG=".install.linux.conf.yaml"
DOTBOT_DIR=".dotbot"

DOTBOT_BIN="bin/dotbot"
BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "${BASEDIR}"

"$BASEDIR/dotbot-tools/linux/install/install-before-running-dotbot.sh"

git -C "${DOTBOT_DIR}" submodule sync --quiet --recursive
git submodule update --init --recursive "${DOTBOT_DIR}"

bash "${BASEDIR}/dotbot-tools/linux/install/fix_file_attrs.sh"

"${BASEDIR}/${DOTBOT_DIR}/${DOTBOT_BIN}" \
    -d "${BASEDIR}" \
    -c "${CONFIG}" \
    --plugin-dir "${BASEDIR}/dotbot-conditional" \
    --plugin-dir "${BASEDIR}/dotbot-crossplatform" \
    "${@}"
