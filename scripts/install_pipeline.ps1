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

$uvprojxCandidates = @()
$uvprojxCandidates += Get-ChildItem -Path $Workspace -Filter *.uvprojx -File -ErrorAction SilentlyContinue
if ($uvprojxCandidates.Count -eq 0) {
    $uvprojxCandidates += Get-ChildItem -Path $Workspace -Recurse -Filter *.uvprojx -File -ErrorAction SilentlyContinue
}
if ($uvprojxCandidates.Count -eq 0) {
    throw "No .uvprojx found under $Workspace"
}

$uvprojx = $uvprojxCandidates | Sort-Object FullName | Select-Object -First 1
if ($uvprojxCandidates.Count -gt 1) {
    Write-Warning "Multiple .uvprojx found. Auto-selected: $($uvprojx.FullName)"
}

$targetName = 'Target 1'
$outputDirRaw = '.\\Objects\\'
$outputName = 'Project'
try {
    [xml]$x = Get-Content $uvprojx.FullName
    $target = $x.Project.Targets.Target | Select-Object -First 1
    if ($target.TargetName) { $targetName = [string]$target.TargetName }
    $tco = $target.TargetOption.TargetCommonOption
    if ($tco.OutputDirectory) { $outputDirRaw = [string]$tco.OutputDirectory }
    if ($tco.OutputName) { $outputName = [string]$tco.OutputName }
} catch {
    Write-Warning "Failed to parse uvprojx metadata, using defaults: $($_.Exception.Message)"
}

$projDir = Split-Path -Parent $uvprojx.FullName
$outputAbs = [System.IO.Path]::GetFullPath((Join-Path $projDir $outputDirRaw))
$buildLogAbs = Join-Path $outputAbs "$outputName.build_log.htm"
$artifactAbs = Join-Path $outputAbs "$outputName.axf"
$hexAbs = Join-Path $outputAbs "$outputName.hex"

$keilCandidates = @('C:\\Keil5\\UV4\\UV4.exe','C:\\Keil_v5\\UV4\\UV4.exe')
$stlinkCandidates = @(
    'C:\\Program Files (x86)\\STMicroelectronics\\STM32 ST-LINK Utility\\ST-LINK Utility\\ST-LINK_CLI.exe',
    'C:\\Program Files\\STMicroelectronics\\STM32Cube\\STM32CubeProgrammer\\bin\\STM32_Programmer_CLI.exe'
)

$KeilUv4 = ($keilCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1)
if (-not $KeilUv4) { $KeilUv4 = $keilCandidates[0] }

$StlinkCli = ($stlinkCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1)
if (-not $StlinkCli) { $StlinkCli = $stlinkCandidates[0] }

New-Item -ItemType Directory -Force -Path (Join-Path $Workspace 'config'), (Join-Path $Workspace 'scripts'), (Join-Path $Workspace 'tools'), (Join-Path $Workspace 'logs'), (Join-Path $Workspace 'Objects') | Out-Null
Copy-Item (Join-Path $TemplateRoot 'scripts\\*') (Join-Path $Workspace 'scripts') -Recurse -Force
Copy-Item (Join-Path $TemplateRoot 'tools\\uart_logger.py') (Join-Path $Workspace 'tools') -Force

$configPath = Join-Path $Workspace 'config\\dev-config.ps1'
@"
`$Root = Split-Path -Parent `$PSScriptRoot

# Keil MDK
`$KeilUv4 = '$KeilUv4'

# Keil project (absolute path for nested workspaces)
`$ProjectFile = '$($uvprojx.FullName)'
`$TargetName = '$targetName'
`$BuildLog = '$buildLogAbs'

# Build artifacts
`$ArtifactPath = '$artifactAbs'
`$HexPath = '$hexAbs'

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
Write-Host "[skill-installer] project=$($uvprojx.FullName), target=$targetName"
Write-Host "[skill-installer] outputs: $outputAbs\\$outputName.*"
Write-Host "[skill-installer] run: powershell -ExecutionPolicy Bypass -File .\\scripts\\dev-all.ps1 -NoMonitor"
