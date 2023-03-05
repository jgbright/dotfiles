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
    [switch]$Elevated,
    [switch]$SkipElevationCheck,
    [switch]$SkipPrerequisites
)

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

# function Install-WindowsTerminal {
#     if (Get-AppxPackage 'Microsoft.WindowsTerminal') {
#         Write-Host "Windows Terminal is already installed."
#         return
#     }

#     $PreviousProgressPreference = $ProgressPreference
#     $ProgressPreference = 'SilentlyContinue'

#     try {
#         Write-Host "Installing Windows Terminal..."

#         Add-AppxPackageFromUrl `
#             -Uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx `
#             -Name "Microsoft Visual C++ Redistributable (x64)"

#         Install-MicrosoftUiXaml

#         Add-AppxPackageFromUrl `
#             -Uri https://github.com/microsoft/terminal/releases/download/v1.16.10261.0/Microsoft.WindowsTerminal_Win11_1.16.10262.0_8wekyb3d8bbwe.msixbundle `
#             -Name "Windows Terminal"

#         Write-Host "Installed Windows Terminal."
#     }
#     finally {
#         $ProgressPreference = $PreviousProgressPreference
#     }
# }




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

    Write-Host "SkipPrerequisites: $SkipPrerequisites"
    Write-Host "Elevated: $Elevated"
    Write-Host "SkipElevationCheck: $SkipElevationCheck"
    
    Get-PSCallStack | Out-String | Write-Host
}

function ImportTools {

    if ($PSCommandPath) {
        Write-Host "Importing tools..."
        . "$PSScriptRoot/dotbot-tools/windows/Run.ps1"
        . "$PSScriptRoot/dotbot-tools/windows/install/winget.ps1"
        Write-Host "Imported tools."
    }
    else {
        Write-Host "Downloading tools..."
        (New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/jgbright/dotfiles/main/dotbot-tools/windows/Run.ps1') | Invoke-Expression
        (New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/jgbright/dotfiles/main/dotbot-tools/windows/install/winget.ps1') | Invoke-Expression
        Write-Host "Downloaded tools."
    }
}

function Main {
    
    PrintHeader
    
    ImportTools

    if (!$SkipElevationCheck -and !(IsAdminUser)) {
        if ($Elevated) {
            Read-Host -Prompt "ERROR: Failed to run installation process with admin privileges."
        }
        else {
            Write-Host "Restarting installation process with admin privileges..."
            Run `
                -Restart `
                -AsAdministrator `
                -ScriptParams '-Elevated' `
                -LogSlug restarted-with-admin-privileges
        }
        
        return
    }

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

    # For now, let's just give this script the ability to restart itself.  We'll do
    # something similar for the current user after we know we are on pwsh and not
    # powershell.
    # Set-ExecutionPolicy `
    #     -ExecutionPolicy Bypass `
    #     -Scope Process `
    #     -Force


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

    $NeedPrerequisites = -not $SkipPrerequisites
    if ($NeedPrerequisites) {
        Write-Host "Installing prerequisites..."

        Install-WingetAndTools

        # Install software that will be used or configured later.  In particular,
        # these are programs known to require a new process before you can start
        # using them.
        @(
            @{ 
                Id = 'Microsoft.PowerShell'
                # Scope = 'Machine'
            },
            @{ 
                Id    = 'Git.Git'
                Scope = 'user'
            },
            @{ 
                Id    = 'Python.Python.3.11'
                Scope = 'user'
            },
            @{ 
                Id = 'Microsoft.DotNet.SDK.6'
            }
        ) | Install-WingetProgram -InstalledPrograms (Get-WGInstalled)

        Write-Host "Finished installing prerequisites."
    }

    # Look for a reason to restart the script.  It would be nice to avoid a restart if possible.
    $RequiredCommands = 'git', 'python', 'pwsh', 'dotnet'
    $MissingCommands = $RequiredCommands | Where-Object { -not (Get-Command $_ -ErrorAction SilentlyContinue) }

    $PythonVersion = & { 
        $ErrorActionPreference = "SilentlyContinue"
        ![string]::IsNullOrEmpty((& python -V))
        $ErrorActionPreference = "Stop"
    }

    if (!$PythonVersion -and $MissingCommands -notcontains 'python') {
        $MissingCommands += 'python'
    }

    if ($MissingCommands -or $PSVersionTable.PSEdition -ne 'Core') {
        if ($MissingCommands) {
            Write-Host "Some required commands are not available ($MissingCommands)."
        }

        if ($PSVersionTable.PSEdition -ne 'Core') {
            Write-Host "We're running PowerShell instead of pwsh."
        }

        if ($SkipPrerequisites) {
            Read-Host -Prompt "Already tried restarting the script, but that didn't work."
        }
        else {
            Write-Host "Restarting script..."

            $Command = Get-PwshCommandWithLog `
                -File "$BASEDIR\install.ps1" `
                -ScriptParams '-SkipPrerequisites' `
                -LogSlug 'install.ps1-after-installing-prerequisites'

            RunPwshSoon $Command

            Write-Host "Restarted script."
        }
        return
    }

    Set-StrictMode -Version 3.0

    Configure-PwshExecutionPolicy

    if ($NeedToInstallRepo) {
        Write-Host "Installing dotfiles repository..."
        git clone https://github.com/jgbright/dotfiles $BASEDIR
    }

    # Now that the files are in place, we want to use them if/when we restart the scrip.
    $Self = "$BASEDIR\install.ps1"

    Write-Host "Installing local dotfiles repository in $DOTBOT_DIR..."
    git -C $DOTBOT_DIR submodule sync --quiet --recursive
    Write-Host "Installed local dotfiles repository."

    Write-Host "Updating submodules..."
    git submodule update --init --recursive $DOTBOT_DIR
    Write-Host "Updated submodules."

    Write-Host "Running dotbot..."

    $Python = 'python', 'python3', 'python2' | 
    Where-Object { 
        $Version = & $_ -V
        $Result = $? -and $Version
        Write-Host "Valid: $Result Python: $_ Version: $Version"
        return $Result
    } | 
    Select-Object -First 1

    Write-Host "PYTHON: $Python"

    if (!$Python) {
        Write-Error "Error: Cannot find Python."
        exit 1
    }
        
    # $DotBotCli = Join-Path $BASEDIR -ChildPath $DOTBOT_DIR | Join-Path -ChildPath $DOTBOT_BIN
    # $DotbotPluginArgs = Get-ChildItem "$BASEDIR\dotbot-plugins" -Directory | ForEach-Object { " ``n    --plugin-dir '$_'" }
    #             $Command = @"
    # & '$Python' $DotBotCli `
    #     -d $BASEDIR$DotbotPluginArgs `
    #     -c $CONFIG $Args
    # "@



    # $DotBotCli = Join-Path $BASEDIR -ChildPath $DOTBOT_DIR | Join-Path -ChildPath $DOTBOT_BIN
    # $PwshCommandToLaunchDotBot = "& '$Python' '$DotBotCli'"
    # foreach ($PluginDir in (Get-ChildItem "$BASEDIR\dotbot-plugins" -Directory)) {
    #     $PwshCommandToLaunchDotBot += " `n    --plugin-dir '$PluginDir'"
    # }
    # $PwshCommandToLaunchDotBot += " `n    -c '$CONFIG' $Args"

    # Invoke-Command {

    # }

    $DotbotPluginArgs = Get-ChildItem "$BASEDIR\dotbot-plugins" -Directory | ForEach-Object { '--plugin-dir', $_.FullName }

    Write-Host "& $Python $DotBotCli -d $BASEDIR -c $CONFIG $DotbotPluginArgs $Args"
    & $Python $DotBotCli -d $BASEDIR -c $CONFIG $DotbotPluginArgs $Args

    Write-Host "🎉 Enjoy!"
}

# These need to be top-level in this file, because the context will change.

# Write-Host "MyInvocation: $($MyInvocation | Format-List | Out-String)"
# Write-Host "MyInvocation.MyCommand: $($MyInvocation.MyCommand | Format-List | Out-String)"
# Write-Host "MyInvocation.MyCommand.Definition: $($MyInvocation.MyCommand.Definition)"

Main

# Read-Host "Press any key to exit..."
