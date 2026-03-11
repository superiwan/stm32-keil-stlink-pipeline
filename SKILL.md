---
name: stm32-keil-stlink-pipeline
description: Use when a user needs end-to-end STM32 automation on Windows with Keil and ST-Link, including project detection, optional target sync from probe, command-line build, flash download, and optional serial monitoring that can be executed automatically by the agent.
---

# STM32 Keil ST-Link Pipeline

## Overview

Use this skill to bootstrap and run a reusable one-click STM32 workflow for Keil + ST-Link on Windows.

Default pipeline:
1. Install/update workspace pipeline files
2. Optional target sync from probe output
3. Keil command-line build
4. ST-Link flash download
5. Optional UART monitor

## Agent Execution Rules

- Do not ask the user to manually type commands unless they explicitly request manual mode.
- Execute the bundled runner script directly.
- Use current workspace by default.
- Default behavior should be non-blocking for CI-style checks: run without monitor.

Primary command (automatic mode):

```powershell
powershell -ExecutionPolicy Bypass -File "$env:CODEX_HOME\skills\stm32-keil-stlink-pipeline\scripts\run_pipeline.ps1" -Workspace "<workspace-path>"
```

With UART monitor:

```powershell
powershell -ExecutionPolicy Bypass -File "$env:CODEX_HOME\skills\stm32-keil-stlink-pipeline\scripts\run_pipeline.ps1" -Workspace "<workspace-path>" -WithMonitor
```

## Installer Behavior`r`n`r`n- `-Workspace` can be a project root or a parent directory.`r`n- Installer recursively finds `.uvprojx` if not present at workspace root.`r`n- Build/flash paths are derived from uvproj `OutputDirectory` + `OutputName`, not hard-coded `Objects\\Project.*`.`r`n`r`n## Modular Architecture (Plan 2)

### Probe Layer

- `scripts/templates/scripts/lib/probe.ps1`
- Reads probe info via ST-LINK_CLI or STM32_Programmer_CLI
- Extracts `Device ID` and `Device family`

### Mapping Layer

- `scripts/templates/scripts/mappings/target-mappings.psd1`
- Data-only mapping table from probe signals to Keil target metadata
- `scripts/templates/scripts/lib/mapping.ps1` resolves best match

### Apply Layer

- `scripts/templates/scripts/lib/apply-keil-target.ps1`
- Applies mapping fields to `*.uvprojx` safely and deterministically

## How To Add New STM32 Series

1. Open mapping table:
- `scripts/templates/scripts/mappings/target-mappings.psd1`

2. Add a new hashtable entry under `Mappings` with these fields:
- `Name`
- `MatchDeviceIds` (array)
- `MatchFamilyRegex`
- `Device`
- `PackID`
- `Cpu`
- `FlashDriverDll`
- `RegisterFile`
- `SFDFile`
- `SimDllName`
- `SimDlgDllArguments`
- `TargetDllName`
- `TargetDlgDllArguments`
- `AdsCpuType`

3. Re-run pipeline in any workspace:

```powershell
powershell -ExecutionPolicy Bypass -File "$env:CODEX_HOME\skills\stm32-keil-stlink-pipeline\scripts\run_pipeline.ps1" -Workspace "<workspace-path>"
```

If no mapping matches, the sync step fails with a clear message telling you to add a mapping.

## What The Skill Installs Into Workspace

- `config/dev-config.ps1`
- `scripts/build-keil.ps1`
- `scripts/sync-target-to-probe.ps1`
- `scripts/flash-stlink.ps1`
- `scripts/monitor-serial.ps1`
- `scripts/dev-all.ps1`
- `scripts/lib/*.ps1`
- `scripts/mappings/target-mappings.psd1`
- `tools/uart_logger.py`

## Verification Signals

Treat workflow as successful only if all expected markers appear:
- `[build] OK:` from build script
- `Programming Complete.` from ST-LINK_CLI
- `[dev] build + flash completed (monitor skipped)` when monitor is disabled

## Guardrails

- If sync reports `unsupported probe target`, read `references/mapping-playbook.md` before changing mappings.

- Prefer auto-detected tool paths; only hardcode as fallback.
- Do not trust uVision process exit code alone; parse `Objects/Project.build_log.htm` and fail only when `Error(s) > 0`.
- If probe-reported family differs from project target, report it clearly before applying changes.
- Keep workflow Windows-specific (`powershell`, `UV4.exe`, `ST-LINK_CLI.exe`).
