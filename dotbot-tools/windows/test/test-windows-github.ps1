# Open the task scheduler so we can troubleshoot continuations.
& taskschd.msc

# Open the current folder in explorer.
& explorer $PSScriptRoot

. "$PSScriptRoot/../Invoke-Later.ps1"

Invoke-Later `
    -DisableCommandEncoding `
    -NextLogFileSlug 'install.ps1-github-first-run' `
    -RunAsAdministrator `
    -Command "Invoke-RestMethod ""https://raw.githubusercontent.com/jgbright/dotfiles/main/install.ps1?random-seed=$(Get-Random)"" | Invoke-Expression"

    # -File ([System.IO.Path]::GetFullPath("$PSScriptRoot/../../../install.ps1"))


# if ($false) {
#     . $PSScriptRoot/dotbot-tools/Invoke-Later.ps1
# }
# else {
#     Write-Host "Downloading Invoke-Later.ps1..."
#     # Invoke-Expression ". { $(Invoke-RestMethod https://raw.githubusercontent.com/jgbright/dotfiles/main/dotbot-tools/Invoke-Later.ps1) }"

    

#     # Invoke-RestMethod https://raw.githubusercontent.com/jgbright/dotfiles/main/dotbot-tools/Invoke-Later.ps1 | Invoke-Expression
#     (New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/jgbright/dotfiles/main/dotbot-tools/Invoke-Later.ps1') | Invoke-Expression
#     Write-Host "Downloaded Invoke-Later.ps1."
# }

# Robocopy.exe `
#     /e `
#     C:/Users\WDAGUtilityAccount\dotfiles-readonly `
#     C:\Users\WDAGUtilityAccount\dotfiles

# Invoke-Later `
#     -DisableCommandEncoding `
#     -Command "(New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/jgbright/dotfiles/main/install-remote.ps1') | Invoke-Expression"
#     # -Command "Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/jgbright/dotfiles/main/install-remote.ps1' | Invoke-Expression"


# # Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/jgbright/dotfiles/main/install-remote.ps1' | Invoke-Expression `
# #     *>> "$PSScriptRoot/../logs/$($TriggerAt.ToString("yyyy-MM-dd_hh-mm-ss-FFF")).test-windows-github.log"
