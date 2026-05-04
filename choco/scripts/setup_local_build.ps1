#Requires -Version 5.1
<#
.SYNOPSIS
  Deja la carpeta `build` del proyecto en disco local (fuera de OneDrive) para evitar
  errores como "Flutter failed to delete build\flutter_assets" por bloqueos de sincronización.

  Ejecutar una vez desde PowerShell (como tu usuario):
    .\scripts\setup_local_build.ps1

  Opcional si algo sigue bloqueando archivos:
    .\scripts\setup_local_build.ps1 -StopDartProcesses
#>
param(
  [switch]$StopDartProcesses
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$BuildPath = Join-Path $ProjectRoot "build"
$Target = Join-Path $env:LOCALAPPDATA "ChocoAventura-front-flutter-build"

function Stop-DartFamily {
  Get-Process -Name dart, dartaotruntime, flutter_tester -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue
}

if ($StopDartProcesses) {
  Stop-DartFamily
  Start-Sleep -Milliseconds 400
}

New-Item -ItemType Directory -Force -Path $Target | Out-Null

function Remove-DirectoryDeep([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { return }
  $item = Get-Item -LiteralPath $Path -Force
  if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
    # Solo quitar el vínculo; no borrar el destino del junction.
    cmd /c "rmdir `"$Path`""
    return
  }
  $empty = Join-Path $env:TEMP ("flutter_empty_" + [guid]::NewGuid().ToString("n"))
  New-Item -ItemType Directory -Force -Path $empty | Out-Null
  try {
    & robocopy.exe $empty $Path /MIR /NFL /NDL /NJH /NJS /NP | Out-Null
    Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
  } finally {
    if (Test-Path -LiteralPath $empty) {
      Remove-Item -LiteralPath $empty -Recurse -Force -ErrorAction SilentlyContinue
    }
  }
}

if (Test-Path -LiteralPath $BuildPath) {
  $item = Get-Item -LiteralPath $BuildPath -Force
  $isLink = ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint)
  if ($isLink) {
    Write-Host "OK: 'build' ya apunta fuera de OneDrive."
    Write-Host "    Enlace -> $Target"
    exit 0
  }
  Write-Host "Eliminando carpeta build antigua (rutas largas / OneDrive)..."
  try {
    Remove-DirectoryDeep -Path $BuildPath
  } catch {
    Write-Host "No se pudo borrar 'build'. Cierra Chrome/VS Code, ejecuta con -StopDartProcesses, o pausa OneDrive y vuelve a intentar."
    throw
  }
}

$code = (Start-Process -FilePath cmd.exe -ArgumentList @(
    '/c', 'mklink', '/J', $BuildPath, $Target
  ) -Wait -NoNewWindow -PassThru).ExitCode

if ($code -ne 0) {
  throw "mklink falló (código $code). Prueba abrir PowerShell 'Como administrador' solo si tu política lo exige."
}

Write-Host "Listo: build -> $Target"
Write-Host "Ahora en la carpeta choco: flutter pub get  y  flutter run -d chrome"
