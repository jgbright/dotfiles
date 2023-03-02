trap {
    Read-Host -Prompt "TRAPPED!  Press enter to exit. ($_)"
}


Write-Host "PSCommandPath: $PSCommandPath"
# Write-Host "MyInvocation: $($MyInvocation | Format-List | Out-String)"
# Write-Host "MyInvocation.MyCommand: $($MyInvocation.MyCommand | Format-List | Out-String)"
if (!$PSCommandPath) {
    Write-Host "MyInvocation.MyCommand.Definition: $($MyInvocation.MyCommand.Definition)"
}

function Upgrade-All {
    winget upgrade `
        --all `
        --accept-source-agreements `
        --accept-package-agreements
}

function  Configure-Path {
    # Add ~/.local/bin to path if it's not already there.
    $BinDir = "$env:USERPROFILE\.local\bin"
    if ($env:PATH -notlike "*$BinDir*") {
        [Environment]::SetEnvironmentVariable("PATH", "$BinDir;$env:PATH", "User")
    }
}

function Configure-PwshExecutionPolicy {
    Write-Host "Configuring pwsh..."
    
    
    Write-Host "Configured pwsh."
}

function Configure-DotNetNugetSources {
    if ("$(dotnet nuget list source)" -like '*https://api.nuget.org/v3/index.json*') {
        Write-Host "Nuget sources already configured."
        return
    }

    Write-Host "Configuring nuget sources..."
    dotnet nuget add source https://api.nuget.org/v3/index.json -n nuget.org
    Write-Host "Configured nuget sources."
}

function Configure-Explorer {
    Write-Host "Configuring explorer..."

    # Show file extensions in explorer
    Set-ItemProperty `
        -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' `
        -Name 'HideFileExt' `
        -value 0 `
        -Force

    # Hide task view button in task bar
    Set-ItemProperty `
        -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' `
        -Name 'ShowTaskViewButton' `
        -value 0 `
        -Force

    # Hide desktop icons on desktop
    # Set-ItemProperty `
    #     -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" `
    #     -Name 'HideIcons' `
    #     -Value 1 `
    #     -Force

    # Hide search bar icons in task bar
    Set-ItemProperty `
        -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" `
        -Name 'SearchBoxTaskbarMode' `
        -Value 0 `
        -Force

    # Need to restart explorer in order to immediately apply changes.
    Stop-Process -ProcessName Explorer -Force

    Write-Host "Configured explorer."
}

function Configure-Vscode {
    Write-Host "Configuring vscode..."
    
    $SettingsChanged = $false

    $UserSettingsFile = "$env:APPDATA\Code\User\settings.json"
    if (Test-Path $UserSettingsFile) {
        $UserSettings = Get-Content -Raw $UserSettingsFile | ConvertFrom-Json
    }
    else {
        New-Item `
            -ItemType Directory `
            -Path ([System.IO.Path]::GetDirectoryName($UserSettingsFile)) `
            -Force | Out-Null
        $UserSettings = @{}
    }
    
    if ($UserSettings.'editor.fontFamily' -notcontains 'FiraCode NF') {
        $UserSettings.'editor.fontFamily' = "'FiraCode NF', Consolas, 'Courier New', monospace"
        $SettingsChanged = $true
    }

    if ($UserSettings.'terminal.integrated.defaultProfile.linux' -ne 'zsh') {
        $UserSettings.'terminal.integrated.defaultProfile.linux' = 'zsh'
        $SettingsChanged = $true
    }
    
    if ($SettingsChanged) {        
        $UserSettings | ConvertTo-Json | Set-Content $UserSettingsFile
    }
    
    Write-Host "Configured vscode."
}

function Configure-1Password {
}


function Configure-WindowsTerminal {
    $SettingsFile = "${env:LOCALAPPDATA}\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    if (!(Test-Path $SettingsFile)) {
        Write-Host "Windows Terminal config not found."

        wt pwsh -NoProfile -Command exit
        Start-Sleep -Seconds 5

        if (!(Test-Path $SettingsFile)) {
            Write-Host "Windows Terminal config not found - even after starting it."
    
            return
        }
    }

    $FontFace = 'FiraCode NF'
    if (Select-String -LiteralPath $SettingsFile -SimpleMatch -Pattern $FontFace -Quiet) {
        Write-Host "Windows Terminal already configured."
        return
    }
    
    $Settings = Get-Content -Raw $SettingsFile | ConvertFrom-Json -Depth 99
    # $Settings.profiles ??= @{}
    # $Settings.profiles.defaults ??= @{}
    # $Settings.profiles.defaults.fontFace = 'FiraCode NF'
    # $Settings.profiles.defaults.Add('fontFace', 'FiraCode NF')
    $Settings.profiles.defaults | Add-Member fontFace 'FiraCode NF'
    $Settings | ConvertTo-Json -Depth 99 | Set-Content $SettingsFile
}

function Install-DotnetSuggest {
    if (Get-Command dotnet-suggest -ErrorAction SilentlyContinue) {
        Write-Host "dotnet-suggest already installed."
        return
    }

    Write-Host "Installing dotnet-suggest..."
    dotnet tool install --global dotnet-suggest
    Write-Host "Installed dotnet-suggest."
}

function Configure-DotnetSuggest {
    $ConfigFile = $PROFILE.CurrentUserAllHosts
    if (!(Test-Path $ConfigFile)) {
        New-Item -ItemType Directory -Path ([System.IO.Path]::GetDirectoryName($ConfigFile)) -Force | Out-Null
        New-Item -ItemType File -Path $ConfigFile -Force | Out-Null
    }
    
    if (Select-String -LiteralPath $ConfigFile -SimpleMatch -Pattern 'DOTNET_SUGGEST_SCRIPT_VERSION' -Quiet) {
        Write-Host "Dotnet suggest already configured."
        return
    }
    
    $DotnetShimUrl = 'https://raw.githubusercontent.com/dotnet/command-line-api/main/src/System.CommandLine.Suggest/dotnet-suggest-shim.ps1'
    Invoke-RestMethod -Uri $DotnetShimUrl | Add-Content $ConfigFile
}

function Configure-OhMyPosh {
    $ConfigFile = $PROFILE.CurrentUserAllHosts
    if (!(Test-Path $ConfigFile)) {
        New-Item -ItemType Directory -Path ([System.IO.Path]::GetDirectoryName($ConfigFile)) -Force | Out-Null
        New-Item -ItemType File -Path $ConfigFile -Force | Out-Null
    }
    
    if (Select-String -LiteralPath $ConfigFile -SimpleMatch -Pattern 'oh-my-posh init pwsh' -Quiet) {
        Write-Host "Oh-my-posh already configured."
        return
    }
    
    @"
    
    # oh-my-posh
    # Uncomment one of these presets to get started.
    # docs: https://ohmyposh.dev/docs/installation/customize
    
    $(
        (
        Get-ChildItem `
        -File $env:POSH_THEMES_PATH `
        -Filter '*.omp.*' `
        | ForEach-Object {
                "# oh-my-posh init pwsh --config '$($_.FullName)' | Invoke-Expression"
            }
        ) -join "`n"
        )
"@ | Add-Content $ConfigFile
}

# function Configure-Starship {
#     $ConfigFile = $PROFILE.CurrentUserAllHosts
#     if (!(Test-Path ConfigFile)) {
#         New-Item -ItemType Directory -Path ([System.IO.Path]::GetDirectoryName($ConfigFile)) -Force | Out-Null
#         New-Item -ItemType File -Path $ConfigFile -Force | Out-Null
#     }
    
#     $Content = 'Invoke-Expression (&starship init powershell)'
#     if (Select-String -LiteralPath $ConfigFile -SimpleMatch -Pattern $ContentPattern -Quiet) {
#         Write-Host "Starship already configured."
#         return
#     }
#     $Content | Add-Content $ConfigFile
# }

function Disable-TaskBarSearch {
    # https://jdhitsolutions.com/blog/powershell/8424/hiding-taskbar-search-with-powershell/
    $splat = @{
        Path        = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'
        Name        = 'SearchBoxTaskbarMode'
        Value       = 0
        Type        = 'DWord'
        Force       = $True
        ErrorAction = 'Stop'
    }
    Set-ItemProperty @splat
}

function Disable-TaskBarTaskView {
    # https://jdhitsolutions.com/blog/powershell/8424/hiding-taskbar-search-with-powershell/
    $splat = @{
        Path        = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        Name        = 'ShowTaskViewButton'
        Value       = 0
        Type        = 'DWord'
        Force       = $True
        ErrorAction = 'Stop'
    }
    Set-ItemProperty @splat
}

function Main {
    Write-Host "Configuring apps..."

    Upgrade-All

    Configure-Path
    Configure-PwshExecutionPolicy
    Configure-DotNetNugetSources
    Install-DotnetSuggest
    Configure-DotnetSuggest
    Configure-Explorer
    Configure-Vscode
    Configure-1Password
    Configure-WindowsTerminal
    Configure-OhMyPosh

    # Configure-Starship

    Write-Host "Configured apps."
}
    
Main
