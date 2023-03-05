#requires -psedition Core

trap {
    Read-Host -Prompt "TRAPPED!  Press enter to exit. ($_)"
}

. "$PSScriptRoot\winget.ps1"

# Scott Hanselman's setupmachine.bat.
#https://gist.githubusercontent.com/shanselman/6b91a78a2db92b81dd07cb28534ee875/raw/f5db11be9d6bc312824f4d1d83a009bfacdc3d38/setupmachine.bat

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
    $envMachinePath = [System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::Machine)
    if ($envMachinePath -split ';' -notcontains $installDir) {
        [Environment]::SetEnvironmentVariable('PATH', "$envMachinePath;$installDir", [System.EnvironmentVariableTarget]::Machine)
    }
    Remove-Item -Path op.zip

    Write-Host "Installed 1Password CLI."
}


# function Add-AppxPackageFromUrl {
#     param(
#         [Parameter(Mandatory = $true)]
#         [Uri]$Uri,
#         [string]$Name
#     )
#     $FileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($Uri)
#     $Extension = [System.IO.Path]::GetExtension($Uri)
#     $TempFile = "$([System.IO.Path]::GetTempPath())/${FileNameWithoutExtension}_$([guid]::NewGuid())$Extension"
    
#     Write-Host "Downloading $Name..."
#     (New-Object System.Net.WebClient).DownloadFile($Uri, $TempFile)
#     Write-Host "Downloaded $Name."

#     Write-Host "Installing $Name..."
#     Add-AppxPackage $TempFile
#     Write-Host "Installed $Name."

#     Remove-Item $TempFile
# }

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

    Set-PSDebug -Trace 1
    
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
            
    Install-WingetAndTools
    Install-Fonts
    Install-1PasswordCli

    Write-Host "Installed apps."
}

Main