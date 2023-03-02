#!/usr/bin/env bash

Set-StrictMode -Version 3.0

if (!$env:DOTFILES_DIR) {
    Write-Error "DOTFILES_DIR is not set."
    exit 1
}

if (Test-Path "$env:DOTFILES_DIR\.git\MERGE_HEAD") {
    Write-Error "Merge conflict detected. Resolve the conflict and run this script again."
    # git rebase -C "$DOTFILES_DIR" --abort
    exit 1
}

Push-Location $env:DOTFILES_DIR

git add -A
git commit --message '-- wip --\n\n[nocicd]'
git pull --rebase
if (Test-Path "$env:DOTFILES_DIR\.git\MERGE_HEAD") {
    Write-Error "Merge conflict detected. Resolve the conflict and run this script again."
    # git rebase -C "$DOTFILES_DIR" --abort
    exit 1
}
git push
& "$env:DOTFILES_DIR\install.sh"
popd
