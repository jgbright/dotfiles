$ErrorActionPreference = 'Stop'

function Resolve-Error ($ErrorRecord = $Error[0]) {
    $ErrorRecord | Format-List * -Force
    $ErrorRecord.InvocationInfo | Format-List *
    $Exception = $ErrorRecord.Exception
    for ($i = 0; $Exception; $i++, ($Exception = $Exception.InnerException)) {
        "$i" * 80
        $Exception | Format-List * -Force
    }
}

trap {
    Write-Host -NoNewline "Error! "
    Resolve-Error $_
}

# Push-Location $TempDir

$ThemesUrl = 'https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip'
$PoshThemesTempDir = "$home/.local/tmp/poshthemes"
Remove-Item $PoshThemesTempDir -Recurse -Force -ErrorAction SilentlyContinue
$ThemesZipFile = "$PoshThemesTempDir/themes.zip"
$AllThemesDir = "$PoshThemesTempDir/all-themes"
$TransientThemesDir = "$PoshThemesTempDir/transient-themes"

$AllThemesDir, $TransientThemesDir | ForEach-Object {
    New-Item -ItemType Directory -Path $PoshThemesTempDir -Force | Out-Null
}

(New-Object System.Net.WebClient).DownloadFile($ThemesUrl, $ThemesZipFile)
Expand-Archive -Path $ThemesZipFile -DestinationPath $AllThemesDir

if (Get-Command Get-PoshThemes -ErrorAction SilentlyContinue) {
    Get-PoshThemes -Path $AllThemesDir
}

# code .

Write-Host "Have fun exploring the themes here: $PoshThemesTempDir"
Write-Host "When you're done, clean up with this: rm -rf '$PoshThemesTempDir'"

# grep -l transient_prompt $ThemesDir/*.omp.* | xargs -I '{}' cp "{}" $TempDir
# Get-PoshThemes -Path $TempDir

# Get temp dir in xplat way
# https://stackoverflow.com/a/45136638/323416
# $TempDir = [System.IO.Path]::GetTempPath()
# $TempDir = [System.IO.Path]::GetTempFileName()
# $TempDir = [System.IO.Path]::GetTempPath()
# $TempDir = [System.IO.Path]::GetTempFileName()
