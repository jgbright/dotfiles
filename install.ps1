<#
.SYNOPSIS
    Install dotfiles, configure the environment, and set up various software.
.DESCRIPTION
    Install dotfiles for the current user with symlinks to files in this
    directory.  It also installs various software I use.  This script will
    restart itself as needed to pick up environmental changes and to elevate
    privileges of the process.
#>

[CmdletBinding()]
param (
    [switch]$Elevated
)

$ErrorActionPreference = "Stop"

trap {
    Read-Host -Prompt "TRAPPED!  Press enter to exit. ($_)"
}

function IsAdminUser {
    $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object Security.Principal.WindowsPrincipal($Identity)
    $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}



function Add-AppxPackageFromUrl {
    param(
        [Parameter(Mandatory = $true)]
        [Uri]$Uri,
        [string]$Name
    )
    $FileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($Uri)
    $Extension = [System.IO.Path]::GetExtension($Uri)
    $TempFile = "$([System.IO.Path]::GetTempPath())/${FileNameWithoutExtension}_$([guid]::NewGuid())$Extension"
    if (!$Name) {
        $Name = $FileNameWithoutExtension
    }

    Write-Host "Downloading $Name..."
    (New-Object System.Net.WebClient).DownloadFile($Uri, $TempFile)
    Write-Host "Downloaded $Name."

    Write-Host "Installing $Name..."
    Add-AppxPackage $TempFile
    Write-Host "Installed $Name."

    Remove-Item $TempFile
}

function Install-MicrosoftUiXaml {

    $TempDir = New-Item -ItemType Directory -Path $env:TEMP -Name "Microsoft.UI.Xaml_$([guid]::NewGuid())" -Verbose
    $Uri = 'https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.7.3'

    Write-Host "Downloading Microsoft.UI.Xaml..."
    Invoke-WebRequest -Uri $Uri -OutFile "$TempDir\Microsoft.UI.Xaml.zip"
    Write-Host "Downloaded Microsoft.UI.Xaml."

    Write-Host "Extracting Microsoft.UI.Xaml..."
    Expand-Archive "$TempDir\Microsoft.UI.Xaml.zip" -DestinationPath "$TempDir\Microsoft.UI.Xaml"
    Write-Host "Extracted Microsoft.UI.Xaml."

    Write-Host "Installing Microsoft.UI.Xaml..."
    Add-AppxPackage "$TempDir\Microsoft.UI.Xaml\tools\AppX\x64\Release\Microsoft.UI.Xaml.2.7.appx" -ErrorAction SilentlyContinue
    Write-Host "Installed Microsoft.UI.Xaml."

    Remove-Item $TempDir -Recurse -Force
}

function Install-WindowsTerminal {
    if (Get-AppxPackage 'Microsoft.WindowsTerminal') {
        Write-Host "Windows Terminal is already installed."
        return
    }

    $PreviousProgressPreference = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'

    try {
        Write-Host "Installing Windows Terminal..."

        Add-AppxPackageFromUrl `
            -Uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx `
            -Name "Microsoft Visual C++ Redistributable (x64)"

        Install-MicrosoftUiXaml

        Add-AppxPackageFromUrl `
            -Uri https://github.com/microsoft/terminal/releases/download/v1.16.10261.0/Microsoft.WindowsTerminal_Win11_1.16.10262.0_8wekyb3d8bbwe.msixbundle `
            -Name "Windows Terminal"

        Write-Host "Installed Windows Terminal."
    }
    finally {
        $ProgressPreference = $PreviousProgressPreference
    }
}




# function RestartScript {
#     [CmdletBinding()]
#     param (
#         [string]$NextLogFileSlug,
#         [TimeSpan]$Delay = [TimeSpan]::FromSeconds(10)
#     )

#     Write-Host "Restarting script..."

#     # $FilePath = $MyInvocation.MyCommand.Definition
#     # $ArgumentList = $MyInvocation.UnboundArguments

#     Write-Host "NextLogFileSlug: $NextLogFileSlug"

#     Write-Host "PSCommandPath: $PSCommandPath"
#     # Write-Host "MyInvocation: $($MyInvocation | Format-List | Out-String)"
#     # Write-Host "MyInvocation.MyCommand: $($MyInvocation.MyCommand | Format-List | Out-String)"
#     # Write-Host "MyInvocation.MyCommand.Definition: $($MyInvocation.MyCommand.Definition)"
#     # Write-Host "MyInvocation.UnboundArguments: $($MyInvocation.UnboundArguments | Out-String)"

#     if ($PSCommandPath) {
#         $Command = $PSCommandPath
#     }
#     else {
#         $Command = (Get-PSCallStack)[-1].Position.Text
#     }

#     Write-Host "Command: $Command"

#     Invoke-Later `
#         -RunAsAdministrator `
#         -ScheduledTask `
#         -NextLogFileSlug $NextLogFileSlug `
#         -Delay $Delay `
#         -Command $Command

#     Write-Host "Restarted script."
# }

function Configure-PwshExecutionPolicy {
    Write-Host "Configuring pwsh..."

    Set-ExecutionPolicy `
        -ExecutionPolicy Bypass `
        -Scope CurrentUser `
        -Force

    Write-Host "Configured pwsh."
}

function PrintHeader {
    
    # This is actually pretty important to note as it will change and that change will impact the script.

    $Date = Get-Date -Format g
    $PowershellVersion = $PSVersionTable.PSVersion
    if ($PSVersionTable.PSEdition -eq 'Core') {
        $PowershellName = 'pwsh'
    }
    else {
        $PowershellName = 'PowerShell'
    }
    
    if ([Environment]::OSVersion.Platform -eq 'Unix') {
        $OperatingSystem = $(lsb_release -sd)
    }
    else {
        $OperatingSystem = (Get-WmiObject -class Win32_OperatingSystem).Caption
    }
    
    $MachineName = [Environment]::MachineName
    $UserName = [Environment]::UserName
    
    Write-Host "Installing jgbright/dotfiles..."
    Write-Host "DATE: $Date"
    Write-Host "USER@HOST: $UserName@$MachineName"
    Write-Host "OS: $OperatingSystem"
    Write-Host "SHELL: $PowershellName $PowershellVersion"
    
    Write-Host "PSCommandPath: $PSCommandPath"
}

function Main {
    
    PrintHeader
    
    # if ($IsRepoAvailable) {
    #     Write-Host "Importing Invoke-Later.ps1..."
    #     . "$PSScriptRoot/dotbot-tools/windows/Invoke-Later.ps1"
    #     Write-Host "Imported Invoke-Later.ps1."
    # }
    # else {
    #     Write-Host "Downloading Invoke-Later.ps1..."
    #         (New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/jgbright/dotfiles/main/dotbot-tools/windows/Invoke-Later.ps1') | Invoke-Expression
    #     Write-Host "Downloaded Invoke-Later.ps1."
    # }

    if ($PSCommandPath) {
        Write-Host "Importing Run.ps1..."
        . "$PSScriptRoot/dotbot-tools/windows/Run.ps1"
        . "$PSScriptRoot/dotbot-tools/windows/install/winget.ps1"
        Write-Host "Imported Run.ps1."
    }
    else {
        Write-Host "Downloading Run.ps1..."
        (New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/jgbright/dotfiles/main/dotbot-tools/windows/Run.ps1') | Invoke-Expression
        (New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/jgbright/dotfiles/main/dotbot-tools/windows/install/winget.ps1') | Invoke-Expression
        Write-Host "Downloaded Run.ps1."
    }


    if (!(IsAdminUser)) {
        if ($Elevated) {
            Read-Host -Prrompt "Already tried elevating privileges, but that didn't work."
        }
        else {
            Write-Host "Elevating privileges..."
            Run `
                -Self $PSCommandPath `
                -AsAdministrator `
                -LogSlug elevated `
                -Wait
        }
        
        return
    }

    & $PSScriptRoot/dotbot-tools/windows/install/install-before-running-dotbot.ps1

    # Write-Host "MyInvocation: $($MyInvocation | Format-List | Out-String)"
    # Write-Host "MyInvocation.MyCommand: $($MyInvocation.MyCommand | Format-List | Out-String)"
    # Write-Host "MyInvocation.MyCommand.Definition: $($MyInvocation.MyCommand.Definition)"

    # if (ElevateIfNeeded) {
    #     return
    # }

    # $IsRepoAvailable = [boolean]$MyInvocation.MyCommand.Path
    # $IsRepoAvailable = [boolean]$MyInvocation.MyCommand.Name
    $IsRepoAvailable = [boolean]$PSCommandPath
    $IsRepoReallyAvailable = [boolean]$PSCommandPath -and (Test-Path $PSCommandPath)
    $IsRepoReallyReallyAvailable = `
        [boolean]$PSCommandPath `
        -and (Test-Path $PSCommandPath) `
        -and (Test-Path "$([System.IO.Path]::GetDirectoryName($PSCommandPath))\.dotbot\bin\dotbot")

    $CommandToRestartScript = if ($PSCommandPath) { $PSCommandPath } else { (Get-PSCallStack)[-1].Position.Text }

    Write-Host "IsRepoAvailable: $IsRepoAvailable"
    Write-Host "IsRepoReallyAvailable: $IsRepoReallyAvailable"
    Write-Host "IsRepoReallyReallyAvailable: $IsRepoReallyReallyAvailable"
    Write-Host "CommandToRestartScript: $CommandToRestartScript"
    Write-Host "PSCommandPath: $PSCommandPath"


    # Invoke-Later `
    # -File "$PSScriptRoot/dotbot-tools/windows/install/configure-apps.ps1" `
    # -ScheduledTask `
    # -NextLogFileSlug 'configure-apps'

    # return

    # For now, let's just give this script the ability to restart itself.  We'll do
    # something similar for the current user after we know we are on pwsh and not
    # powershell.
    Set-ExecutionPolicy `
        -ExecutionPolicy Bypass `
        -Scope Process `
        -Force


    $CONFIG = ".install.windows.conf.yaml"
    $DOTBOT_DIR = ".dotbot"

    $DOTBOT_BIN = "bin\dotbot"

    $BASEDIR = ""
    $NeedToInstallRepo = $false
    if ($PSScriptRoot) {
        $BASEDIR = $PSScriptRoot
        # Might be nice to warn the user if they are not installing under their user dir.
    }
    else {
        $BASEDIR = (Get-Location).Path
        $NeedToInstallRepo = $true
    }

    Write-Host "BaseDir: $BASEDIR"

    # If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    #     Write-Host "Restarting as administrator..."
    #     $pwsh = 'pwsh', 'powershell' | % { Get-Command $_ -ErrorAction SilentlyContinue } | Select-Object -First 1 | Select-Object -ExpandProperty Path

    #     RestartScript `
    #         -NextLogFileSlug 'elevate-to-administrator'

    #     # if ($PSVersionTable.PSEdition -eq 'Core') {
    #     #     $pwsh = 'pwsh.exe'
    #     # } else {
    #     #     $pwsh = 'powershell.exe'
    #     # }
    #     # Write-Host "MyInvocation.MyCommand.Path: $($MyInvocation.MyCommand.Path)"
    #     # write-Host "PSCommandPath: $PSCommandPath"
    #     # Write-Host "pwsh: $pwsh"
    #     # Read-Host "Press enter to continue..."
    #     # Start-Process `
    #     #     -FilePath $pwsh `
    #     #     -ArgumentList "-File ""$PSCommandPath""" `
    #     #     -Verb RunAs
    #     return
    # }

    Set-Location $BASEDIR

    Write-Host "Installing prerequisites..."

    Install-WingetAndTools

    # Install software that will be used or configured later.  In particular,
    # these are programs known to require a new process before you can start
    # using them.
    @(
        'Microsoft.PowerShell',
        'Git.Git',
        'Python.Python.3.11',
        'Microsoft.DotNet.SDK.6'
    ) | Install-WingetProgram -InstalledPrograms (Get-WGInstalled)

    # Look for a reason to restart the script.  It would be nice to avoid a restart if possible.
    $RequiredCommands = 'git', 'python', 'pwsh', 'dotnet'
    $MissingCommands = $RequiredCommands | Where-Object { !(Get-Command $_ -ErrorAction SilentlyContinue) }

    if ($MissingCommands -or $PSVersionTable.PSEdition -ne 'Core') {
        if ($MissingCommands) {
            Write-Host "Some required commands are not available ($MissingCommands)."
        }
        if ($PSVersionTable.PSEdition -ne 'Core') {
            Write-Host "We're running PowerShell instead of pwsh."
        }
        Write-Host "Restarting script..."
        # RestartScript -NextLogFileSlug 
        Run `
            -Self $PSCommandPath `
            -AsAdministrator `
            -LogSlug 'install.ps1-after-installing-core-tools' `
            -Wait
        Write-Host "Restarted script."
        return
    }

    Set-StrictMode -Version 3.0

    Configure-PwshExecutionPolicy

    Write-Host "Finished installing prerequisites."

    if ($NeedToInstallRepo) {
        Write-Host "Installing dotfiles repository..."
        git clone https://github.com/jgbright/dotfiles $BASEDIR
    }

    Write-Host "Installing local dotfiles repository in $DOTBOT_DIR..."
    git -C $DOTBOT_DIR submodule sync --quiet --recursive
    Write-Host "Installed local dotfiles repository."

    Write-Host "Updating submodules..."
    git submodule update --init --recursive $DOTBOT_DIR
    Write-Host "Updated submodules."

    $DotbotPluginArgs = Get-ChildItem "$PSScriptRoot/dotbot-plugins" -Directory | ForEach-Object { "--plugin-dir", $_.FullName }

    Write-Host "Running dotbot..."
    foreach ($PYTHON in ('python', 'python3', 'python2')) {
        # Python redirects to Microsoft Store in Windows 10 when not installed
        if (& { $ErrorActionPreference = "SilentlyContinue"
                ![string]::IsNullOrEmpty((&$PYTHON -V))
                $ErrorActionPreference = "Stop" }) {
            &$PYTHON `
            $(Join-Path $BASEDIR -ChildPath $DOTBOT_DIR | Join-Path -ChildPath $DOTBOT_BIN) `
                -d $BASEDIR `
                @DotbotPluginArgs `
                --plugin-dir "$BASEDIR/dotbot-conditional" `
                --plugin-dir "$BASEDIR/dotbot-crossplatform" `
                -c $CONFIG $Args

            Install-WindowsTerminal

            @(
                @{
                    Id       = 'Microsoft.VisualStudioCode'
                    Source   = 'winget'
                    Override = '/SILENT /mergetasks="!runcode,addcontextmenufiles,addcontextmenufolders"'
                },
                # @{
                #     Id     = 'Microsoft.WindowsTerminal'
                #     Source = 'msstore'
                # },
                'Microsoft.WindowsTerminal',
                'JanDeDobbeleer.OhMyPosh',
                'Google.Chrome',
                'Mozilla.Firefox',
                '7zip.7zip',
                'Fork.Fork',
                'Microsoft.VisualStudioCode',
                'Microsoft.VisualStudio.2022.Community',
                # 'Microsoft.DotNet.DesktopRuntime.7',
                # 'Microsoft.DotNet.SDK.7',
                'LINQPad.LINQPad.7',
                'Microsoft.AzureCLI',
                'CoreyButler.NVMforWindows',
                'Docker.DockerDesktop',
                'NickeManarin.ScreenToGif',
                'Microsoft.PowerToys',
                # 'WinFsp.WinFsp',
                'SSHFS-Win.SSHFS-Win',
                'Logitech.OptionsPlus',
                'SlackTechnologies.Slack',
                'AgileBits.1Password',
                'Greenshot.Greenshot',
                'dotPDNLLC.paintdotnet'
                # 'Starship.Starship',
            ) | Install-WingetProgram -InstalledPrograms (Get-WGInstalled)
            & $PSScriptRoot/dotbot-tools/windows/install/install-after-running-dotbot.ps1
            & install-before-running-dotbot.ps1
            # Run `
            #     -File "$PSScriptRoot/dotbot-tools/windows/install/configure-apps.ps1" `
            #     -LogSlug 'configure-apps'

            # Invoke-Later `
            #     -File "$PSScriptRoot/dotbot-tools/windows/install/configure-apps.ps1" `
            #     -NextLogFileSlug 'configure-apps'
            # -ScheduledTask `

            Write-Host "Finished running dotbot.  Another script will launch in a few seconds to configure apps."
            return
        }
    }

    Write-Error "Error: Cannot find Python."
}

# These need to be top-level in this file, because the context will change.

# Write-Host "MyInvocation: $($MyInvocation | Format-List | Out-String)"
# Write-Host "MyInvocation.MyCommand: $($MyInvocation.MyCommand | Format-List | Out-String)"
# Write-Host "MyInvocation.MyCommand.Definition: $($MyInvocation.MyCommand.Definition)"

Main

# Read-Host "Press any key to exit..."
