# Mapping Playbook

Use this guide when `sync-target-to-probe.ps1` reports unsupported probe target, or when the board family is new.

## When To Add Mapping

Add a new mapping entry if any of these happens:
- Sync error contains: `unsupported probe target`
- Probe output has `Device ID` and/or `Device family` that do not match existing rules
- Build/download requires a different Keil target metadata set than current mapping

## Fast Decision Rules

1. Match priority:
- `MatchDeviceIds` has higher priority than `MatchFamilyRegex`
- If both match multiple entries, stop and ask for a specific MCU part number

2. Confidence policy:
- High confidence: unique `Device ID` + family alignment -> apply automatically
- Medium confidence: family-only match -> prefer explicit user confirmation
- Low confidence: no match -> do not modify project, add mapping first

## Minimal Mapping Template

Add one hashtable entry under `Mappings` in `scripts/templates/scripts/mappings/target-mappings.psd1`:

```powershell
@{
    Name = 'stm32f4xx-example'
    MatchDeviceIds = @('0X413')
    MatchFamilyRegex = 'STM32F405|STM32F407|STM32F415|STM32F417'
    Device = 'STM32F407VG'
    PackID = 'Keil.STM32F4xx_DFP.3.0.0'
    Cpu = 'IRAM(0x20000000,0x20000) IROM(0x08000000,0x100000) CPUTYPE("Cortex-M4") FPU2 CLOCK(12000000) ELITTLE'
    FlashDriverDll = 'UL2CM3(-S0 -C0 -P0 -FD20000000 -FC1000 -FN1 -FF0STM32F4xx_1024 -FS08000000 -FL100000 -FP0($$Device:STM32F407VG$CMSIS\\Flash\\STM32F4xx_1024.FLM))'
    RegisterFile = '$$Device:STM32F407VG$CMSIS\\Device\\ST\\STM32F4xx\\Include\\stm32f407xx.h'
    SFDFile = '$$Device:STM32F407VG$CMSIS\\SVD\\STM32F407.svd'
    SimDllName = 'SARMCM4.DLL'
    SimDlgDllArguments = '-pCM4'
    TargetDllName = 'SARMCM4.DLL'
    TargetDlgDllArguments = '-pCM4'
    AdsCpuType = '"Cortex-M4"'
}
```

## Post-Change Verification

After adding or updating mapping:
1. Reinstall pipeline to workspace:
- `powershell -ExecutionPolicy Bypass -File "$env:CODEX_HOME\skills\stm32-keil-stlink-pipeline\scripts\install_pipeline.ps1" -Workspace "<workspace>"`
2. Run one-shot sync + build + flash:
- `powershell -ExecutionPolicy Bypass -File "$env:CODEX_HOME\skills\stm32-keil-stlink-pipeline\scripts\run_pipeline.ps1" -Workspace "<workspace>"`
3. Confirm success markers:
- `[sync] updated ...` or `already aligned`
- `[build] OK:`
- `Programming Complete.`

## Guardrail

If part number is ambiguous (same family but different flash size/package), ask for exact MCU marking and avoid blind updates.
