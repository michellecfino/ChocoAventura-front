#Requires -Version 5.1
<#
.SYNOPSIS
  Libera bloqueos comunes y ejecuta flutter clean + pub get.

  Uso (desde la carpeta choco):
    .\scripts\clean_flutter_build.ps1 -StopDartProcesses

  Si flutter clean sigue fallando (ephemeral, .dart_tool, symlinks):
    .\scripts\clean_flutter_build.ps1 -StopDartProcesses -DeepClean
#>
param(
  [switch]$StopDartProcesses,
  [switch]$DeepClean
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $ProjectRoot

function Stop-BuildProcesses {
  Get-Process -Name dart, dartaotruntime, flutter_tester -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue
  $gradle = Join-Path $ProjectRoot "android\gradlew.bat"
  if (Test-Path -LiteralPath $gradle) {
    Push-Location (Join-Path $ProjectRoot "android")
    try {
      & .\gradlew.bat --stop 2>$null
    } finally {
      Pop-Location
    }
  }
}

function Clear-DirectoryContents([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { return }
  $empty = Join-Path $env:TEMP ("flutter_empty_" + [guid]::NewGuid().ToString("n"))
  New-Item -ItemType Directory -Force -Path $empty | Out-Null
  try {
    & robocopy.exe $empty $Path /MIR /NFL /NDL /NJH /NJS /NP | Out-Null
  } finally {
    if (Test-Path -LiteralPath $empty) {
      Remove-Item -LiteralPath $empty -Recurse -Force -ErrorAction SilentlyContinue
    }
  }
}

if ($StopDartProcesses) {
  Stop-BuildProcesses
  Start-Sleep -Milliseconds 500
}

if ($DeepClean) {
  Write-Host "DeepClean: vaciando build, .dart_tool y carpetas ephemeral..."
  Clear-DirectoryContents (Join-Path $ProjectRoot "build")
  Clear-DirectoryContents (Join-Path $ProjectRoot ".dart_tool")
  Clear-DirectoryContents (Join-Path $ProjectRoot "ios\Flutter\ephemeral")
  Clear-DirectoryContents (Join-Path $ProjectRoot "macos\Flutter\ephemeral")
  Clear-DirectoryContents (Join-Path $ProjectRoot "windows\flutter\ephemeral")
}

& flutter clean
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Listo. Ejecuta: flutter run -d chrome"
