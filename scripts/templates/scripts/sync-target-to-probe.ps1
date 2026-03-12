param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $PSScriptRoot
. (Join-Path $Root 'config\dev-config.ps1')
. (Join-Path $PSScriptRoot 'lib\probe.ps1')
. (Join-Path $PSScriptRoot 'lib\mapping.ps1')
. (Join-Path $PSScriptRoot 'lib\apply-keil-target.ps1')

# Normalize uvprojx encoding to UTF-8 no BOM to reduce "Cannot read project file" issues.
if (Test-Path $ProjectFile) {
    $raw = Get-Content $ProjectFile -Raw
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($ProjectFile, $raw, $enc)
}

$probeInfo = Get-Stm32ProbeInfo -FlashToolPath $StlinkCli -Interface $StlinkInterface
$mappingPath = Join-Path $PSScriptRoot 'mappings\target-mappings.psd1'
$mapping = Resolve-Stm32TargetMapping -ProbeInfo $probeInfo -MappingsPath $mappingPath

$result = Set-KeilTargetFromMapping -ProjectFile $ProjectFile -Mapping $mapping -Force:$Force
if ($result.Changed) {
    Write-Host "[sync] updated Keil target metadata to $($mapping.Device) in $ProjectFile"
} else {
    Write-Host "[sync] project already aligned to $($mapping.Device); no changes applied."
}
