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
# Prevent non-zero exit codes from the Copilot CLI from throwing terminating errors
# on PowerShell 7.4+ (where $PSNativeCommandUseErrorActionPreference defaults to $true).
# The CLI sometimes exits non-zero even on successful delivery; subsequent blocks must run.
$PSNativeCommandUseErrorActionPreference = $false

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
    Write-Error "[Dayarc] ERROR: Cannot find agent package. Reinstall with: copilot plugin install YuiZhou/dayarc-agent"
    exit 1
}

# ── Resolve agent name ───────────────────────────────────────────────────────
# Plugin-level agents use "dayarc:dayarc"; user-level agents use "dayarc"
if ($pluginHit) {
    $agentName = "dayarc:dayarc"
} else {
    $agentName = "dayarc"
}

$profileDir = Join-Path ([Environment]::GetFolderPath('MyDocuments')) "dayarc"

# ── Logging ──────────────────────────────────────────────────────────────────
# Task Scheduler runs without a console — Write-Host output is lost.
# Log to ~/Documents/dayarc/logs/{date}-{trigger}.log for diagnostics.
$logDir = Join-Path $profileDir "logs"
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
$logFile = Join-Path $logDir "$(Get-Date -Format 'yyyy-MM-dd')-$trigger.log"

function Log([string]$msg) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$ts  $msg" | Tee-Object -FilePath $logFile -Append
}

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

Log "[Dayarc] Trigger: $trigger | Date: $($today.ToString('yyyy-MM-dd')) | Agent: $agentName"

Push-Location $profileDir

if ($trigger -eq "am") {
    Log "[Dayarc] Running AM brief..."
    try {
        & copilot --agent=$agentName --allow-all --prompt "$agentDir\prompts\am.md" 2>&1 | Tee-Object -FilePath $logFile -Append
    } catch {
        Log "[Dayarc] WARNING: copilot exited non-zero during AM brief: $_"
    }
}

if ($trigger -eq "pm") {
    Log "[Dayarc] Running PM brief..."
    try {
        & copilot --agent=$agentName --allow-all --prompt "$agentDir\prompts\pm.md" 2>&1 | Tee-Object -FilePath $logFile -Append
    } catch {
        Log "[Dayarc] WARNING: copilot exited non-zero during PM brief: $_"
    }

    if ($today.DayOfWeek -eq [DayOfWeek]::Friday) {
        Log "[Dayarc] Friday -- running Weekly brief..."
        try {
            & copilot --agent=$agentName --allow-all --prompt "$agentDir\prompts\weekly.md" 2>&1 | Tee-Object -FilePath $logFile -Append
        } catch {
            Log "[Dayarc] WARNING: copilot exited non-zero during Weekly brief: $_"
        }

        if (Is-LastWorkday $today) {
            Log "[Dayarc] Last workday of month -- running Monthly brief..."
            try {
                & copilot --agent=$agentName --allow-all --prompt "$agentDir\prompts\monthly.md" 2>&1 | Tee-Object -FilePath $logFile -Append
            } catch {
                Log "[Dayarc] WARNING: copilot exited non-zero during Monthly brief: $_"
            }
        }
    } elseif (Is-LastWorkday $today) {
        Log "[Dayarc] Last workday of month (non-Friday) -- running Weekly + Monthly..."
        try {
            & copilot --agent=$agentName --allow-all --prompt "$agentDir\prompts\weekly.md" 2>&1 | Tee-Object -FilePath $logFile -Append
        } catch {
            Log "[Dayarc] WARNING: copilot exited non-zero during Weekly brief: $_"
        }
        try {
            & copilot --agent=$agentName --allow-all --prompt "$agentDir\prompts\monthly.md" 2>&1 | Tee-Object -FilePath $logFile -Append
        } catch {
            Log "[Dayarc] WARNING: copilot exited non-zero during Monthly brief: $_"
        }
    }
}

Pop-Location

Log "[Dayarc] Done."
