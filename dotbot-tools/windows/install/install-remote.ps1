<#
.SYNOPSIS
    Install dotfiles (and other stuff) from git repo.
#>

trap {
    Read-Host -Prompt "[install-remote.ps1] TRAPPED!  Press enter to exit. ($_)"
}

Write-Host "[install-remote.ps1] MyInvocation.MyCommand.Definition: $($MyInvocation.MyCommand.Definition)"
Write-Host "[install-remote.ps1] MyInvocation.MyCommand.Name: $($MyInvocation.MyCommand.Name)"
Write-Host "[install-remote.ps1] MyInvocation.UnboundArguments: $($MyInvocation.UnboundArguments)"


Write-Host "[install-remote.ps1] MyInvocation: $($MyInvocation | Format-List | Out-String)"
Write-Host "[install-remote.ps1] MyInvocation.MyCommand: $($MyInvocation.MyCommand | Format-List | Out-String)"
Write-Host "[install-remote.ps1] MyInvocation.MyCommand.Definition: $($MyInvocation.MyCommand.Definition | Format-List | Out-String)"
Write-Host "[install-remote.ps1] MyInvocation.MyCommand.Definition: $($MyInvocation.MyCommand.Definition)"

Set-ExecutionPolicy `
    -ExecutionPolicy Bypass `
    -Scope Process `
    -Force

# $IsRepoAvailable = [boolean]$MyInvocation.MyCommand.Path
$IsRepoAvailable = [boolean]$MyInvocation.MyCommand.Name
$CommandToRelaunch = $MyInvocation.MyCommand.Definition

if ($MyInvocation.MyCommand.Name) {
    . $PSScriptRoot\dotbot-tools\Invoke-Later.ps1
}
else {
    Write-Host "Downloading Invoke-Later.ps1..."
    # Invoke-Expression ". { $(Invoke-RestMethod https://raw.githubusercontent.com/jgbright/dotfiles/main/dotbot-tools/Invoke-Later.ps1) }"

    (New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/jgbright/dotfiles/main/dotbot-tools/Invoke-Later.ps1') | Invoke-Expression
    Write-Host "Downloaded Invoke-Later.ps1."
}

function RestartScript {
    Write-Host "[install-remote.ps1] Restarting script..."
    Start-Process `
        -FilePath $MyInvocation.MyCommand.Definition `
        -ArgumentList $MyInvocation.UnboundArguments `
        -Wait
    Write-Host "[install-remote.ps1] Restarted script."
    exit
}


Write-Host "[install-remote.ps1] MyInvocation: $($MyInvocation | Format-List | Out-String)"
Write-Host "[install-remote.ps1] MyInvocation.MyCommand: $($MyInvocation.MyCommand | Format-List | Out-String)"
Write-Host "[install-remote.ps1] MyInvocation.MyCommand.Definition: $($MyInvocation.MyCommand.Definition | Format-List | Out-String)"
Write-Host "[install-remote.ps1] MyInvocation.MyCommand.Definition: $($MyInvocation.MyCommand.Definition)"

Set-StrictMode -Version 3.0
$ErrorActionPreference = "Stop"

$IsRepoAvailable = [boolean]$MyInvocation.MyCommand.Path


$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

Write-Host "[install-remote.ps1] scriptPath: $scriptPath"
Write-Host "[install-remote.ps1] MyInvocation.MyCommand.Path: $($MyInvocation.MyCommand.Path)"
Write-Host "[install-remote.ps1] MyInvocation.MyCommand.Path: $($MyInvocation.MyCommand.Path)"
Write-Host "[install-remote.ps1] MyInvocation.UnboundArguments: $($MyInvocation.UnboundArguments)"

# This is actually pretty important to note as it will change and that change will impact the script.
Write-Host "[install-remote.ps1] PSVersionTable: $($PSVersionTable | Format-Table | Out-String)"


. $PSScriptRoot/dotbot-tools/Invoke-Later.ps1

# Find the path to either the pwsh or powershell command.  We prefer to use pwsh as it is current and cross-platform.
# On a Windows 10 system, we are guaranteed (?) to have old powershell.  We can bootstrap pwsh later.
# function Get-PwshCommandSource {
#     'pwsh', 'powershell' |
#     ForEach-Object {
#         Get-Command $_ -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
#     } |
#     Where-Object { $_ } |
#     Select-Object -First 1
# }


# Returns true if a continuation is needed.
function Install-Git {
    if (Find-GitExe) {
        Write-Host "Git is already installed."
    }
    else {

        Write-Host "Downloading git..."
        $git_url = "https://api.github.com/repos/git-for-windows/git/releases/latest"
        $ProgressPreference = 'SilentlyContinue'
        $asset = Invoke-RestMethod $git_url | Select-Object -Expand assets | Where-Object name -like "*64-bit.exe"
        $installer = "$env:temp\$($asset.name)"
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $installer
        Write-Host "Downloaded git."

        Write-Host "Installing git..."
        $git_install_inf = "<install inf file>"
        $install_args = "/SP- /VERYSILENT /SUPPRESSMSGBOXES /NOCANCEL /NORESTART /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /LOADINF=""$git_install_inf"""
        # $install_args = "/SP- /VERYSILENT /SUPPRESSMSGBOXES /NOCANCEL /NORESTART /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /LOADINF=""$git_install_inf"""
        # $install_args = "/VERYSILENT /NORESTART"
        Start-Process -Wait -FilePath $installer -ArgumentList $install_args
        Remove-Item $installer -Force
        Write-Host "Installed git."

        # Write-Host "Relaunching script..."
        # Start-Process -Wait -NoNewWindow (Get-PwshCommandSource) -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"Invoke-RestMethod https://raw.githubusercontent.com/jgbright/dotfiles/main/install-remote.ps1 | Invoke-Expression`""
        # Write-Host "Relaunched script..."

        Write-Host "Scheduling task to run in 5 seconds..."


        # TODO: Consider using the EncodedCommand parameter instead of the Command and Argument parameters as it can 
        # better cope with escaping strings.
        # https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_powershell_exe?view=powershell-5.1#examples
        $action = New-ScheduledTaskAction `
            -Execute (Get-PwshCommandName) `
            -Argument (
                # '-ExecutionPolicy Bypass -NonInteractive -Command '+
                '-ExecutionPolicy Bypass -Command '+
                '"& { Invoke-RestMethod "https://raw.githubusercontent.com/jgbright/dotfiles/main/install-remote.ps1?random-junk=$(Get-Random)" | Invoke-Expression } 2>&1 > $env:temp/jgbright-dotfiles-install-remote-$(Get-Date -Format "yyyy-MM-dd_hh-mm-ss-FFF").log"')

        $trigger =  New-ScheduledTaskTrigger -Once -At ([DateTime]::Now).AddSeconds(5)
        Register-ScheduledTask `
            -Action $action `
            -RunLevel Highest `
            -Trigger $trigger `
            -TaskName "dotfiles-git-continuation" `
            -Description "Install dotfiles, continued after installing git." `

            # https://superuser.com/a/1622540

        Write-Host "Scheduled task."

        Write-Host "This script will now exit and a new window will pop up to continue the installation."

        Start-Sleep -Seconds 5

        Read-Host -Prompt 'Press enter to exit. (waiting for git to finish installing)'
        
        return $true
    }
}

function Find-GitExe {
    $GitCmd = Get-Command git -ErrorAction SilentlyContinue
    if ($GitCmd) {
        return $GitCmd.Path
    }

    $GitDir = Get-ChildItem $env:ProgramFiles | Where-Object Name -eq Git | Select-Object -ExpandProperty FullName
    $GitExe = Get-ChildItem -Recurse $GitDir git.exe | ? FullName -like '*cmd\git.exe'

    if (!$GitExe) {
        return $false
    }

    return $GitExe.FullName
}

$MagicSshConfig = 'StrictHostKeyChecking=accept-new'


Write-Host "[install-remote.ps1] [before Main] MyInvocation.MyCommand.Path: $($MyInvocation.MyCommand.Path)"
Write-Host "[install-remote.ps1] [before Main] MyInvocation.UnboundArguments: $($MyInvocation.UnboundArguments)"

function Main {
    
    Write-Host "[install-remote.ps1] [Main] MyInvocation.MyCommand.Path: $($MyInvocation.MyCommand.Path)"
    Write-Host "[install-remote.ps1] [Main] MyInvocation.UnboundArguments: $($MyInvocation.UnboundArguments)"

    if (Install-Git) {
        return
    }
    $git = Find-GitExe

    Write-Host "Running git found here: $git"

    if ((Test-Path ~/.ssh/config) -and (Select-String $MagicSshConfig ~/.ssh/config)) {
        Write-Host "SSH config already contains magic string."
    }
    else {
        Write-Host "Adding magic string to SSH config..."
        New-Item -ItemType Directory -Force -Path ~/.ssh | Out-Null
        Add-Content ~/.ssh/config $MagicSshConfig
        Write-Host "Added magic string to SSH config."
    }

    Write-Host "Cloning dotfiles..."
    & $git clone git@github.com:jgbright/dotfiles.git (Join-Path $HOME .dotfiles)
    if (!$?) {
        Write-Host "Failed to load ""git"" url, trying https url instead..."
        & $git clone https://github.com/jgbright/dotfiles.git (Join-Path $HOME .dotfiles)
    }
    Write-Host "Cloned dotfiles."

    Write-Host "Setting execution policy..."
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force
    Write-Host "Set execution policy."

    Write-Host "Running install script..."
    & "$HOME/.dotfiles/install.ps1"
    Write-Host "Ran install script."
}

Main

Read-Host -Prompt '[install-remote.ps1] Press enter to exit.'
