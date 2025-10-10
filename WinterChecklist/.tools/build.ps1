# .tools/build.ps1
Param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("retail","classic_era")]
  [string]$Flavor,

  [Parameter(Mandatory = $true)]
  [ValidateSet("zip","install")]
  [string]$Mode,

  # Optional overrides
  [string]$RetailDir     = "C:\Program Files (x86)\World of Warcraft\_retail_",
  [string]$ClassicEraDir = "C:\Program Files (x86)\World of Warcraft\_classic_era_"
)

$ErrorActionPreference = "Stop"

# ---------------- Paths / constants ----------------
$Root      = (Split-Path -Parent $MyInvocation.MyCommand.Path) | Split-Path -Parent
$AddonName = "WinterChecklist"
$SrcDir    = $Root
$DistDir   = Join-Path $Root ".dist"                  # zip output
$TmpRoot   = Join-Path $env:TEMP "${AddonName}_stage" # temp staging only for zips

# ---------------- Flavor map ----------------
$FlavorMap = @{
  "retail" = @{
    Toc     = "${AddonName}_Mainline.toc"
    GameDir = $RetailDir
  }
  "classic_era" = @{
    Toc     = "${AddonName}_Vanilla.toc"
    GameDir = $ClassicEraDir
  }
}

if (-not $FlavorMap.ContainsKey($Flavor)) {
  throw "Unknown flavor: ${Flavor}"
}

$ChosenToc = Join-Path $Root $FlavorMap[$Flavor].Toc
if (-not (Test-Path $ChosenToc)) {
  throw "Missing TOC for ${Flavor}: $($FlavorMap[$Flavor].Toc)"
}

# ---------------- Helpers ----------------
function Reset-Dir {
  param([Parameter(Mandatory = $true)][string]$Path)
  if (Test-Path $Path) { Remove-Item $Path -Recurse -Force }
  New-Item -ItemType Directory -Path $Path | Out-Null
}

function Get-VersionFromToc {
  param([Parameter(Mandatory = $true)][string]$TocPath)
  $verLine = Get-Content $TocPath | Where-Object { $_ -match '^\s*##\s*Version\s*:\s*(.+)$' } | Select-Object -First 1
  if ($verLine -and ($verLine -match '##\s*Version\s*:\s*(.+)$')) { return $Matches[1].Trim() }
  return "0.0.0"
}

function Copy-Project {
  param(
    [Parameter(Mandatory = $true)][string]$DestDir,
    [Parameter(Mandatory = $true)][string]$ChosenTocPath
  )

  $includeExt = @(".lua",".xml",".tga",".blp",".toc",".txt",".md",".png",".jpg",".jpeg",".ttf",".otf",".fnt")
  $excludeTop = @(".git",".vscode",".tools",".dist")

  Reset-Dir $DestDir

  Get-ChildItem -Path $SrcDir -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($SrcDir.Length).TrimStart('\','/')
    $top = ($rel -split '[\\/]')[0]

    if ($excludeTop -contains $top) { return }
    if (-not ($includeExt -contains $_.Extension.ToLower())) { return }

    $dest = Join-Path $DestDir $rel
    New-Item -ItemType Directory -Path (Split-Path $dest) -Force | Out-Null
    Copy-Item $_.FullName -Destination $dest -Force
  }

  # Ensure only the chosen TOC ships and is named WinterChecklist.toc
  Get-ChildItem -Path $DestDir -Recurse -Filter "*.toc" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
  Copy-Item -Path $ChosenTocPath -Destination (Join-Path $DestDir "WinterChecklist.toc") -Force
}

# ---------------- Actions ----------------
$Version   = Get-VersionFromToc -TocPath $ChosenToc
$FlavorTag = if ($Flavor -eq "retail") { "Retail" } else { "ClassicEra" }

switch ($Mode) {
  'zip' {
    $StageDir   = Join-Path $TmpRoot "stage"
    $PackageDir = Join-Path $TmpRoot $AddonName

    Reset-Dir $StageDir
    Copy-Project -DestDir $StageDir -ChosenTocPath $ChosenToc

    Reset-Dir $PackageDir
    Copy-Item -Path (Join-Path $StageDir '*') -Destination $PackageDir -Recurse

    if (-not (Test-Path $DistDir)) { New-Item -ItemType Directory -Path $DistDir | Out-Null }
    $ZipPath = Join-Path $DistDir ("{0}-{1}-{2}.zip" -f $AddonName,$Version,$FlavorTag)
    if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
    Compress-Archive -Path (Join-Path $PackageDir '*') -DestinationPath $ZipPath

    Write-Host "Created: $ZipPath"
    break
  }

  'install' {
    $GameDir      = $FlavorMap[$Flavor].GameDir
    $AddOnsDir    = Join-Path $GameDir "Interface\AddOns"
    $DestAddonDir = Join-Path $AddOnsDir $AddonName

    if (-not (Test-Path $AddOnsDir)) {
      throw "AddOns folder not found: ${AddOnsDir} - check your WoW install path."
    }

    Copy-Project -DestDir $DestAddonDir -ChosenTocPath $ChosenToc
    Write-Host "Installed to: $DestAddonDir"
    break
  }

  default {
    throw "Unknown mode: ${Mode}"
  }
}
