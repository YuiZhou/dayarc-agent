<#
.SYNOPSIS
    Dayarc — Scheduler Script
.DESCRIPTION
    Triggers AM or PM briefs via Copilot CLI. Run via Task Scheduler on weekdays.
.PARAMETER trigger
    "am" for morning brief, "pm" for evening brief (+ weekly/monthly on Fridays).
.EXAMPLE
    .\scheduler.ps1 -trigger am
    .\scheduler.ps1 -trigger pm
.NOTES
    Register with Task Scheduler:
      AM: schtasks /create /tn "Dayarc-AM" /tr "powershell -File C:\path\to\scheduler.ps1 -trigger am" /sc weekly /d MON,TUE,WED,THU,FRI /st 08:00
      PM: schtasks /create /tn "Dayarc-PM" /tr "powershell -File C:\path\to\scheduler.ps1 -trigger pm" /sc weekly /d MON,TUE,WED,THU,FRI /st 20:00
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("am", "pm")]
    [string]$trigger
)

$ErrorActionPreference = "Stop"

# ── Discover agent package location ──────────────────────────────────────────
# Plugin install: lives under ~/.copilot/installed-plugins/
# Git clone:      lives at ~/.dayarc-agent/
$agentDir = $null

# Check plugin install first
$pluginHit = Get-ChildItem -Path (Join-Path $HOME ".copilot\installed-plugins") -Filter "scheduler.ps1" -Recurse -ErrorAction SilentlyContinue |
    Where-Object { (Split-Path $_.DirectoryName -Leaf) -ne "skills" } |
    Select-Object -First 1
if ($pluginHit) {
    $agentDir = $pluginHit.DirectoryName
}

# Fall back to git clone
if (-not $agentDir) {
    $cloneDir = Join-Path $HOME ".dayarc-agent"
    if (Test-Path (Join-Path $cloneDir "scheduler.ps1")) {
        $agentDir = $cloneDir
    }
}

if (-not $agentDir) {
    Write-Host "[Dayarc] ERROR: Cannot find agent package. Reinstall with: copilot plugin install YuiZhou/dayarc-agent"
    exit 1
}

$profileDir = Join-Path ([Environment]::GetFolderPath('MyDocuments')) "dayarc"

function Is-LastWorkday {
    param([DateTime]$date)
    $lastDay = [DateTime]::DaysInMonth($date.Year, $date.Month)
    $check = [DateTime]::new($date.Year, $date.Month, $lastDay)
    while ($check.DayOfWeek -eq [DayOfWeek]::Saturday -or $check.DayOfWeek -eq [DayOfWeek]::Sunday) {
        $check = $check.AddDays(-1)
    }
    return $date.Date -eq $check.Date
}

$today = Get-Date

Write-Host "[Dayarc] Trigger: $trigger | Date: $($today.ToString('yyyy-MM-dd'))"

Push-Location $profileDir

if ($trigger -eq "am") {
    Write-Host "[Dayarc] Running AM brief..."
    copilot --agent=dayarc --prompt "$agentDir\prompts\am.md"
}

if ($trigger -eq "pm") {
    Write-Host "[Dayarc] Running PM brief..."
    copilot --agent=dayarc --prompt "$agentDir\prompts\pm.md"

    if ($today.DayOfWeek -eq [DayOfWeek]::Friday) {
        Write-Host "[Dayarc] Friday -- running Weekly brief..."
        copilot --agent=dayarc --prompt "$agentDir\prompts\weekly.md"

        if (Is-LastWorkday $today) {
            Write-Host "[Dayarc] Last workday of month -- running Monthly brief..."
            copilot --agent=dayarc --prompt "$agentDir\prompts\monthly.md"
        }
    } elseif (Is-LastWorkday $today) {
        Write-Host "[Dayarc] Last workday of month (non-Friday) -- running Weekly + Monthly..."
        copilot --agent=dayarc --prompt "$agentDir\prompts\weekly.md"
        copilot --agent=dayarc --prompt "$agentDir\prompts\monthly.md"
    }
}

Pop-Location

Write-Host "[Dayarc] Done."
