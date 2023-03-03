#!/usr/bin/env bash

Set-StrictMode -Version 3.0

<<<<<<< HEAD
if (!$env:DOTFILES_DIR) {
    Write-Error "DOTFILES_DIR is not set."
    exit 1
}

if (Test-Path "$env:DOTFILES_DIR\.git\MERGE_HEAD") {
=======
function Get-DotFilesDir {
    $DotFilesDirCandidates = @()

    if ($env:DOTFILES_DIR) {
        $DotFilesDirCandidates += $env:DOTFILES_DIR
    }

    # If this script was run from ~/.dotfiles/bin/windows/sync-dotfiles.ps1
    $DotFilesDirCandidates += [System.IO.Path]::GetFullPath("$PSScriptRoot\..\..\.dotfiles")

    # If this script was run from ~/.local/bin/sync-dotfiles.ps1
    $DotFilesDirCandidates += [System.IO.Path]::GetFullPath("$PSScriptRoot\..\..")

    $DotFilesDirCandidates += (Get-Location).Path

    $DotFilesDirCandidates | Where-Object { Test-Path "$_\.dotfile_dir" } | Select-Object -First 1
}

$DotFilesDir = Get-DotFilesDir
if (!$DotFilesDir) {
    Write-Host "Dotfiles dir could not be located.  Set environment variable DOTFILES_DIR if you are using a non-standard location."
    if (Test-Path "$home\.dotfiles\.dotbot\dotbot") {
        $DotFilesDir = "$home\.dotfiles"
    }
    else {
        Write-Host "Could not find dotfiles directory."
        exit 1
    }
    exit 1
}

if (Test-Path "$DotFilesDir\.git\MERGE_HEAD") {
>>>>>>> 612f5670e113a023876d445c9bdeec103333ba2f
    Write-Error "Merge conflict detected. Resolve the conflict and run this script again."
    # git rebase -C "$DOTFILES_DIR" --abort
    exit 1
}

<<<<<<< HEAD
Push-Location $env:DOTFILES_DIR

git add -A
git commit --message '--wip-- [nocicd]'
git pull --rebase
if (Test-Path "$env:DOTFILES_DIR\.git\MERGE_HEAD") {
=======
Push-Location $DotFilesDir

git add -A
git commit --message '-- wip --  [nocicd]'
git pull --rebase
if (Test-Path "$DotFilesDir\.git\MERGE_HEAD") {
>>>>>>> 612f5670e113a023876d445c9bdeec103333ba2f
    Write-Error "Merge conflict detected. Resolve the conflict and run this script again."
    # git rebase -C "$DOTFILES_DIR" --abort
    exit 1
}
git push
<<<<<<< HEAD
& "$env:DOTFILES_DIR\install.sh"
popd
=======
& "$DotFilesDir\install.sh"

Pop-Location

>>>>>>> 612f5670e113a023876d445c9bdeec103333ba2f
