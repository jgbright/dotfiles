$ErrorActionPreference = "Stop"

function Resolve-Error ($ErrorRecord=$Error[0])
{
   $ErrorRecord | Format-List * -Force
   $ErrorRecord.InvocationInfo |Format-List *
   $Exception = $ErrorRecord.Exception
   for ($i = 0; $Exception; $i++, ($Exception = $Exception.InnerException))
   {   "$i" * 80
       $Exception |Format-List * -Force
   }
}

trap {
    Read-Host -Prompt "TRAPPED!  Press enter to exit. ($_)`n$(Resolve-Error $_ | Out-String)"
}

$InTheSandbox = $env:USERNAME -eq 'WDAGUtilityAccount'

if ($InTheSandbox) {
    $LogDir = [System.IO.Path]::GetFullPath("$PSScriptRoot\..\..\..\logs")
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    & explorer $LogDir
}

. "$PSScriptRoot\..\Run.ps1"

$File = [System.IO.Path]::GetFullPath("$PSScriptRoot\..\..\..\install.ps1")
Write-Host "File: $File"

Run `
    -File $File `
    -LogSlug 'test-windows-local' `
    -AsAdministrator
