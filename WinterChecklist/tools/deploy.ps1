<#
  deploy.ps1
  Wrapper for publish.ps1
  - Env defaults for AddOnsDir
  - Calls publish for build/install
  - Ensures destination has EXACTLY ONE TOC named <ADDON_NAME>.toc
#>

param(
  [ValidateSet('Retail','ClassicEra')]
  [string]$Flavor = 'ClassicEra',
  [switch]$Install,
  [string]$AddOnsDir,
  [string]$Toc
)

$ErrorActionPreference = 'Stop'

$Here    = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Path $MyInvocation.MyCommand.Path -Parent }
$Publish = Join-Path -Path $Here -ChildPath 'publish.ps1'
if (-not (Test-Path -LiteralPath $Publish)) { throw "publish.ps1 not found at: $Publish" }

$AddonName = if ($env:ADDON_NAME) { $env:ADDON_NAME } else { 'WinterChecklist' }

# Resolve AddOnsDir default if needed
if ($Install -and -not $AddOnsDir) {
  $AddOnsDir = if ($Flavor -eq 'Retail') { $env:WOW_DIR_RETAIL } else { $env:WOW_DIR_CLASSIC }
}
if ($Install -and -not $AddOnsDir) {
  throw "AddOnsDir not provided and no default found in env (WOW_DIR_RETAIL / WOW_DIR_CLASSIC)."
}

# Forward to publish.ps1
$pubArgs = @('-File', $Publish, '-Flavor', $Flavor)
if ($Install)   { $pubArgs += @('-Install', '-AddOnsDir', $AddOnsDir) }
if ($Toc)       { $pubArgs += @('-Toc', $Toc) }
& "$PSHOME\powershell.exe" -NoProfile -ExecutionPolicy Bypass @pubArgs
$exit = $LASTEXITCODE
if ($exit -ne 0) { exit $exit }

# Post-install: guarantee ONLY one TOC exists named <ADDON_NAME>.toc
if ($Install) {
  $dest = Join-Path -Path $AddOnsDir -ChildPath $AddonName
  if (-not (Test-Path -LiteralPath $dest)) { New-Item -ItemType Directory -Force -Path $dest | Out-Null }

  # If there's no base-named TOC yet, try to copy from repo
  $baseToc = Join-Path -Path $dest -ChildPath ($AddonName + '.toc')
  if (-not (Test-Path -LiteralPath $baseToc)) {
    $repoRoot = Split-Path -Path $Here -Parent
    $cand = @("$AddonName.toc", "${AddonName}_ClassicEra.toc", "${AddonName}_Classic.toc") |
      ForEach-Object { Join-Path -Path $repoRoot -ChildPath $_ } |
      Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if ($cand) { Copy-Item -LiteralPath $cand -Destination $baseToc -Force }
  }

  # Remove any other .toc variants
  Get-ChildItem -LiteralPath $dest -Filter '*.toc' |
    Where-Object { $_.Name -ne ($AddonName + '.toc') } |
    Remove-Item -Force -ErrorAction SilentlyContinue

  Write-Host "Deploy verified: single TOC $($AddonName + '.toc') in $dest"
}
