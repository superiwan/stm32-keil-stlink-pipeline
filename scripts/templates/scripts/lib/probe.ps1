function Get-Stm32ProbeInfo {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FlashToolPath,
        [string]$Interface = 'SWD'
    )

    if (-not (Test-Path $FlashToolPath)) {
        throw "Flash tool not found: $FlashToolPath"
    }

    if ($FlashToolPath -match 'STM32_Programmer_CLI.exe$') {
        $probeArgs = @('-c', "port=$Interface", 'mode=UR')
    } else {
        $probeArgs = @('-c', $Interface, 'UR')
    }

    Write-Host "[sync] probing target with $FlashToolPath $($probeArgs -join ' ')"
    $probeText = (& $FlashToolPath @probeArgs 2>&1 | Out-String)
    Write-Host $probeText

    $deviceId = $null
    $family = $null
    if ($probeText -match 'Device ID:\s*(0x[0-9A-Fa-f]+)') { $deviceId = $Matches[1].ToUpper() }
    if ($probeText -match 'Device family:\s*(.+)') { $family = $Matches[1].Trim() }

    if (-not $deviceId -and -not $family) {
        throw '[sync] failed to parse probe output (missing Device ID/family)'
    }

    return [pscustomobject]@{
        ToolPath = $FlashToolPath
        DeviceId = $deviceId
        Family = $family
        RawOutput = $probeText
    }
}
