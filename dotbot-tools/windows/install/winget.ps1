Set-StrictMode -Version 3.0

<#
Install winget using the WingetTools pwsh module.
https://github.com/jdhitsolutions/WingetTools
#>
function Install-WingetAndTools {
    $PreviousProgressPreference = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'

    try {
        if (!(Get-PackageProvider | Where-Object Name -eq NuGet)) {
            Write-Host "Installing NuGet pwsh package provider..."
            Get-PackageProvider NuGet -ForceBootstrap | Out-Null
            Write-Host "Installed NuGet pwsh package provider."
        }

        if (!(Get-InstalledModule -Name WingetTools -ErrorAction SilentlyContinue)) {
            Write-Host "Installing WingetTools..."
            Install-Module WingetTools -Scope CurrentUser -Force
            Write-Host "Installed WingetTools."
        }

        if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
            Write-Host "Installing winget..."
            Install-WinGet
            Write-Host "Installed winget."
        }
    }
    finally {
        $ProgressPreference = $PreviousProgressPreference
    }

    # Below is an another way to install winget that uses Add-AppxPackageFromUrl.

    # Add-AppxPackageFromUrl https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx
    # Add-AppxPackageFromUrl https://github.com/microsoft/winget-cli/releases/download/v1.3.2691/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle


    # Install Terminal


    # irm https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -o Microsoft.VCLibs.appx
    # Add-AppxPackage .\Microsoft.VCLibs.appx
    # Remove-Item .\Microsoft.VCLibs.appx


    # $url = "https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.8.2"
    # $zipFile = "Microsoft.UI.Xaml.2.8.2.nupkg.zip"
    # Invoke-WebRequest https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.8.2 -OutFile Microsoft.UI.Xaml.2.8.2.zip
    # Expand-Archive Microsoft.UI.Xaml.2.8.2.zip
    # Add-AppxPackage ".\Microsoft.UI.Xaml.2.8.2\tools\AppX\x64\Release\Microsoft.UI.Xaml.2.8.appx" -ErrorAction SilentlyContinue


    # $url = "https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.7.3"
    # $zipFile = "Microsoft.UI.Xaml.2.7.3.nupkg.zip"
    # Invoke-WebRequest https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.7.3 -OutFile Microsoft.UI.Xaml.2.7.3.zip
    # Expand-Archive Microsoft.UI.Xaml.2.7.3.zip
    # Add-AppxPackage ".\Microsoft.UI.Xaml.2.7.3\tools\AppX\x64\Release\Microsoft.UI.Xaml.2.7.appx" -ErrorAction SilentlyContinue

    # irm https://github.com/microsoft/terminal/releases/download/v1.16.10261.0/Microsoft.WindowsTerminal_Win11_1.16.10262.0_8wekyb3d8bbwe.msixbundle -o Microsoft.WindowsTerminal_Win11_1.msixbundle
    # Add-AppxPackage .\Microsoft.WindowsTerminal_Win11_1.msixbundle
    # Remove-Item .\Microsoft.WindowsTerminal_Win11_1.msixbundle


    # Add-AppxPackage https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx
    # Add-AppxPackage https://github.com/microsoft/terminal/releases/download/v1.16.10261.0/Microsoft.WindowsTerminal_Win11_1.16.10262.0_8wekyb3d8bbwe.msixbundle
    # Add-AppxPackageFromUrl https://github.com/microsoft/winget-cli/releases/download/v1.3.2691/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle

}

function Install-WingetProgram {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(ValueFromPipeline, ParameterSetName = "Pipeline", Mandatory)]
        [object[]]
        $Programs,

        [Parameter(ParameterSetName = "Pipeline")]
        [Parameter(ParameterSetName = "Parameters")]
        [object[]]
        $InstalledPrograms,

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
        [ValidateSet('user', 'machine')]
        [string]
        $Scope = 'user',

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
            if ($Scope) {
                $Program.Scope = $Scope
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
            $Source = if ((-not $IsString) -and ($Program | Get-Member Source)) { $Program.Source } else { 'winget' }
            $Scope = if ((-not $IsString) -and ($Program | Get-Member Scope)) { $Program.Scope } else { 'user' }
            $Override = if ((-not $IsString) -and ($Program | Get-Member Override)) { $Program.Override }

            Write-Host "Id: $Id"
            Write-Host "Version: $Version"
            Write-Host "Source: $Source"
            Write-Host "Scope: $Scope"
            Write-Host "Override: $Override"

            if ($InstalledPrograms | Where-Object Id -eq $Id) {
                Write-Host "Upgrading $Id..."

                $WingetArgs = @()
                $WingetArgs += 'upgrade'

                $WingetArgs += @(
                    '--id',
                    $Id ,
                    '--accept-package-agreements',
                    '--accept-source-agreements',
                    '--silent'
                )

                if ($Source){
                    $WingetArgs += "--source", $Source
                }

                # Echo command text for troubleshooting.
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

                if (!$Id) {
                    throw "error, invalid winget data: $Id"
                }

                $WingetArgs += '--id', $Id
                if ($Source) {
                    $WingetArgs += '--source', $Source
                }
                if ($Version) {
                    $WingetArgs += '--version', $Version
                }
                $WingetArgs += @(
                    '--accept-package-agreements',
                    '--accept-source-agreements',
                    '--silent'
                )

                if ($Scope){
                    $WingetArgs += "--scope", $Scope
                }
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
