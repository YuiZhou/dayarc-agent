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
- `runs/{date}-{type}.json`

To list files: list the contents of a subdirectory.

### Write
Write JSON to the memory directory. ALWAYS read memory-schemas.md first and validate the structure.

### Memory Lifecycle (for scheduled plans)
- PM: write daily-profile-{today}.json
- Weekly: absorb prev → archive to weekly-archive/ → rotate current→prev → write new → purge dailies
- Monthly: absorb prev month → overwrite monthly-summary.json → purge weekly-archive older than current month

### Run Tags
Write `runs/{date}-{type}.json` (e.g., `runs/2026-03-14-pm.json`) before sending email. If tag exists, skip — already ran.

## Instructions
When writing: validate against memory-schemas.md. When reading: handle missing files gracefully (bootstrap).
