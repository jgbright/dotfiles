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

function Get-PwshCommandName {
    $PwshPathCandidate = 'C:/Program Files/PowerShell/7/pwsh.exe'

    $PwshExe = Get-Command pwsh -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
    if ($PwshExe) {
        return $PwshExe
    }

    if (Test-Path $PwshPathCandidate) {
        return $PwshPathCandidate
    }

    return Get-Command Powershell -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
}

function ElevateIfNeeded {
    If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
    {
        if ($Elevated) {
            Write-Host "We already attempted to elevate the process once, so I guess we can't..."
            return $true
        }

        # Relaunch as an elevated process:
        Start-Process `
            -Verb RunAs `
            -Wait `
            -FilePath (Get-PwshCommandName) `
            -ArgumentList "-Command & '$($PSCommandPath)' -Elevated"
        return $true
    }
}



<#
Install winget using the WingetTools pwsh module.
https://github.com/jdhitsolutions/WingetTools
#>
function Install-WingetAndTools {
    $PreviousProgressPreference = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'

    try {
        if (!(Get-PackageProvider | Where-Object Name -eq NuGet)) {
            Write-Host "Installing NuGet pwsh package provider..."
            Get-PackageProvider NuGet -ForceBootstrap | Out-Null
            Write-Host "Installed NuGet pwsh package provider."
        }

        if (!(Get-InstalledModule -Name WingetTools -ErrorAction SilentlyContinue)) {
            Write-Host "Installing WingetTools..."
            Install-Module WingetTools -Scope CurrentUser -Force
            Write-Host "Installed WingetTools."
        }

        if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
            Write-Host "Installing winget..."
            Install-WinGet
            Write-Host "Installed winget."
        }
    }
    finally {
        $ProgressPreference = $PreviousProgressPreference
    }

    # Below is an another way to install winget that uses Add-AppxPackageFromUrl.

    # Add-AppxPackageFromUrl https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx
    # Add-AppxPackageFromUrl https://github.com/microsoft/winget-cli/releases/download/v1.3.2691/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle


    # Install Terminal


    # irm https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -o Microsoft.VCLibs.appx
    # Add-AppxPackage .\Microsoft.VCLibs.appx
    # Remove-Item .\Microsoft.VCLibs.appx


    # $url = "https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.8.2"
    # $zipFile = "Microsoft.UI.Xaml.2.8.2.nupkg.zip"
    # Invoke-WebRequest https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.8.2 -OutFile Microsoft.UI.Xaml.2.8.2.zip
    # Expand-Archive Microsoft.UI.Xaml.2.8.2.zip
    # Add-AppxPackage ".\Microsoft.UI.Xaml.2.8.2\tools\AppX\x64\Release\Microsoft.UI.Xaml.2.8.appx" -ErrorAction SilentlyContinue

    
    # $url = "https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.7.3"
    # $zipFile = "Microsoft.UI.Xaml.2.7.3.nupkg.zip"
    # Invoke-WebRequest https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.7.3 -OutFile Microsoft.UI.Xaml.2.7.3.zip
    # Expand-Archive Microsoft.UI.Xaml.2.7.3.zip
    # Add-AppxPackage ".\Microsoft.UI.Xaml.2.7.3\tools\AppX\x64\Release\Microsoft.UI.Xaml.2.7.appx" -ErrorAction SilentlyContinue

    # irm https://github.com/microsoft/terminal/releases/download/v1.16.10261.0/Microsoft.WindowsTerminal_Win11_1.16.10262.0_8wekyb3d8bbwe.msixbundle -o Microsoft.WindowsTerminal_Win11_1.msixbundle
    # Add-AppxPackage .\Microsoft.WindowsTerminal_Win11_1.msixbundle
    # Remove-Item .\Microsoft.WindowsTerminal_Win11_1.msixbundle


    # Add-AppxPackage https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx
    # Add-AppxPackage https://github.com/microsoft/terminal/releases/download/v1.16.10261.0/Microsoft.WindowsTerminal_Win11_1.16.10262.0_8wekyb3d8bbwe.msixbundle
    # Add-AppxPackageFromUrl https://github.com/microsoft/winget-cli/releases/download/v1.3.2691/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle

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
    Start-BitsTransfer -Source $Uri -Destination $TempFile | Complete-BitsTransfer
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

function Install-WingetProgram {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(ValueFromPipeline, ParameterSetName = "Pipeline", Mandatory)]
        [object[]]
        $Programs,

        [Parameter(ParameterSetName = "Pipeline")]
        [Parameter(ParameterSetName = "Parameters")]
        [object[]]
        $InstalledPrograms,

        [Parameter(ParameterSetName = "Parameters", Mandatory)]
        [string]
        $Id,

        [Parameter(ParameterSetName = "Parameters")]
        [string]
        $Version,

        [Parameter(ParameterSetName = "Parameters")]
        [string]
        $Source,

        [Parameter(ParameterSetName = "Parameters")]
        [string]
        $Override
    )

    Process {
        if ($PSCmdlet.ParameterSetName -eq 'Parameters') {
            $Program = @{
                Id = $Id
            }
            if ($Version) {
                $Program.Version = $Version
            }
            if ($Source) {
                $Program.Source = $Source
            }
            if ($Override) {
                $Program.Override = $Override
            }
            $PipelineInput = @($Program)
        }
        else {
            $PipelineInput = $Programs
        }

        $PipelineInput `
        | ForEach-Object {
            $IsString = $_ -is [string]

            if ($_ -is [hashtable]) {
                $Program = [PSCustomObject]$_
            }
            else {
                $Program = $_
            }

            $Id = if ($IsString) { $Program } else { $Program.Id }
            $Version = if ((-not $IsString) -and ($Program | Get-Member Version)) { $Program.Version }
            $Source = if ($IsString) { 'winget' } else { $Program.Source }
            $Override = if ((-not $IsString) -and ($Program | Get-Member Override)) { $Program.Override }

            Write-Host "Id: $Id"
            Write-Host "Version: $Version"
            Write-Host "Source: $Source"
            Write-Host "Override: $Override"

            if ($InstalledPrograms | Where-Object Id -eq $Id) {
                Write-Host "Upgrading $Id..."

                $WingetArgs = @()
                $WingetArgs += 'upgrade'

                $WingetArgs += @(
                    '--id',
                    $Id ,
                    "--source=$Source",
                    '--accept-package-agreements',
                    '--accept-source-agreements',
                    '--silent'
                )

                # Echo command text for troubleshooting.
                Write-Host "> winget $WingetArgs"
                if ($PSCmdlet.ShouldProcess($Id, "Upgrading")) {
                    winget @WingetArgs
                }

                Write-Host "Upgraded $Id."
            }
            else {
                Write-Host "Installing $Id..."

                $WingetArgs = @()
                $WingetArgs += 'install'

                if (!$Source) {
                    throw "error, invalid winget data: $Id"
                }

                $WingetArgs += '--id', $Id
                if ($Source) {
                    $WingetArgs += '--source', $Source
                }
                if ($Version) {
                    $WingetArgs += '--source', $Version
                }
                $WingetArgs += @(
                    '--accept-package-agreements',
                    '--accept-source-agreements',
                    '--silent'
                )
                if ($Override) {
                    $WingetArgs += '--override', $Override
                }

                # Echo command for troubleshooting.
                Write-Host "> winget $WingetArgs"
                if ($PSCmdlet.ShouldProcess($Id, "Installing")) {
                    winget @WingetArgs
                }

                Write-Host "Installed $Id."
            }
        }
    }
}



function RestartScript {
    [CmdletBinding()]
    param (
        [string]$NextLogFileSlug,
        [TimeSpan]$Delay = [TimeSpan]::FromSeconds(10)
    )

    Write-Host "Restarting script..."

    # $FilePath = $MyInvocation.MyCommand.Definition
    # $ArgumentList = $MyInvocation.UnboundArguments

    Write-Host "NextLogFileSlug: $NextLogFileSlug"

    Write-Host "PSCommandPath: $PSCommandPath"
    Write-Host "MyInvocation: $($MyInvocation | Format-List | Out-String)"
    # Write-Host "MyInvocation.MyCommand: $($MyInvocation.MyCommand | Format-List | Out-String)"
    # Write-Host "MyInvocation.MyCommand.Definition: $($MyInvocation.MyCommand.Definition)"
    Write-Host "MyInvocation.UnboundArguments: $($MyInvocation.UnboundArguments | Out-String)"

    if ($PSCommandPath) {
        $Command = $PSCommandPath
    }
    else {
        $Command = $MyInvocation.MyCommand.Definition
        
    }

    Invoke-Later `
        -RunAsAdministrator `
        -ScheduledTask `
        -NextLogFileSlug $NextLogFileSlug `
        -Delay $Delay `
        -Command $Command

    Write-Host "Restarted script."
}

function Configure-PwshExecutionPolicy {
    Write-Host "Configuring pwsh..."

    Set-ExecutionPolicy `
        -ExecutionPolicy Bypass `
        -Scope CurrentUser `
        -Force

    Write-Host "Configured pwsh."
}

function Main {

        
    # This is actually pretty important to note as it will change and that change will impact the script.

    $Date = Get-Date -Format g
    $PowershellVersion = $PSVersionTable.PSVersion
    if ($PSVersionTable.PSEdition -eq 'Core') {
        $PowershellName = 'pwsh'
    } else {
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
    Write-Host "MyInvocation: $($MyInvocation | Format-List | Out-String)"
    Write-Host "MyInvocation.MyCommand: $($MyInvocation.MyCommand | Format-List | Out-String)"
    Write-Host "MyInvocation.MyCommand.Definition: $($MyInvocation.MyCommand.Definition)"

    if (ElevateIfNeeded) {
        return
    }

    # $IsRepoAvailable = [boolean]$MyInvocation.MyCommand.Path
    # $IsRepoAvailable = [boolean]$MyInvocation.MyCommand.Name
    $IsRepoAvailable = [boolean]$PSCommandPath
    $IsRepoReallyAvailable = [boolean]$PSCommandPath -and (Test-Path $PSCommandPath)
    $IsRepoReallyReallyAvailable = `
        [boolean]$PSCommandPath -and `
    (Test-Path $PSCommandPath) -and `
    (Test-Path "$([System.IO.Path]::GetDirectoryName($PSCommandPath))\dotbot-tools\windows\Invoke-Later.ps1")

    $CommandToRestartScript = $MyInvocation.MyCommand.Definition

    Write-Host "IsRepoAvailable: $IsRepoAvailable"
    Write-Host "IsRepoReallyAvailable: $IsRepoReallyAvailable"
    Write-Host "IsRepoReallyReallyAvailable: $IsRepoReallyReallyAvailable"
    Write-Host "CommandToRestartScript: $CommandToRestartScript"
    Write-Host "PSCommandPath: $PSCommandPath"

    if ($IsRepoAvailable) {
        Write-Host "Importing Invoke-Later.ps1..."
        . "$PSScriptRoot/dotbot-tools/windows/Invoke-Later.ps1"
        Write-Host "Imported Invoke-Later.ps1."
    }
    else {
        Write-Host "Downloading Invoke-Later.ps1..."
        (New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/jgbright/dotfiles/main/dotbot-tools/windows/Invoke-Later.ps1') | Invoke-Expression
        Write-Host "Downloaded Invoke-Later.ps1."
    }


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
    $BASEDIR = $PSScriptRoot

    [Environment]::SetEnvironmentVariable('DOTFILES_DIR', "$PSScriptRoot", 'User')

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

    Get-Service bits | Start-Service

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
        RestartScript -NextLogFileSlug 'install.ps1-after-installing-core-tools'
        Write-Host "Restarted script."
        return
    }

    Set-StrictMode -Version 3.0

    Configure-PwshExecutionPolicy

    Write-Host "Finished installing prerequisites."

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

            Invoke-Later `
                -File "$PSScriptRoot/dotbot-tools/windows/install/configure-apps.ps1" `
                -ScheduledTask `
                -NextLogFileSlug 'configure-apps'

            Write-Host "Finished running dotbot.  Another script will launch in a few seconds to configure apps."
            return
        }
    }

    Write-Error "Error: Cannot find Python."
}

# These need to be top-level in this file, because the context will change.
Write-Host "MyInvocation: $($MyInvocation | Format-List | Out-String)"
Write-Host "MyInvocation.MyCommand: $($MyInvocation.MyCommand | Format-List | Out-String)"
Write-Host "MyInvocation.MyCommand.Definition: $($MyInvocation.MyCommand.Definition)"

Main

Read-Host "Press any key to exit..."
