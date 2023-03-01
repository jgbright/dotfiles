function Cleanse-Filename {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [string]
        $Filename,

        [string]$Replacement = '_'
    )

    $Filename.Split([IO.Path]::GetInvalidFileNameChars()) -join $Replacement
}

function Cleanse-ScheduledTaskName {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [string]
        $ScheduledTaskName,

        [string]$Replacement = '_'
    )

    $ScheduledTaskName -Replace '[^a-zA-Z0-9/./-]', $Replacement
}

function Get-PwshCommandName {
    $PwshPathCandidate = 'C:/Program Files/PowerShell/7/pwsh.exe'

    $PwshExe = Get-Command pwsh -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
    if ($PwshExe) {
        return $PwshExe
    }

    if (Test-Path $PwshPathCandidate) {
        return $PwshPathCandidate
    }

    return Get-Command Powershell -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
}


$TaskNameCounter = 1

$LogFileCount = 0

function Invoke-Later {
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = 'File', Mandatory = $true)]
        [string]
        $File,

        [Parameter(ParameterSetName = 'Command', Mandatory = $true)]
        [string]
        $Command,

        [string]$NextLogFileSlug,
        [switch]$ScheduledTask,
        [switch]$RunAsAdministrator,
        [switch]$DisableCommandEncoding,
        [string]$PwshCommandName,
        [switch]$DisableLogging,
        [TimeSpan]$Delay = [TimeSpan]::FromSeconds(10),
        [string]$TaskName = "",
        [string]$Description = ""
    )

    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $IsAdministrator = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    Write-Host "[Invoke-Later] IsAdministrator: $IsAdministrator"

    if ($PSCmdlet.ParameterSetName -eq 'File') {
        Write-Host "[Invoke-Later] File: $File"
    }
    else {
        Write-Host "[Invoke-Later] Command: $Command"
    }
    Write-Host "[Invoke-Later] NextLogFileSlug: $NextLogFileSlug"
    Write-Host "[Invoke-Later] DisableCommandEncoding: $DisableCommandEncoding"
    Write-Host "[Invoke-Later] PwshCommandName: $PwshCommandName"
    Write-Host "[Invoke-Later] DisableLogging: $DisableLogging"
    Write-Host "[Invoke-Later] Delay: $Delay"
    Write-Host "[Invoke-Later] TaskName: $TaskName"
    Write-Host "[Invoke-Later] Description: $Description"

    if (!$PwshCommandName) {
        $PwshCommandName = Get-PwshCommandName
    }

    if (!$TaskName) {
        $StackFrame = (Get-PSCallStack)[1]
        if ($StackFrame.FunctionName.Trim() -eq '<ScriptBlock>') {
            if ($StackFrame.ScriptName) {
                $TaskName = [System.IO.Path]::GetFileName($StackFrame.ScriptName) | Cleanse-ScheduledTaskName
            }
        }
        else {
            $TaskName = $StackFrame.FunctionName | Cleanse-ScheduledTaskName
        }
        if (!$TaskName) {
            $TaskName = "jgbright-dotfiles"
        }
        $TaskName += "-$TaskNameCounter"
        $TaskNameCounter++

        $Description = 
        @"
$(if ($File) { $File } else { $Command })
Get-PSCallStack -Verbose
$(Get-PSCallStack -Verbose)

Get-PSCallStack | Format-List
$(Get-PSCallStack | Format-List | Out-String)

Get-PSCallStack | Format-Table -AutoSize
$(Get-PSCallStack | Format-Table -AutoSize | Out-String)
"@

        Get-PSCallStack | Format-List | Out-String | Write-Host
    }

    $TriggerAt = [DateTime]::Now.Add($Delay)

    $Suffix = ""
    if (!$DisableLogging) {
        $LogFileCount++
        $Timestamp = $TriggerAt.ToString("yyyy-MM-dd_HH-mm-ss-FFF")
        $Slug = $NextLogFileSlug
        if (!$Slug) {
            $Slug = $TaskName | Cleanse-Filename
        }
        # $Suffix = " *>> ""$([System.io.path]::GetFullPath("$PSScriptRoot/../logs/$Timestamp.$Slug.log"))"""
        $Suffix = " *>&1 | Tee-Object ""$([System.io.path]::GetFullPath("$PSScriptRoot/../../logs/$Timestamp.$Slug.log"))"""
    }

    $FileOrCommand = ""
    if ($PsCmdlet.ParameterSetName -eq 'File') {
        # Write-Host "Scheduling file to run later: $File"

        $Command = "& '$File'$Suffix"
        
        # Write-Host "Scheduling command to run later:"
        # Write-Host $Command
    }
    else {
        # Write-Host "Scheduling command to run later:"
        # Write-Host $Command
        $Command = "& {`n$Command`n}$Suffix"
        # Write-Host $Command
    }

    if ($DisableCommandEncoding) {
        $FileOrCommand = "-Command $Command"
    }
    else {
        $Bytes = [System.Text.Encoding]::Unicode.GetBytes($Command)
        $EncodedCommand = [Convert]::ToBase64String($Bytes)
        # Write-Host "EncodedCommand: $EncodedCommand"

        $FileOrCommand = "-EncodedCommand $EncodedCommand"
    }

    Write-Host "PwshCommandName: $PwshCommandName"
    Write-Host "FileOrCommand: $FileOrCommand"
    # Write-Host "Suffix: $Suffix"
    
    # $RunAsArg = ""
    # if ($RunAsAdministrator -and $PwshCommandName -like '*pwsh*') {
    #     $RunAsArg = " -Verb RunAs"
    # }

    if ($ScheduledTask) {
        $Action = New-ScheduledTaskAction `
            -Execute $PwshCommandName `
            -Argument "-ExecutionPolicy Bypass $FileOrCommand" `
            -Verbose

        $Trigger = New-ScheduledTaskTrigger `
            -Once `
            -At $TriggerAt

        $RegisterScheduledTaskArgs = @{}
        if ($RunAsAdministrator) {
            $RegisterScheduledTaskArgs.RunLevel = 'Highest'
        }

        Write-Host "TaskName: $TaskName"
        Register-ScheduledTask `
            -Action $Action `
            -Trigger $Trigger `
            -TaskName "$TaskName-$([Guid]::NewGuid())" `
            -Description $Description `
            @RegisterScheduledTaskArgs
    }
    else {
        $StartProcessArgs = @{}
        if ($RunAsAdministrator) {
            $StartProcessArgs['Verb'] = 'RunAs'
        }
        Start-Process `
            -FilePath $PwshCommandName `
            -ArgumentList "-ExecutionPolicy Bypass $FileOrCommand" `
            -Wait `
            -NoNewWindow `
            @StartProcessArgs
    }

    try {
        # This will fail in powershell.exe, but not pwsh.exe.  We don't really care, since this is just a convenience function.
        Start-Sleep -Duration $Delay
    }
    catch {}
}

# function HappyCaller {
#     Invoke-Later -Command 'Write-Host "Hello, world!"'
# }

# HappyCaller
