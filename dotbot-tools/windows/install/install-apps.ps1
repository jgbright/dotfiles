#requires -psedition Core

trap {
    Read-Host -Prompt "TRAPPED!  Press enter to exit. ($_)"
}

# Scott Hanselman's setupmachine.bat.
#https://gist.githubusercontent.com/shanselman/6b91a78a2db92b81dd07cb28534ee875/raw/f5db11be9d6bc312824f4d1d83a009bfacdc3d38/setupmachine.bat

function Install-WingetTools {
    if (!(Get-PackageProvider | Where-Object Name -eq NuGet)) {
        Write-Host "Installing NuGet pwsh package provider..."
        Get-PackageProvider NuGet -ForceBootstrap
        Write-Host "Installed NuGet pwsh package provider."
    }

    if (!(Get-InstalledModule -Name WingetTools -ErrorAction SilentlyContinue)) {
        Write-Host "Installing WingetTools..."
        Install-Module WingetTools -Scope CurrentUser -Force
        Write-Host "Installed WingetTools."
    }
}

function Install-WingetPrograms {
    Install-WingetTools

    Write-Host "Cataloging installed programs..."
    $Installed = Get-WGInstalled
    Write-Host "Cataloged installed programs."

    @(
        'Google.Chrome',
        'Mozilla.Firefox',
        '7zip.7zip',
        'AgileBits.1Password',
        'Logitech.OptionsPlus',
        'Greenshot.Greenshot',
        'CoreyButler.NVMforWindows',
        'Microsoft.VisualStudio.2022.Community',
        'Microsoft.AzureCLI',
        'Microsoft.VisualStudioCode',
        'LINQPad.LINQPad.7',
        'JanDeDobbeleer.OhMyPosh'
        'Fork.Fork',
        'Docker.DockerDesktop',
        'Microsoft.WindowsTerminal',
        'SlackTechnologies.Slack',
        'dotPDNLLC.paintdotnet',
        'NickeManarin.ScreenToGif',
        'Microsoft.PowerToys',
        'Microsoft.PowerShell',
        # 'Microsoft.DotNet.DesktopRuntime.7',
        # 'Microsoft.DotNet.SDK.7',
        'Microsoft.DotNet.SDK.6'
        # 'WinFsp.WinFsp',
        # 'SSHFS-Win.SSHFS-Win',
    ) | 
    ForEach-Object {
        if ($Installed | Where-Object ID -eq $_) {
            
            Write-Host "Upgrading $_..."

            winget upgrade `
                --id $_ `
                --source winget `
                --accept-package-agreements `
                --accept-source-agreements `
                --silent

            Write-Host "Upgraded $_."
        }
        else {
        
            Write-Host "Installing $_..."

            winget install `
                --id $_ `
                --source winget `
                --accept-package-agreements `
                --accept-source-agreements `
                --silent

            Write-Host "Installed $_."
        }
    }

    # These snowflakes require special handling.

    Write-Host "Installing vscode..."

    winget install `
        --id Microsoft.VisualStudioCode `
        --source winget `
        --accept-package-agreements `
        --accept-source-agreements `
        --override '/SILENT /mergetasks="!runcode,addcontextmenufiles,addcontextmenufolders"'

    Write-Host "Installed vscode."

    winget install `
        --id "windows terminal" `
        --source msstore `
        --accept-package-agreements `
        --accept-source-agreements 

}



function IsNerdFontInstalled {
    try {
        # Add-Type -AssemblyName System.Drawing
        [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
        return (New-Object System.Drawing.Text.InstalledFontCollection).Families | Where-Object Name -like 'FiraCode*'
    }
    catch {
        Write-Host "Unable to determine if fonts are installed.  Continuing..."
        return $false
    }
}

function Install-Fonts {
    if (IsNerdFontInstalled) {
        Write-Host "Fonts already installed."
        return
    }
    
    Write-Host "Installing fonts..."

    $OutFile = "${env:temp}/font-$([Guid]::NewGuid()).zip"
    $TempDir = "${env:temp}/FiraCode-$([Guid]::NewGuid())"
    (New-Object System.Net.WebClient).DownloadFile('https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/FiraCode.zip', $OutFile)
    Expand-Archive `
        -Path $OutFile `
        -DestinationPath $TempDir

    $fonts = $null
    Get-ChildItem `
        -LiteralPath $TempDir `
        -File `
        -Filter *.ttf |
    ForEach-Object {
        if (!$fonts) {
            $shellApp = New-Object -ComObject shell.application
            $fonts = $shellApp.NameSpace(0x14)
        }
        $fonts.CopyHere($fontFile.FullName)
    }

    Write-Host "Installed fonts."
}

function Install-1PasswordCli {
    Write-Host "Installing 1Password CLI..."

    $arch = (Get-CimInstance Win32_OperatingSystem).OSArchitecture
    switch ($arch) {
        '64-bit' { $opArch = 'amd64'; break }
        '32-bit' { $opArch = '386'; break }
        Default { Write-Error "Sorry, your operating system architecture '$arch' is unsupported" -ErrorAction Stop }
    }
    $installDir = Join-Path -Path $env:ProgramFiles -ChildPath '1Password-cli'
    Invoke-WebRequest -Uri "https://cache.agilebits.com/dist/1P/op2/pkg/v2.14.0/op_windows_$($opArch)_v2.14.0.zip" -OutFile op.zip
    Expand-Archive -Path op.zip -DestinationPath $installDir -Force
    $envMachinePath = [System.Environment]::GetEnvironmentVariable('PATH', 'machine')
    if ($envMachinePath -split ';' -notcontains $installDir) {
        [Environment]::SetEnvironmentVariable('PATH', "$envMachinePath;$installDir", 'Machine')
    }
    Remove-Item -Path op.zip

    Write-Host "Installed 1Password CLI."
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
    
    Write-Host "Downloading $Name..."
    (New-Object System.Net.WebClient).DownloadFile($Uri, $TempFile)
    Write-Host "Downloaded $Name."

    Write-Host "Installing $Name..."
    Add-AppxPackage $TempFile
    Write-Host "Installed $Name."

    Remove-Item $TempFile
}

# function Install-WindowsTerminal {
#     # Add-AppxPackageFromUrl 'https://github.com/microsoft/terminal/releases/download/v1.16.10261.0/Microsoft.WindowsTerminal_Win11_1.16.10262.0_8wekyb3d8bbwe.msixbundle'

#     AAP("Microsoft.UI.Xaml.2.7.1.nupkg\tools\AppX\x64\Release\Microsoft.UI.Xaml.2.7.appx")
#     AAP("Microsoft.UI.Xaml.2.7.1.nupkg\tools\AppX\x64\Release\Microsoft.UI.Xaml.2.7.appx")

#     Add-AppxPackage `
#         -ErrorAction SilentlyContinue `
#         "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"
#     Add-AppxPackage `
#         -ErrorAction SilentlyContinue `
#         'https://github.com/microsoft/terminal/releases/download/v1.16.10261.0/Microsoft.WindowsTerminal_Win11_1.16.10262.0_8wekyb3d8bbwe.msixbundle'
# }

function Main {
    Write-Host "Installing apps..."

    Install-WingetPrograms
    Install-Fonts
    Install-1PasswordCli
    # Install-WindowsTerminal

    Write-Host "Installed apps."
}

Main