param([string]$AddOnsDir, [string]$AddonName = 'WinterChecklist')
$dest = Join-Path -Path $AddOnsDir -ChildPath $AddonName
Write-Host "Contents of $dest:"
Get-ChildItem -Recurse -Force $dest | Select-Object FullName, Length | Format-Table -AutoSize
