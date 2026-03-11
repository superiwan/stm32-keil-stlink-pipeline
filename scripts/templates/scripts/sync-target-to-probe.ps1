param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $PSScriptRoot
. (Join-Path $Root 'config\dev-config.ps1')

if (-not (Test-Path $ProjectFile)) {
    throw "Keil project not found: $ProjectFile"
}
if (-not (Test-Path $StlinkCli)) {
    throw "Flash tool not found: $StlinkCli"
}

if ($StlinkCli -match 'STM32_Programmer_CLI.exe$') {
    $probeArgs = @('-c', 'port=SWD', 'mode=UR')
} else {
    $probeArgs = @('-c', $StlinkInterface, 'UR')
}

Write-Host "[sync] probing target with $StlinkCli $($probeArgs -join ' ')"
$probeText = (& $StlinkCli @probeArgs 2>&1 | Out-String)
Write-Host $probeText

$deviceId = $null
$family = $null
if ($probeText -match 'Device ID:\s*(0x[0-9A-Fa-f]+)') { $deviceId = $Matches[1].ToUpper() }
if ($probeText -match 'Device family:\s*(.+)') { $family = $Matches[1].Trim() }

if (-not $deviceId -and -not $family) {
    throw '[sync] failed to parse probe output (missing Device ID/family)'
}

$targetDevice = $null
if ($deviceId -eq '0X413' -or $family -match 'STM32F405|STM32F407|STM32F415|STM32F417') {
    $targetDevice = 'STM32F407VG'
}

if (-not $targetDevice) {
    throw "[sync] unsupported probe target: deviceId='$deviceId' family='$family'."
}

if ($targetDevice -ne 'STM32F407VG') {
    throw "[sync] mapping not implemented for '$targetDevice'"
}

$xmlPath = $ProjectFile
$text = Get-Content $xmlPath -Raw
$original = $text

$text = [regex]::Replace($text, '<Device>.*?</Device>', '<Device>STM32F407VG</Device>')
$text = [regex]::Replace($text, '<PackID>.*?</PackID>', '<PackID>Keil.STM32F4xx_DFP.3.0.0</PackID>')
$text = [regex]::Replace($text, '<Cpu>.*?</Cpu>', '<Cpu>IRAM(0x20000000,0x20000) IROM(0x08000000,0x100000) CPUTYPE("Cortex-M4") FPU2 CLOCK(12000000) ELITTLE</Cpu>')
$text = [regex]::Replace($text, '<FlashDriverDll>.*?</FlashDriverDll>', '<FlashDriverDll>UL2CM3(-S0 -C0 -P0 -FD20000000 -FC1000 -FN1 -FF0STM32F4xx_1024 -FS08000000 -FL100000 -FP0($$Device:STM32F407VG$CMSIS\\Flash\\STM32F4xx_1024.FLM))</FlashDriverDll>')
$text = [regex]::Replace($text, '<RegisterFile>.*?</RegisterFile>', '<RegisterFile>$$Device:STM32F407VG$CMSIS\\Device\\ST\\STM32F4xx\\Include\\stm32f407xx.h</RegisterFile>')
$text = [regex]::Replace($text, '<SFDFile>.*?</SFDFile>', '<SFDFile>$$Device:STM32F407VG$CMSIS\\SVD\\STM32F407.svd</SFDFile>')
$text = [regex]::Replace($text, '<SimDllName>.*?</SimDllName>', '<SimDllName>SARMCM4.DLL</SimDllName>')
$text = [regex]::Replace($text, '<SimDlgDllArguments>.*?</SimDlgDllArguments>', '<SimDlgDllArguments>-pCM4</SimDlgDllArguments>')
$text = [regex]::Replace($text, '<TargetDllName>.*?</TargetDllName>', '<TargetDllName>SARMCM4.DLL</TargetDllName>')
$text = [regex]::Replace($text, '<TargetDlgDllArguments>.*?</TargetDlgDllArguments>', '<TargetDlgDllArguments>-pCM4</TargetDlgDllArguments>')
$text = [regex]::Replace($text, '<AdsCpuType>.*?</AdsCpuType>', '<AdsCpuType>"Cortex-M4"</AdsCpuType>')

if (-not $Force -and $text -eq $original) {
    Write-Host '[sync] project already aligned to F407; no changes applied.'
    exit 0
}

$enc = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($xmlPath, $text, $enc)
Write-Host "[sync] updated Keil target metadata to STM32F407VG in $xmlPath"
