@powershell ^
    -ExecutionPolicy Bypass ^
    -Command ". '%~dp0..\Invoke-Later.ps1'; Invoke-Later -DisableCommandEncoding -File '%~dp0test-windows-github.ps1'"
