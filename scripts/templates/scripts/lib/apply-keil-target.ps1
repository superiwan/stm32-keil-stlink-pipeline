function Set-KeilTargetFromMapping {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectFile,
        [Parameter(Mandatory = $true)]
        [hashtable]$Mapping,
        [switch]$Force
    )

    if (-not (Test-Path $ProjectFile)) {
        throw "Keil project not found: $ProjectFile"
    }

    $text = Get-Content $ProjectFile -Raw
    $original = $text

    $text = [regex]::Replace($text, '<Device>.*?</Device>', "<Device>$($Mapping.Device)</Device>")
    $text = [regex]::Replace($text, '<PackID>.*?</PackID>', "<PackID>$($Mapping.PackID)</PackID>")
    $text = [regex]::Replace($text, '<Cpu>.*?</Cpu>', "<Cpu>$($Mapping.Cpu)</Cpu>")
    $text = [regex]::Replace($text, '<FlashDriverDll>.*?</FlashDriverDll>', "<FlashDriverDll>$($Mapping.FlashDriverDll)</FlashDriverDll>")
    $text = [regex]::Replace($text, '<RegisterFile>.*?</RegisterFile>', "<RegisterFile>$($Mapping.RegisterFile)</RegisterFile>")
    $text = [regex]::Replace($text, '<SFDFile>.*?</SFDFile>', "<SFDFile>$($Mapping.SFDFile)</SFDFile>")
    $text = [regex]::Replace($text, '<SimDllName>.*?</SimDllName>', "<SimDllName>$($Mapping.SimDllName)</SimDllName>")
    $text = [regex]::Replace($text, '<SimDlgDllArguments>.*?</SimDlgDllArguments>', "<SimDlgDllArguments>$($Mapping.SimDlgDllArguments)</SimDlgDllArguments>")
    $text = [regex]::Replace($text, '<TargetDllName>.*?</TargetDllName>', "<TargetDllName>$($Mapping.TargetDllName)</TargetDllName>")
    $text = [regex]::Replace($text, '<TargetDlgDllArguments>.*?</TargetDlgDllArguments>', "<TargetDlgDllArguments>$($Mapping.TargetDlgDllArguments)</TargetDlgDllArguments>")
    $text = [regex]::Replace($text, '<AdsCpuType>.*?</AdsCpuType>', "<AdsCpuType>$($Mapping.AdsCpuType)</AdsCpuType>")

    if (-not $Force -and $text -eq $original) {
        return [pscustomobject]@{ Changed = $false }
    }

    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($ProjectFile, $text, $enc)
    return [pscustomobject]@{ Changed = $true }
}
