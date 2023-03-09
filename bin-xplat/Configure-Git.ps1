#!/usr/bin/env pwsh

[CmdletBinding()]
param (
    [switch]$Force
)

#Requires -PSEdition Core

$ErrorActionPreference = "Stop"

function Resolve-Error ($ErrorRecord = $Error[0]) {
    $ErrorRecord | Format-List * -Force
    $ErrorRecord.InvocationInfo | Format-List *
    $Exception = $ErrorRecord.Exception
    for ($i = 0; $Exception; $i++, ($Exception = $Exception.InnerException)) {
        "$i" * 80
        $Exception | Format-List * -Force
    }
}

trap {
    Read-Host -Prompt "TRAPPED!  Press enter to exit. ($_)`n$(Resolve-Error $_ | Out-String)"
}

# It's important not to setup the actual ~/.gitconfig file here.  We want to wrap that up when an interactive shell
# starts.  We do this to avoid problems with the dev container's dotfile implementation.
function Configure-Git {
    $HomeConfigFile = "$home/.gitconfig"
    if (-not $Force -and -not (Test-Path $HomeConfigFile)) {
        Write-Host ".gitconfig not found.  Skipping."
        # $DotfilesConfigFile = [System.IO.Path]::Combine($home, '.gitconfig')
        # Copy-Item $DotfilesConfigFile $HomeConfigFile
        return
    }

    if (-not (Test-Path $HomeConfigFile)) {
        Copy-Item "$PSScriptRoot/../gitconfig-template" $HomeConfigFile
    }

    # $IncludePath = git config --global include.path
    # if (!$IncludePath) {
    #     git config --global include.path $($IsLinux ? '.gitconfig-linux' : '.gitconfig-windows')
    # }
}

function Main {
    Configure-Git
}

Main
