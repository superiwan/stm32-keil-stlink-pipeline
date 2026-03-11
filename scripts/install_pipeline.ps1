param(
    [Parameter(Mandatory = $true)]
    [string]$Workspace
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $Workspace)) {
    throw "Workspace not found: $Workspace"
}

$Workspace = (Resolve-Path $Workspace).Path
$TemplateRoot = Join-Path $PSScriptRoot 'templates'

$uvprojx = Get-ChildItem -Path $Workspace -Filter *.uvprojx -File | Select-Object -First 1
if (-not $uvprojx) {
    throw "No .uvprojx found in $Workspace"
}

$targetName = 'Target 1'
try {
    [xml]$x = Get-Content $uvprojx.FullName
    $tn = $x.Project.Targets.Target.TargetName | Select-Object -First 1
    if ($tn) { $targetName = [string]$tn }
} catch {}

$keilCandidates = @('C:\Keil5\UV4\UV4.exe','C:\Keil_v5\UV4\UV4.exe')
$stlinkCandidates = @(
    'C:\Program Files (x86)\STMicroelectronics\STM32 ST-LINK Utility\ST-LINK Utility\ST-LINK_CLI.exe',
    'C:\Program Files\STMicroelectronics\STM32Cube\STM32CubeProgrammer\bin\STM32_Programmer_CLI.exe'
)

$KeilUv4 = ($keilCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1)
if (-not $KeilUv4) { $KeilUv4 = $keilCandidates[0] }

$StlinkCli = ($stlinkCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1)
if (-not $StlinkCli) { $StlinkCli = $stlinkCandidates[0] }

New-Item -ItemType Directory -Force -Path (Join-Path $Workspace 'config'), (Join-Path $Workspace 'scripts'), (Join-Path $Workspace 'tools'), (Join-Path $Workspace 'logs'), (Join-Path $Workspace 'Objects') | Out-Null

# Copy full script template tree (including lib/ and mappings/)
Copy-Item (Join-Path $TemplateRoot 'scripts\*') (Join-Path $Workspace 'scripts') -Recurse -Force
Copy-Item (Join-Path $TemplateRoot 'tools\uart_logger.py') (Join-Path $Workspace 'tools') -Force

$configPath = Join-Path $Workspace 'config\dev-config.ps1'
@"
`$Root = Split-Path -Parent `$PSScriptRoot

# Keil MDK
`$KeilUv4 = '$KeilUv4'

# Keil project
`$ProjectFile = Join-Path `$Root '$($uvprojx.Name)'
`$TargetName = '$targetName'
`$BuildLog = Join-Path `$Root 'Objects\\build.log'

# Build artifacts
`$ArtifactPath = Join-Path `$Root 'Objects\\Project.axf'
`$HexPath = Join-Path `$Root 'Objects\\Project.hex'

# ST-Link flashing
`$StlinkCli = '$StlinkCli'
`$StlinkInterface = 'SWD'

# UART monitor
`$SerialPort = 'auto'
`$BaudRate = 115200
`$LogPath = Join-Path `$Root 'logs\\uart.log'

# Ensure runtime folders exist
`$null = New-Item -ItemType Directory -Force -Path (Join-Path `$Root 'Objects'), (Join-Path `$Root 'logs')
"@ | Set-Content -Encoding utf8 $configPath

Write-Host "[skill-installer] installed pipeline into $Workspace"
Write-Host "[skill-installer] project=$($uvprojx.Name), target=$targetName"
Write-Host "[skill-installer] run: powershell -ExecutionPolicy Bypass -File .\\scripts\\dev-all.ps1 -NoMonitor"
