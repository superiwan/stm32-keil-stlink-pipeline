function Resolve-Stm32TargetMapping {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$ProbeInfo,
        [Parameter(Mandatory = $true)]
        [string]$MappingsPath
    )

    if (-not (Test-Path $MappingsPath)) {
        throw "Mappings file not found: $MappingsPath"
    }

    $data = Import-PowerShellDataFile -Path $MappingsPath
    $mappings = @($data.Mappings)
    if (-not $mappings -or $mappings.Count -eq 0) {
        throw "No mappings found in $MappingsPath"
    }

    $idMatches = @($mappings | Where-Object {
        $_.MatchDeviceIds -and $ProbeInfo.DeviceId -and ($_.MatchDeviceIds -contains $ProbeInfo.DeviceId)
    })
    if ($idMatches.Count -gt 0) {
        return $idMatches[0]
    }

    $famMatches = @($mappings | Where-Object {
        $_.MatchFamilyRegex -and $ProbeInfo.Family -and ($ProbeInfo.Family -match $_.MatchFamilyRegex)
    })
    if ($famMatches.Count -gt 0) {
        return $famMatches[0]
    }

    throw "[sync] unsupported probe target: deviceId='$($ProbeInfo.DeviceId)' family='$($ProbeInfo.Family)'. Add mapping in $MappingsPath"
}
