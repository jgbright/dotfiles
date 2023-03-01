param([switch]$Elevated)

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

function SelfElevate {
    if ((Test-Admin) -eq $false)  {
        if ($elevated) {
            # tried to elevate, did not work, aborting
        } else {
            $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source

#             Write-Host @"
# Start-Process `
#     -FilePath "$pwsh" `
#     -ArgumentList $('-noprofile -noexit -file "{0}" -elevated' -f ($PSCommandPath)) `
#     -Verb RunAs
# "@
            Start-Process `
                -FilePath $pwsh `
                -ArgumentList ('-NoProfile -NoExit -File "{0}" -Elevated' -f ($PSCommandPath)) `
                -Verb RunAs
        }
        exit
    }
}

SelfElevate

. "${env:DOTFILES_DIR}\dotbot-tools\windows\Invoke-Later.ps1"

Invoke-Later `
    -File "${env:DOTFILES_DIR}\install.ps1" `
    -ScheduledTask `
    -RunAsAdministrator
