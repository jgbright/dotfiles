#!/usr/bin/env pwsh

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


if ($PSVersionTable.Platform -eq 'Unix') {
    throw "On unix systems, run install.sh instead."
}

# It's important not to setup the actual ~/.gitconfig file here.  We want to wrap that up when an interactive shell
# starts.  We do this to avoid problems with the dev container's dotfile implementation.
function Configure-Git {
    $HomeConfigFile = [System.IO.Path]::Combine($home, '.gitconfig')
    if (-not (Test-Path $HomeConfigFile)) {
        # $DotfilesConfigFile = [System.IO.Path]::Combine($home, '.gitconfig')
        # Copy-Item $DotfilesConfigFile $HomeConfigFile
        return
    }

    if ((git config --global include.path) -eq '') {
        git config --global include.path ($IsLinux ? '.gitconfig-linux' : '.gitconfig-windows')
    }
}

function Main {
    Configure-Git
}

Main
