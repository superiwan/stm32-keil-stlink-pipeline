$Root = Split-Path -Parent $PSScriptRoot
. (Join-Path $Root 'config\dev-config.ps1')

function Resolve-HexPath {
    param(
        [string]$PreferredPath,
        [string]$ObjectsDir
    )

    if ($PreferredPath -and (Test-Path $PreferredPath)) {
        return (Resolve-Path $PreferredPath).Path
    }

    $candidates = Get-ChildItem -Path $ObjectsDir -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -eq '.hex' } |
        Sort-Object LastWriteTime -Descending

    if ($candidates) {
        return $candidates[0].FullName
    }

    return $null
}

if (-not (Test-Path $StlinkCli)) {
    throw "ST-LINK_CLI not found: $StlinkCli"
}

$objectsDir = Join-Path $Root 'Objects'
$resolvedHex = Resolve-HexPath -PreferredPath $HexPath -ObjectsDir $objectsDir
if (-not $resolvedHex) {
    throw "HEX not found. Checked '$HexPath' and latest .hex in '$objectsDir'. Build first."
}

$cmd = @(
    '-c', $StlinkInterface, 'UR',
    '-P', $resolvedHex,
    '-V',
    '-Rst'
)

Write-Host "[flash] $StlinkCli $($cmd -join ' ')"
& $StlinkCli @cmd
if ($LASTEXITCODE -ne 0) {
    throw "ST-LINK_CLI flash failed with exit code $LASTEXITCODE"
}

Write-Host "[flash] OK: $resolvedHex"
