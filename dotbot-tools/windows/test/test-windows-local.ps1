# # Open the task scheduler so we can troubleshoot continuations.
# & taskschd.msc

# # Open the current folder in explorer.
# & explorer $PSScriptRoot

. "$PSScriptRoot/../Run.ps1"

Run `
    -File ([System.IO.Path]::GetFullPath("$PSScriptRoot/../../../install.ps1")) `
    -LogSlug 'test-windows-local' `
    -AsAdministrator
