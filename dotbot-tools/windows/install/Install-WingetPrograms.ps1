Set-StrictMode -Version 3.0

$InstalledSoftware = @()

function Install-WingetProgram {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(ValueFromPipeline, ParameterSetName = "Pipeline", Mandatory)]
        [object[]]
        $Programs,

        [Parameter(ParameterSetName = "Parameters", Mandatory)]
        [string]
        $Id,
        
        [Parameter(ParameterSetName = "Parameters")]
        [string]
        $Version,
        
        [Parameter(ParameterSetName = "Parameters")]
        [string]
        $Source,
        
        [Parameter(ParameterSetName = "Parameters")]
        [string]
        $Override
    )

    Process {
        if ($PSCmdlet.ParameterSetName -eq 'Parameters') {
            $Program = @{
                Id = $Id
            }
            if ($Version) {
                $Program.Version = $Version
            }
            if ($Source) {
                $Program.Source = $Source
            }
            if ($Override) {
                $Program.Override = $Override
            }
            $PipelineInput = @($Program)
        } 
        else {
            $PipelineInput = $Programs
        }

        $PipelineInput `
        | ForEach-Object {
            $IsString = $_ -is [string]

            if ($_ -is [hashtable]) {
                $Program = [PSCustomObject]$_
            }
            else {
                $Program = $_
            }

            $Id = if ($IsString) { $Program } else { $Program.Id }
            $Version = if ((-not $IsString) -and ($Program | Get-Member Version)) { $Program.Version }
            $Source = if ($IsString) { 'winget' } else { $Program.Source }
            $Override = if ((-not $IsString) -and ($Program | Get-Member Override)) { $Program.Override }

            Write-Host "Id: $Id"
            Write-Host "Version: $Version"
            Write-Host "Source: $Source"
            Write-Host "Override: $Override"

            if ($InstalledSoftware | Where-Object ID -eq $Id) {
                Write-Host "Upgrading $Id..."

                $WingetArgs = @()
                $WingetArgs += 'upgrade'

                $WingetArgs += @(
                    '--id',
                    $Id ,
                    "--source=$Source",
                    '--accept-package-agreements',
                    '--accept-source-agreements',
                    '--silent'
                )

                # Echo command for troubleshooting.
                Write-Host "> winget $WingetArgs"
                if ($PSCmdlet.ShouldProcess($Id, "Upgrading")) {
                    winget @WingetArgs
                }

                Write-Host "Upgraded $Id."
            }
            else {
                Write-Host "Installing $Id..."

                $WingetArgs = @()
                $WingetArgs += 'install'

                if (!$Source) {
                    throw "error, invalid winget data: $Id"
                }

                $WingetArgs += '--id', $Id
                if ($Source) {
                    $WingetArgs += '--source', $Source
                }
                if ($Version) {
                    $WingetArgs += '--source', $Version
                }
                $WingetArgs += @(
                    '--accept-package-agreements',
                    '--accept-source-agreements',
                    '--silent'
                )
                if ($Override) {
                    $WingetArgs += '--override', $Override
                }
                
                # Echo command for troubleshooting.
                Write-Host "> winget $WingetArgs"
                if ($PSCmdlet.ShouldProcess($Id, "Installing")) {
                    winget @WingetArgs
                }

                Write-Host "Installed $Id."
            }
        }
    }
}



@{
    Id       = 'Microsoft.VisualStudioCode'
    Source   = 'winget'
    Override = '/SILENT /mergetasks="!runcode,addcontextmenufiles,addcontextmenufolders"'
} | Install-WingetProgram -WhatIf | Format-List


# @{
#     Id       = 'Microsoft.VisualStudioCode'
#     Source   = 'winget'
#     Override = '/SILENT /mergetasks="!runcode,addcontextmenufiles,addcontextmenufolders"'
# },
# @{
#     Id     = 'Microsoft.WindowsTerminal'
#     Source = 'msstore'
# },
# 'Microsoft.DotNet.SDK.6',
# 'Microsoft.PowerShell' | Install-WingetProgram -WhatIf | Format-List