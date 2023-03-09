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

        [Parameter(Mandatory = $true)]
        [string]$LogSlug,

        [string]$ScriptParams,

        [datetime]$DateTime = ([DateTime]::Now)
    )

    if ($PsCmdlet.ParameterSetName -eq 'File') {
        $Command = "& { & '$File'"
        if ($ScriptParams) {
            $Command += " $ScriptParams"
        }
        $Command += " }"
    }
    else {
        if ($ScriptParams) {
            $Command = "& { $Command $ScriptParams }"
        }
        else {
            $Command = "& { $Command }"

        }
    }


    $Timestamp = $DateTime.ToString("yyyy-MM-dd_HH-mm-ss-FFF")
    # $Command += " *>> ""$([System.io.path]::GetFullPath("$PSScriptRoot/../logs/$Timestamp.$Slug.log"))"""
    $Command += " *>&1 | Tee-Object ""$([System.io.path]::GetFullPath("$PSScriptRoot/../../logs/$Timestamp.$LogSlug.log"))"""

    $Command
}

function Run {
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = 'Restart', Mandatory = $true)]
        [switch]$Restart,

        [Parameter(ParameterSetName = 'Command', Mandatory = $true)]
        [string]$Command,

        [Parameter(ParameterSetName = 'File', Mandatory = $true)]
        [string]$File,

        [string]$ScriptParams,

        [switch]$AsSeperateProcess,
        [switch]$AsAdministrator,
        [switch]$ShowWindow,
        [switch]$Wait,
        [string]$LogSlug,
        [string]$PwshCommandName = (Get-PwshCommandName)
        # [switch]$AsJob
    )

    $CommandWithLogging = switch ($PsCmdlet.ParameterSetName) {
        'Restart' {
            # If the original command had logging, remove it.
            $CommandWithoutLogging = (Get-PSCallStack)[-1].Position.Text
            $LogCommandIndex = $CommandWithoutLogging.IndexOf(' *>&1 | Tee-Object "')
            if ($LogCommandIndex -gt 0) {
                $CommandWithoutLogging = $CommandWithoutLogging.Substring(0, $LogCommandIndex)
            }
            Get-PwshCommandWithLog -Command $CommandWithoutLogging -LogSlug $LogSlug -ScriptParams $ScriptParams
        }
        'Command' {
            $CommandWithoutLogging = $Command
            Get-PwshCommandWithLog -Command $Command -LogSlug $LogSlug -ScriptParams $ScriptParams
        }
        'File' {
            $CommandWithoutLogging = $File
            Get-PwshCommandWithLog -File $File -LogSlug $LogSlug -ScriptParams $ScriptParams
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
        Wait         = [boolean]$Wait
        # AsJob             = [boolean]$AsJob
    }
    
    if ($AsAdministrator) {
        $StartProcessArgs['Verb'] = 'RunAs'
    }
    else {
        UseNewEnvironment = $true
        $StartProcessArgs['NoNewWindow'] = !$ShowWindow
    }
    Write-Host "Start-Process $($StartProcessArgs | ConvertTo-Json -Depth 99)"

    if ($AsSeperateProcess) {
        # Invoke-Command { & Start-Process @StartProcessArgs }
        Invoke-Command { Invoke-Expression $PS }
    }
    else {
        Start-Process @StartProcessArgs
    }
}

function RunPwshSoon {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, Mandatory)]
        [string]
        $Command,

        [timespan]
        $Delay = (New-TimeSpan -Seconds 5)
    )

    $Bytes = [System.Text.Encoding]::Unicode.GetBytes($Command)
    $EncodedCommand = [Convert]::ToBase64String($Bytes)

    $PwshExeArgs = @(
        '-ExecutionPolicy Bypass'
        '-NoProfile'
        '-WindowStyle Hidden'
        "-EncodedCommand $EncodedCommand"
    ) -join ' '

    Write-Host "Command: $Command"
    Write-Host "Invocation: pwsh $PwshExeArgs"

    $action = New-ScheduledTaskAction -Execute (Get-PwshCommandName) -Argument $PwshExeArgs
    $trigger = New-ScheduledTaskTrigger -Once -At ([DateTime]::Now.Add($Delay))
    # https://learn.microsoft.com/en-us/powershell/module/scheduledtasks/new-scheduledtasksettingsset?view=windowsserver2022-ps
    $settings = New-ScheduledTaskSettingsSet
    $task = New-ScheduledTask -Action $action -Trigger $trigger -Settings $settings
    Register-ScheduledTask 'RunPwshSoon' -InputObject $task -Force
}
