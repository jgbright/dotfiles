$TempDir = mktemp -d
Push-Location $TempDir
grep -l transient_prompt ~/.poshthemes/*.omp.* | xargs -I '{}' cp "{}" $TempDir
Get-PoshThemes -Path $TempDir
