$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
. (Join-Path $Root 'config\\dev-config.ps1')

function Resolve-HexPath {
    param([string]$PreferredPath)

    if ($PreferredPath -and (Test-Path $PreferredPath)) {
        return (Resolve-Path $PreferredPath).Path
    }

    $searchDirs = @()
    if ($PreferredPath) { $searchDirs += Split-Path -Parent $PreferredPath }
    if ($BuildLog) { $searchDirs += Split-Path -Parent $BuildLog }
    if ($ArtifactPath) { $searchDirs += Split-Path -Parent $ArtifactPath }

    foreach ($dir in ($searchDirs | Select-Object -Unique)) {
        if (-not (Test-Path $dir)) { continue }
        $candidates = Get-ChildItem -Path $dir -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -eq '.hex' } |
            Sort-Object LastWriteTime -Descending
        if ($candidates) { return $candidates[0].FullName }
    }

    return $null
}

$resolvedHex = Resolve-HexPath -PreferredPath $HexPath
if (-not $resolvedHex) {
    throw "HEX not found. Checked configured hex path and nearby output directories. Build first."
}

if (-not (Test-Path $StlinkCli)) {
    throw "Flash tool not found: $StlinkCli"
}

if ($StlinkCli -match 'STM32_Programmer_CLI.exe$') {
    $cmd = @('-c', "port=SWD", '-d', $resolvedHex, '0x08000000', '-rst')
    Write-Host "[flash] $StlinkCli $($cmd -join ' ')"
    & $StlinkCli @cmd
} else {
    $cmd = @('-c', $StlinkInterface, 'UR', '-P', $resolvedHex, '-V', '-Rst')
    Write-Host "[flash] $StlinkCli $($cmd -join ' ')"
    & $StlinkCli @cmd
}

if ($LASTEXITCODE -ne 0) {
    throw "Flash failed with exit code $LASTEXITCODE"
}

Write-Host "[flash] OK: $resolvedHex"
