<<<<<<< HEAD
# Open the task scheduler so we can troubleshoot continuations.
& taskschd.msc

# Open the current folder in explorer.
& explorer $PSScriptRoot

. "$PSScriptRoot/../Invoke-Later.ps1"

Invoke-Later `
    -File ([System.IO.Path]::GetFullPath("$
    /../../../install.ps1")) `
    -DisableCommandEncoding `
    -NextLogFileSlug 'install.ps1-test-windows-local' `
    -ScheduledTask `
    -RunAsAdministrator
=======
# # Open the task scheduler so we can troubleshoot continuations.
# & taskschd.msc

# # Open the current folder in explorer.
# & explorer $PSScriptRoot

. "$PSScriptRoot/../Run.ps1"

Run `
    -File ([System.IO.Path]::GetFullPath("$PSScriptRoot/../../../install.ps1")) `
    -LogSlug 'test-windows-local' `
    -AsAdministrator
>>>>>>> 612f5670e113a023876d445c9bdeec103333ba2f
