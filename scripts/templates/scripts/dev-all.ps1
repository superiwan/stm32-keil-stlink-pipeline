param(
    [switch]$SkipBuild,
    [switch]$NoMonitor,
    [switch]$SyncTargetToProbe
)

if ($SyncTargetToProbe) {
    powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'sync-target-to-probe.ps1')
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

if (-not $SkipBuild) {
    powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'build-keil.ps1')
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'flash-stlink.ps1')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if (-not $NoMonitor) {
    powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'monitor-serial.ps1')
    exit $LASTEXITCODE
}

Write-Host '[dev] build + flash completed (monitor skipped)'
exit 0
