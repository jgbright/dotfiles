#!/usr/bin/env bash

Set-StrictMode -Version 3.0

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

    Write-Host "Dotfiles dir candidates: $DotFilesDirCandidates"

    $DotFilesDirCandidates | Where-Object { Test-Path "$_\.dotfiles_dir" } | Select-Object -First 1
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
    Write-Error "Merge conflict detected. Resolve the conflict and run this script again."
    # git rebase -C "$DOTFILES_DIR" --abort
    exit 1
}

Push-Location $DotFilesDir

git add -A
git commit --message '-- wip --  [nocicd]'
git pull --rebase
if (Test-Path "$DotFilesDir\.git\MERGE_HEAD") {
    Write-Error "Merge conflict detected. Resolve the conflict and run this script again."
    # git rebase -C "$DOTFILES_DIR" --abort
    exit 1
}
git push
& "$DotFilesDir\install.sh"

Pop-Location

