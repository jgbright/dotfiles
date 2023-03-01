@REM @powershell ^
@REM     -ExecutionPolicy Bypass ^
@REM     -Command Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope User -Force

@powershell ^
    -ExecutionPolicy Bypass ^
    -File "%~dp0test-windows-local.ps1"

    @REM -Command . '%~dp0Invoke-Later.ps1'; Invoke-Later -NextLogFileSlug 'install.ps-first-run' -File '%~dp0..\install.ps1' -DisableCommandEncoding -ScheduledTask -RunAsAdministrator
