---
name: Dayarc Memory
description: Read and write memory JSON files in the user's dayarc folder.
---

## Memory Location
`~/Documents/dayarc/memory/`

## Operations

### Read
Read any JSON file from the memory directory. Common files:
- `daily/daily-profile-{YYYY-MM-DD}.json`
- `weekly-summary-current.json`
- `weekly-summary-prev.json`
- `weekly-archive/{week-date}.json`
- `monthly-summary.json`
- `monthly-archive/{YYYY-MM}.json`
- `runs/{date}-{type}.json`

To list files: list the contents of a subdirectory.

### Write
Write JSON to the memory directory. ALWAYS read memory-schemas.md first and validate the structure.

> ⚠️ **IMPORTANT — Always use PowerShell shell commands for all file writes. Never use the Copilot CLI built-in `create` tool.**
> The `create` tool writes to the session sandbox, not to `~/Documents/dayarc/memory/`. Files written with it are lost when the session ends.
>
> Use this pattern for every write:
> ```powershell
> $memDir = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "dayarc\memory"
> $json | Set-Content (Join-Path $memDir "{relative-path-to-file}") -Encoding UTF8
> ```
> For subdirectories (e.g., `daily/`, `runs/`, `weekly-archive/`), ensure the directory exists first:
> ```powershell
> $dir = Join-Path $memDir "daily"
> if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force }
> ```

### Memory Lifecycle (for scheduled plans)
- PM: write daily-profile-{today}.json
- Weekly: absorb prev → archive to weekly-archive/ → rotate current→prev → write new → purge dailies
- Monthly: absorb prev month → archive to monthly-archive/{YYYY-MM}.json → overwrite monthly-summary.json → purge weekly-archive older than current month → purge monthly-archive older than 6 months

### Run Tags
Write `runs/{date}-{type}.json` (e.g., `runs/2026-03-14-pm.json`) before sending email. If tag exists, skip — already ran.

## Instructions
When writing: validate against memory-schemas.md. When reading: handle missing files gracefully (bootstrap).
