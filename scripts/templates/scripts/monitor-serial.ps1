param(
    [switch]$NoTimestamp,
    [switch]$Hex
)

$Root = Split-Path -Parent $PSScriptRoot
. (Join-Path $Root 'config\dev-config.ps1')

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    throw 'python not found in PATH.'
}

$logger = Join-Path $Root 'tools\uart_logger.py'
if (-not (Test-Path $logger)) {
    throw "uart logger not found: $logger"
}

$args = @('--port', $SerialPort, '--baud', $BaudRate, '--log', $LogPath)
if ($NoTimestamp) { $args += '--no-ts' }
if ($Hex) { $args += '--hex' }

Write-Host "[uart] python $logger $($args -join ' ')"
& python $logger @args
if ($LASTEXITCODE -ne 0) {
    throw "uart monitor exited with code $LASTEXITCODE"
}
