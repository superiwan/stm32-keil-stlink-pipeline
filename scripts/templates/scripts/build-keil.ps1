param(
    [switch]$Quiet
)

$Root = Split-Path -Parent $PSScriptRoot
. (Join-Path $Root 'config\dev-config.ps1')

function Resolve-ArtifactPath {
    param(
        [string]$PreferredPath,
        [string]$ObjectsDir
    )

    if ($PreferredPath -and (Test-Path $PreferredPath)) {
        return (Resolve-Path $PreferredPath).Path
    }

    $candidates = Get-ChildItem -Path $ObjectsDir -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -in '.axf', '.elf' } |
        Sort-Object LastWriteTime -Descending

    if ($candidates) {
        return $candidates[0].FullName
    }

    return $null
}

if (-not (Test-Path $KeilUv4)) {
    throw "UV4.exe not found: $KeilUv4"
}
if (-not (Test-Path $ProjectFile)) {
    throw "Keil project not found: $ProjectFile"
}

$objectsDir = Join-Path $Root 'Objects'
$htmlLog = Join-Path $objectsDir 'Project.build_log.htm'

$args = @('-j0', '-b', $ProjectFile, '-t', $TargetName)
if (-not $Quiet) {
    Write-Host "[build] $KeilUv4 $($args -join ' ')"
}

$proc = Start-Process -FilePath $KeilUv4 -ArgumentList $args -PassThru -Wait -NoNewWindow

# Some uVision versions return non-zero even on successful command-line builds.
# Use build log content as the source of truth.
if (-not (Test-Path $htmlLog)) {
    throw "Keil build log not found: $htmlLog (exit=$($proc.ExitCode))"
}

$logText = Get-Content $htmlLog -Raw
if ($logText -notmatch '(\d+) Error\(s\),\s*(\d+) Warning\(s\)') {
    throw "Cannot parse Keil build result from $htmlLog (exit=$($proc.ExitCode))"
}

$errCount = [int]$Matches[1]
$warnCount = [int]$Matches[2]
if ($errCount -gt 0) {
    throw "Keil build has $errCount error(s), $warnCount warning(s). See $htmlLog"
}

$resolvedArtifact = Resolve-ArtifactPath -PreferredPath $ArtifactPath -ObjectsDir $objectsDir
if (-not $resolvedArtifact) {
    throw "Build reported success but no .axf/.elf found in $objectsDir"
}

Write-Host "[build] OK: $resolvedArtifact (warnings=$warnCount, exit=$($proc.ExitCode))"
