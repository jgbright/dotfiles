# # Open the task scheduler so we can troubleshoot continuations.
# & taskschd.msc

# # Open the current folder in explorer.
# & explorer $PSScriptRoot

. "$PSScriptRoot/../Invoke-Later.ps1"

Invoke-Later `
    -File ([System.IO.Path]::GetFullPath("$PSScriptRoot/../../../install.ps1")) `
    -NextLogFileSlug 'install.ps1-test-windows-local' `
    -ScheduledTask `
    -RunAsAdministrator
    
    # -DisableCommandEncoding `
