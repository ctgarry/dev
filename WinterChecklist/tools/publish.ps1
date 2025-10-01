<#
  publish.ps1
  - Stages in %TEMP% (avoids Dropbox/AV locks)
  - TOC-only build from the chosen .toc
  - Always stages EXACTLY ONE TOC named <ADDON_NAME>.toc
  - Optional install copies staged files to AddOns
#>

param(
  [ValidateSet('Retail','ClassicEra')]
  [string]$Flavor = 'ClassicEra',
  [switch]$Install,
  [string]$AddOnsDir,
  [string]$Toc  # optional explicit override
)

$ErrorActionPreference = 'Stop'

# Robust path resolution
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Path $MyInvocation.MyCommand.Path -Parent }
$RepoRoot  = Split-Path -Path $ScriptDir -Parent

# Addon name from env (fallback)
$AddonName = if ($env:ADDON_NAME) { $env:ADDON_NAME } else { 'WinterChecklist' }

function Resolve-Toc {
  param([string]$RepoRoot, [string]$Flavor, [string]$AddonName)
  if ($Flavor -eq 'Retail') {
    $candidates = @("$AddonName.toc")
  } else {
    $candidates = @("${AddonName}_ClassicEra.toc", "${AddonName}_Classic.toc")
  }
  foreach ($c in $candidates) {
    $p = Join-Path -Path $RepoRoot -ChildPath $c
    if (Test-Path -LiteralPath $p) { return $p }
  }
  throw "TOC not found for $Flavor. Tried: $($candidates -join ', ')"
}

# Locate TOC
if ($Toc) {
  $TocPath = if ([System.IO.Path]::IsPathRooted($Toc)) { $Toc } else { Join-Path -Path $RepoRoot -ChildPath $Toc }
  if (-not (Test-Path -LiteralPath $TocPath)) { throw "Specified -Toc not found: $TocPath" }
} else {
  $TocPath = Resolve-Toc -RepoRoot $RepoRoot -Flavor $Flavor -AddonName $AddonName
}

# Parse TOC into file list (ignore comments/metadata/blank)
$raw = Get-Content -LiteralPath $TocPath -ErrorAction Stop
$files = $raw |
  Where-Object { $_ -and $_ -notmatch '^\s*(#|//|;|##|\s*$)' } |
  ForEach-Object { $_.Split('#')[0].Trim() } |
  Where-Object { $_ -ne '' }

# Version from TOC or timestamp
$Version = ($raw | Where-Object { $_ -match '^\s*##\s*Version\s*:\s*(.+)$' } |
  ForEach-Object { ($Matches[1]).Trim() } | Select-Object -First 1)
if ([string]::IsNullOrWhiteSpace($Version)) { $Version = (Get-Date -Format 'yyyy.MM.dd.HHmm') }

# Stage in %TEMP%
$stageRootBase = Join-Path -Path $env:TEMP -ChildPath ("WCStage-{0}-{1}-{2}" -f $Flavor, $AddonName, [System.Guid]::NewGuid())
$stageRoot     = Join-Path -Path $stageRootBase -ChildPath $AddonName
New-Item -ItemType Directory -Force -Path $stageRoot | Out-Null

foreach ($rel in $files) {
  $src = Join-Path -Path $RepoRoot -ChildPath $rel
  if (-not (Test-Path -LiteralPath $src)) { Write-Warning "Missing from TOC: $rel"; continue }
  $dst = Join-Path -Path $stageRoot -ChildPath $rel
  New-Item -ItemType Directory -Force -Path (Split-Path -Path $dst) | Out-Null
  Copy-Item -LiteralPath $src -Destination $dst -Force
}

# ALWAYS stage exactly one TOC named <ADDON_NAME>.toc
$targetToc = Join-Path -Path $stageRoot -ChildPath ($AddonName + '.toc')
Copy-Item -LiteralPath $TocPath -Destination $targetToc -Force

# Build ZIP in dist/
$distDir = Join-Path -Path $RepoRoot -ChildPath "dist"
New-Item -ItemType Directory -Force -Path $distDir | Out-Null
$zipName = "$AddonName-v$Version-$Flavor.zip"
$zipPath = Join-Path -Path $distDir -ChildPath $zipName

function Invoke-WithRetry {
  param([scriptblock]$Script, [int]$Tries = 5, [int]$DelayMs = 200)
  for ($i=1; $i -le $Tries; $i++) {
    try { & $Script; return } catch { if ($i -eq $Tries) { throw }; Start-Sleep -Milliseconds ($DelayMs * $i) }
  }
}

Invoke-WithRetry { Remove-Item -LiteralPath $zipPath -Force -ErrorAction SilentlyContinue | Out-Null }
$stageGlob = Join-Path -Path $stageRoot -ChildPath '*'
Invoke-WithRetry { Compress-Archive -Path $stageGlob -DestinationPath $zipPath -CompressionLevel Optimal }
Write-Host "Built: $zipPath"

# Optional install
try {
  if ($Install) {
    if (-not $AddOnsDir) { throw "-Install requires -AddOnsDir" }
    $dest = Join-Path -Path $AddOnsDir -ChildPath $AddonName
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    Copy-Item -Path (Join-Path -Path $stageRoot -ChildPath '*') -Destination $dest -Recurse -Force

    # Ensure ONLY one TOC exists: <ADDON_NAME>.toc
    Get-ChildItem -LiteralPath $dest -Filter '*.toc' |
      Where-Object { $_.Name -ne ($AddonName + '.toc') } |
      Remove-Item -Force -ErrorAction SilentlyContinue

    Write-Host "Installed (TOC-only) to: $dest"
  }
}
finally {
  Remove-Item -LiteralPath $stageRootBase -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
}
