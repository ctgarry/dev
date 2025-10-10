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

    # sanity: baseToc must be a single filename, no wildcards
  if ($baseToc -match '[\*\?\[]') {
    throw "Destination TOC path cannot contain wildcards: $baseToc"
  }

  # If there's no base-named TOC yet, try to copy from repo
  Write-Host "cand  = $cand"
  Write-Host "baseToc = $baseToc"
  $baseToc = Join-Path -Path $dest -ChildPath ($AddonName + '.toc')
  if (-not (Test-Path -LiteralPath $baseToc)) {
    $repoRoot = Split-Path -Path $Here -Parent
    $cand = @("$AddonName.toc", "${AddonName}_ClassicEra.toc", "${AddonName}_Classic.toc") |
      ForEach-Object { Join-Path -Path $repoRoot -ChildPath $_ } |
      Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if ($cand) {
      # --- begin: resolve TOC candidate & validate names ---
      # Trim quotes if -Toc "..." was passed
      $cand = $cand.Trim('"')

      # Resolve $cand to exactly one file. If it's a pattern, use -Path; if not, use -LiteralPath.
      if ($cand -match '[\*\?\[]') {
        $candCandidates = @(Get-ChildItem -Path $cand -ErrorAction SilentlyContinue)
      } else {
        $candCandidates = @(Get-ChildItem -LiteralPath $cand -ErrorAction SilentlyContinue)
      }

      if ($candCandidates.Count -eq 0) {
        throw "TOC not found: $cand"
      }
      if ($candCandidates.Count -gt 1) {
        throw "Ambiguous -Toc '$cand' matched $($candCandidates.Count) files:`n$($candCandidates.FullName -join "`n")"
      }
      $cand = $candCandidates[0].FullName

      # Validate the output filename (guards against colon, *, ?, etc.)
      $baseDir  = Split-Path -Path $baseToc -Parent
      $baseName = [IO.Path]::GetFileName($baseToc)
      if ($baseName.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) {
        throw "Invalid character in output TOC name '$baseName'. Check ADDON_NAME in .vscode/tasks.json."
      }
      # --- end: resolve TOC candidate & validate names ---

      # Ensure destination dir exists, then copy
      if (-not (Test-Path -LiteralPath $baseDir)) {
        New-Item -ItemType Directory -Force -Path $baseDir | Out-Null
      }
      Copy-Item -LiteralPath $cand -Destination $baseToc -Force
    }
  }

  # Remove any other .toc variants
  Get-ChildItem -LiteralPath $dest -Filter '*.toc' |
    Where-Object { $_.Name -ne ($AddonName + '.toc') } |
    Remove-Item -Force -ErrorAction SilentlyContinue

  Write-Host "Deploy verified: single TOC $($AddonName + '.toc') in $dest"
}
