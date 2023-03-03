$InTheSandbox = $env:USERNAME -eq 'WDAGUtilityAccount'

if ($InTheSandbox) {
    $LogDir = [System.IO.Path]::GetFullPath("$PSScriptRoot/../../../logs")
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    & explorer $LogDir
}

. "$PSScriptRoot/../Run.ps1"

Run `
    -File ([System.IO.Path]::GetFullPath("$PSScriptRoot/../../../install.ps1")) `
    -LogSlug 'test-windows-local' `
    -AsAdministrator
