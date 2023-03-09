[CmdletBinding()]
param (
    # If true, create .gitconfig if it is missing, otherwise only modify existing config.
    [switch]
    $Force
)

trap {
    Read-Host -Prompt "TRAPPED!  Press enter to exit. ($_)"
}

function Configure-Git {
    $GitConfigFile = [System.IO.Path]::GetFullPath("$home/.gitconfig")
    if (!(Test-Path $GitConfigFile)) {
        if (!$Force) {
            Write-Host "Git config file does not exist."
            return
        }
        Write-Host 'Copying ~/.gitconfig-local...'
        Copy-Item "$PSScriptRoot/../gitconfig-local.template" "$home/.gitconfig"
        Write-Host 'Copied ~/.gitconfig-local.'
    }

    if (!(Select-String -Path $GitConfigFile -Pattern '[include]' -SimpleMatch)) {
        if ($IsLinux) {
            $ToBeIncluded = ".gitconfig-linux"
        } else {
            $ToBeIncluded = ".gitconfig-windows"
        }

        $GitConfigContent = @"
[include]
`tpath = $ToBeIncluded
"@
        Add-Content $GitConfigFile $GitConfigContent
    }
}


function Main {
    Configure-Git
}
    
Main
