[CmdletBinding()]
param (
    [Parameter()]
    [ValidateSet('Local', 'GitHub')]
    [string]
    $Source = 'Local'
)

#requires -psedition Core

# If we are going to install the Sandbox feature for the user, this script will require elevation during the install.
# Enable-WindowsOptionalFeature -Online -FeatureName:Containers-DisposableClientVM -NoRestart:$True

if ($Source -eq 'Local') {
    & "$PSScriptRoot/test-windows-local.wsb"
}
else {
    & "$PSScriptRoot/test-windows-github.wsb"
}
