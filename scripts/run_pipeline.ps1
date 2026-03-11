param(
    [string]$Workspace = (Get-Location).Path,
    [switch]$WithMonitor,
    [switch]$SkipSyncTarget
)

$ErrorActionPreference = 'Stop'
$Workspace = (Resolve-Path $Workspace).Path

$installScript = Join-Path $PSScriptRoot 'install_pipeline.ps1'
if (-not (Test-Path $installScript)) {
    throw "install script missing: $installScript"
}

powershell -ExecutionPolicy Bypass -File $installScript -Workspace $Workspace
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Push-Location $Workspace
try {
    $devAll = Join-Path $Workspace 'scripts\dev-all.ps1'
    if (-not (Test-Path $devAll)) {
        throw "dev-all script missing: $devAll"
    }

    $args = @()
    if (-not $WithMonitor) { $args += '-NoMonitor' }
    if (-not $SkipSyncTarget) { $args += '-SyncTargetToProbe' }

    powershell -ExecutionPolicy Bypass -File $devAll @args
    exit $LASTEXITCODE
}
finally {
    Pop-Location
}
