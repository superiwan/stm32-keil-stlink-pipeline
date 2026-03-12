param(
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
. (Join-Path $Root 'config\dev-config.ps1')

function Resolve-ArtifactPath {
    param([string]$PreferredPath)

    if ($PreferredPath -and (Test-Path $PreferredPath)) {
        return (Resolve-Path $PreferredPath).Path
    }

    $searchDirs = @()
    if ($PreferredPath) { $searchDirs += Split-Path -Parent $PreferredPath }
    if ($BuildLog) { $searchDirs += Split-Path -Parent $BuildLog }

    foreach ($dir in ($searchDirs | Select-Object -Unique)) {
        if (-not (Test-Path $dir)) { continue }
        $candidates = Get-ChildItem -Path $dir -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -in '.axf', '.elf' } |
            Sort-Object LastWriteTime -Descending
        if ($candidates) { return $candidates[0].FullName }
    }

    return $null
}

function Resolve-BuildLogPath {
    if ($BuildLog -and (Test-Path $BuildLog)) { return (Resolve-Path $BuildLog).Path }

    $dirs = @()
    if ($BuildLog) { $dirs += Split-Path -Parent $BuildLog }
    if ($ArtifactPath) { $dirs += Split-Path -Parent $ArtifactPath }

    foreach ($d in ($dirs | Select-Object -Unique)) {
        if (-not (Test-Path $d)) { continue }
        $logs = Get-ChildItem -Path $d -Filter *.build_log.htm -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
        if ($logs) { return $logs[0].FullName }
    }

    return $null
}

if (-not (Test-Path $KeilUv4)) { throw "UV4.exe not found: $KeilUv4" }
if (-not (Test-Path $ProjectFile)) { throw "Keil project not found: $ProjectFile" }

# Avoid stale GUI session state carrying over across projects.
$uv4 = Get-Process UV4 -ErrorAction SilentlyContinue
if ($uv4) {
    if (-not $Quiet) { Write-Host "[build] stopping stale UV4 sessions before CLI build..." }
    $uv4 | Stop-Process -Force
    Start-Sleep -Milliseconds 300
}

$args = @('-j0', '-b', $ProjectFile, '-t', $TargetName)
if (-not $Quiet) { Write-Host "[build] $KeilUv4 $($args -join ' ')" }

$proc = Start-Process -FilePath $KeilUv4 -ArgumentList $args -PassThru -Wait -NoNewWindow

$logPath = Resolve-BuildLogPath
if (-not $logPath) {
    throw "Keil build log not found. Expected '$BuildLog' or latest *.build_log.htm near artifact (exit=$($proc.ExitCode))"
}

$logText = Get-Content $logPath -Raw
if ($logText -notmatch '(\d+) Error\(s\),\s*(\d+) Warning\(s\)') {
    throw "Cannot parse build result from $logPath (exit=$($proc.ExitCode))"
}

$errCount = [int]$Matches[1]
$warnCount = [int]$Matches[2]
if ($errCount -gt 0) {
    throw "Keil build has $errCount error(s), $warnCount warning(s). See $logPath"
}

$resolvedArtifact = Resolve-ArtifactPath -PreferredPath $ArtifactPath
if (-not $resolvedArtifact) {
    throw "Build reported success but no .axf/.elf found near configured paths."
}

Write-Host "[build] OK: $resolvedArtifact (warnings=$warnCount, exit=$($proc.ExitCode), log=$logPath)"
