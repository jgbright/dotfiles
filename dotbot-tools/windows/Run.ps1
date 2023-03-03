function Get-PwshCommandName {
    $PwshExe = Get-Command pwsh -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
    if ($PwshExe) {
        return $PwshExe
    }
    
    $PwshPathCandidate = 'C:/Program Files/PowerShell/7/pwsh.exe'
    if (Test-Path $PwshPathCandidate) {
        return $PwshPathCandidate
    }

    return Get-Command Powershell -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
}

function Get-PwshCommandWithLog {
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = 'File', Mandatory = $true)]
        [string]
        $File,

        [Parameter(ParameterSetName = 'Command', Mandatory = $true)]
        [string]
        $Command,

        [string]$ScripParams,

        [Parameter(Mandatory = $true)]
        [string]$LogSlug,

        [datetime]$DateTime = ([DateTime]::Now)
    )

    if ($PsCmdlet.ParameterSetName -eq 'File') {
        $Command = "& '$File'"
    }
    else {
        $Command = "& {`n$Command`n}"
    }

    if ($ScripParams) {
        $Command += " $ScripParams"
    }

    $Timestamp = $DateTime.ToString("yyyy-MM-dd_HH-mm-ss-FFF")
    # $Command += " *>> ""$([System.io.path]::GetFullPath("$PSScriptRoot/../logs/$Timestamp.$Slug.log"))"""
    $Command += " *>&1 | Tee-Object ""$([System.io.path]::GetFullPath("$PSScriptRoot/../../logs/$Timestamp.$LogSlug.log"))"""

    $Command
}

function Run {
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = 'Self', Mandatory = $true)]
        [string]$Self,

        [Parameter(ParameterSetName = 'Self')]
        [string]$ScripParams,

        [Parameter(ParameterSetName = 'Command', Mandatory = $true)]
        [string]$Command,

        [Parameter(ParameterSetName = 'File', Mandatory = $true)]
        [string]$File,

        [switch]$AsAdministrator,
        [switch]$ShowWindow,
        [switch]$Wait,
        [string]$LogSlug,
        [string]$PwshCommandName = (Get-PwshCommandName)        
    )

    $CommandWithLogging = switch ($PsCmdlet.ParameterSetName) {
        'Self' {
            if ($Self) {
                $CommandWithoutLogging = $Self
                Get-PwshCommandWithLog -File $Self -LogSlug $LogSlug -ScripParams $ScripParams
            }
            else {
                # If the original command had logging, remove it.
                $CommandWithoutLogging = (Get-PSCallStack)[-1].Position.Text
                $LogCommandIndex = $CommandWithoutLogging.IndexOf(' *>&1 | Tee-Object "')
                if ($LogCommandIndex -gt 0) {
                    $CommandWithoutLogging = $CommandWithoutLogging.Substring(0, $LogCommandIndex)
                }
                Get-PwshCommandWithLog -Command $CommandWithoutLogging -LogSlug $LogSlug -ScripParams $ScripParams
            }
        }
        'Command' {
            $CommandWithoutLogging = $Command
            Get-PwshCommandWithLog -Command $Command -LogSlug $LogSlug -ScripParams $ScripParams
        }
        'File' {
            $CommandWithoutLogging = $File
            Get-PwshCommandWithLog -File $File -LogSlug $LogSlug -ScripParams $ScripParams
        }
    }

    $ShouldEncode = $true

    if ($ShouldEncode) {
        $Bytes = [System.Text.Encoding]::Unicode.GetBytes($CommandWithLogging)
        $EncodedCommand = [Convert]::ToBase64String($Bytes)
        Write-Host "EncodedCommand: $EncodedCommand"
        write-Host "OriginalCommand: $CommandWithLogging"
        $ArgumentList = "-EncodedCommand $EncodedCommand"
    }
    else {
        $ArgumentList = "-Command $CommandWithLogging"
    }

    $StartProcessArgs = @{
        FilePath     = $PwshCommandName
        ArgumentList = $ArgumentList
        Wait         = $Wait
    }

    if ($AsAdministrator) {
        $StartProcessArgs['Verb'] = 'RunAs'
    }
    else {
        $StartProcessArgs['NoNewWindow'] = !$ShowWindow
    }

    Write-Host "Start-Process $($StartProcessArgs | ConvertTo-Json -Depth 99)"
    Start-Process @StartProcessArgs
}
