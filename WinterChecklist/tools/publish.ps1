param(
  [ValidateSet("Retail","ClassicEra")] [string]$Flavor = "Retail",
  [switch]$Install,
  [string]$AddOnsDir
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$AddonName = "WinterChecklist"
$OutDir   = Join-Path $RepoRoot "dist"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

# Pick the TOC for the flavor
$TocFile = if ($Flavor -eq "Retail") {
  Join-Path $RepoRoot "WinterChecklist_Mainline.toc"
} else {
  Join-Path $RepoRoot "WinterChecklist_Vanilla.toc"
}

if (!(Test-Path $TocFile)) { throw "TOC not found: $TocFile" }

# Extract Version from TOC
$Version = (Select-String -Path $TocFile -Pattern '^\s*##\s*Version:\s*(.+)$').Matches.Groups[1].Value.Trim()
if (-not $Version) { $Version = (Get-Date -Format "yyyy.MM.dd.HHmm") }

# Stage into temp dir
$Stage = Join-Path ([System.IO.Path]::GetTempPath()) ("{0}-stage-{1}" -f $AddonName, [guid]::NewGuid().ToString("N"))
$StageAddon = Join-Path $Stage $AddonName
New-Item -ItemType Directory -Force -Path $StageAddon | Out-Null

# Files to include (adjust if you add more)
$include = @(
  "WinterChecklist.lua",
  "WinterChecklist_Mainline.toc",
  "WinterChecklist_Vanilla.toc",
  "LICENSE.txt",
  "README.md"
)
foreach ($rel in $include) {
  $src = Join-Path $RepoRoot $rel
  if (Test-Path $src) { Copy-Item $src -Destination $StageAddon -Force }
}

# Build zip
$ZipName = "{0}-v{1}-{2}.zip" -f $AddonName, $Version, $Flavor
$ZipPath = Join-Path $OutDir $ZipName
if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
Compress-Archive -Path (Join-Path $StageAddon '*') -DestinationPath $ZipPath -Force

Write-Host "Built: $ZipPath"

# Optional install to WoW AddOns
if ($Install) {
  if (-not $AddOnsDir) { throw "-Install requires -AddOnsDir '...\\Interface\\AddOns'" }
  if (!(Test-Path $AddOnsDir)) { throw "AddOns dir not found: $AddOnsDir" }
  $Target = Join-Path $AddOnsDir $AddonName
  if (Test-Path $Target) { Remove-Item $Target -Recurse -Force }
  New-Item -ItemType Directory -Force -Path $Target | Out-Null
  Copy-Item (Join-Path $StageAddon '*') -Destination $Target -Recurse -Force
  Write-Host "Installed to: $Target"
}

# Cleanup
Remove-Item $Stage -Recurse -Force
