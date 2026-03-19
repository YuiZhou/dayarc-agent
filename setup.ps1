<#
.SYNOPSIS
    Dayarc — One-line installer and upgrader.
.DESCRIPTION
    Install:    irm https://raw.githubusercontent.com/YuiZhou/dayarc-agent/main/setup.ps1 | iex
    Uninstall:  setup.ps1 -uninstall
.NOTES
    Idempotent — re-running performs an upgrade (git pull) and skips already-configured steps.
#>

param(
    [switch]$uninstall
)

$ErrorActionPreference = "Stop"

$agentDir  = Join-Path $HOME ".dayarc-agent"
$docsDir   = [Environment]::GetFolderPath("MyDocuments")
$dataDir   = Join-Path $docsDir "dayarc"
$configFile = Join-Path $dataDir "config.json"
$repoUrl   = "https://github.com/YuiZhou/dayarc-agent.git"

# ── Helpers ──────────────────────────────────────────────────────────────────

function Write-Step { param([string]$msg) Write-Host "`n▸ $msg" -ForegroundColor Cyan }
function Write-Ok   { param([string]$msg) Write-Host "  ✓ $msg" -ForegroundColor Green }
function Write-Skip { param([string]$msg) Write-Host "  ⏭ $msg" -ForegroundColor DarkGray }
function Write-Err  { param([string]$msg) Write-Host "  ✗ $msg" -ForegroundColor Red }

# ── Uninstall ────────────────────────────────────────────────────────────────

if ($uninstall) {
    Write-Host "`nDayarc — Uninstall" -ForegroundColor Yellow

    # Remove scheduler tasks
    foreach ($name in @("Dayarc-AM", "Dayarc-PM")) {
        $task = Get-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue
        if ($task) {
            Unregister-ScheduledTask -TaskName $name -Confirm:$false
            Write-Ok "Removed scheduler task: $name"
        }
    }

    # Remove agent directory
    if (Test-Path $agentDir) {
        Remove-Item $agentDir -Recurse -Force
        Write-Ok "Removed $agentDir"
    }

    Write-Host "`nUser data preserved at: $dataDir" -ForegroundColor DarkGray
    Write-Host "To remove user data too: Remove-Item '$dataDir' -Recurse -Force`n" -ForegroundColor DarkGray
    return
}

# ── Preflight ────────────────────────────────────────────────────────────────

Write-Host "`n╔══════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host   "║        Dayarc — Setup                ║" -ForegroundColor Cyan
Write-Host   "╚══════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Step "Preflight checks"

# Git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Err "git is not installed. Install Git for Windows: https://git-scm.com"
    return
}
Write-Ok "git found"

# GitHub CLI
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Err "GitHub CLI (gh) is not installed. Install: winget install GitHub.cli"
    return
}
$ghStatus = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Err "GitHub CLI is not authenticated. Run: gh auth login"
    return
}
Write-Ok "gh authenticated"

# Copilot CLI
$copilotCmd = Get-Command copilot -ErrorAction SilentlyContinue
if (-not $copilotCmd) {
    Write-Err "Copilot CLI is not installed. Install from: https://githubnext.com/projects/copilot-cli"
    return
}
Write-Ok "Copilot CLI found"

# Outlook (soft check)
$outlook = Get-Process OUTLOOK -ErrorAction SilentlyContinue
if ($outlook) {
    Write-Ok "Outlook is running"
} else {
    Write-Host "  ⚠ Outlook is not running (needed for sending email briefs)" -ForegroundColor Yellow
}

# ── Clone or Pull ────────────────────────────────────────────────────────────

Write-Step "Agent package → $agentDir"

if (Test-Path (Join-Path $agentDir ".git")) {
    # Existing install — upgrade
    Write-Host "  Existing install detected — pulling updates..." -ForegroundColor DarkGray
    Push-Location $agentDir
    try {
        git fetch origin main 2>&1 | Out-Null
        $local  = git rev-parse HEAD
        $remote = git rev-parse origin/main
        if ($local -eq $remote) {
            Write-Ok "Already up to date ($($local.Substring(0,7)))"
        } else {
            $result = git pull --ff-only origin main 2>&1
            if ($LASTEXITCODE -eq 0) {
                $newCommits = git log "$local..HEAD" --oneline
                Write-Ok "Updated: $($newCommits.Count) new commit(s)"
                $newCommits | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
            } else {
                Write-Err "Fast-forward failed — local changes detected"
                Write-Host "    Run: Remove-Item '$agentDir' -Recurse -Force" -ForegroundColor DarkGray
                Write-Host "    Then re-run this setup script." -ForegroundColor DarkGray
                Pop-Location
                return
            }
        }
    } finally {
        Pop-Location
    }
} else {
    # Fresh install
    if (Test-Path $agentDir) {
        Write-Host "  Removing non-git directory at $agentDir..." -ForegroundColor DarkGray
        Remove-Item $agentDir -Recurse -Force
    }
    git clone $repoUrl $agentDir 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Clone failed. Check network and repo access."
        return
    }
    $hash = (git -C $agentDir rev-parse --short HEAD)
    Write-Ok "Cloned ($hash)"
}

# ── Symlink agent + skills into ~/.copilot/ ──────────────────────────────────

Write-Step "Registering with Copilot CLI"

$copilotDir = Join-Path $HOME ".copilot"
$copilotAgents = Join-Path $copilotDir "agents"
$copilotSkills = Join-Path $copilotDir "skills"

# Ensure directories exist
foreach ($d in @($copilotAgents, $copilotSkills)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

# Copy agent profile
Copy-Item (Join-Path $agentDir "agents\dayarc.agent.md") (Join-Path $copilotAgents "dayarc.agent.md") -Force
Write-Ok "Agent profile → ~/.copilot/agents/dayarc.agent.md"

# Copy skills
$skillSrc = Join-Path $agentDir "skills"
Get-ChildItem $skillSrc -Directory | ForEach-Object {
    $dest = Join-Path $copilotSkills $_.Name
    if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
    Copy-Item $_.FullName $dest -Recurse -Force
}
$skillCount = (Get-ChildItem $skillSrc -Directory).Count
Write-Ok "$skillCount skills → ~/.copilot/skills/"

# ── User config ──────────────────────────────────────────────────────────────

Write-Step "User data → $dataDir"

# Detect OneDrive — Documents folder outside $HOME\Documents means OneDrive redirect
$isOneDrive = $docsDir -ne (Join-Path $HOME "Documents")

if (Test-Path $dataDir) {
    Write-Skip "Data directory already exists"
} elseif ($isOneDrive) {
    # OneDrive: folder may still be syncing from another machine.
    # Creating it here would cause OneDrive to produce a conflict copy (dayarc-<computername>).
    # Wait for sync instead.
    Write-Host ""
    Write-Host "  OneDrive detected: $docsDir" -ForegroundColor DarkGray
    Write-Host "  The folder ~/Documents/dayarc/ does not exist yet." -ForegroundColor Yellow
    Write-Host ""
    $isFirst = Read-Host "    Is this the first machine you're setting up Dayarc on? [y/N]"
    if ($isFirst -match '^[Yy]') {
        New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $dataDir "memory") -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $dataDir "memory\daily") -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $dataDir "memory\runs") -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $dataDir "memory\weekly-archive") -Force | Out-Null
        Write-Ok "Created data directories"
    } else {
        Write-Host ""
        Write-Host "  Wait for OneDrive to sync the folder from your other machine," -ForegroundColor Yellow
        Write-Host "  then re-run this setup. The folder will appear at:" -ForegroundColor Yellow
        Write-Host "    $dataDir" -ForegroundColor White
        Write-Host ""
        return
    }
} else {
    # No OneDrive — safe to create immediately
    New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $dataDir "memory") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $dataDir "memory\daily") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $dataDir "memory\runs") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $dataDir "memory\weekly-archive") -Force | Out-Null
    Write-Ok "Created data directories"
}

if (Test-Path $configFile) {
    Write-Skip "config.json already exists — keeping your settings"
} else {
    Write-Host ""
    Write-Host "  Let's set up your identity:" -ForegroundColor White

    $displayName = Read-Host "    Full name as it appears in @mentions (e.g. Yu Zhou, not a nickname)"
    $email       = Read-Host "    Work email address"
    $ghUsers     = Read-Host "    GitHub username(s), comma-separated if multiple"
    $ghUserList  = @($ghUsers -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })

    $config = @{
        user = @{
            display_name     = $displayName
            email            = $email
            github_usernames = $ghUserList
        }
        preferences = @{
            brief_max_items     = 15
            priority_max_items  = 5
            unfinished_max_items = 5
            signal_max_items    = 10
            plan_max_items      = 8
            learning_items      = 5
            drift_max_items     = 3
        }
        scheduler = @(
            @{
                machine = ""
                am_time = "08:00"
                pm_time = "20:00"
            }
        )
    }

    # Ensure directory exists (handles edge cases like OneDrive paths)
    $configDir = Split-Path $configFile -Parent
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }
    $config | ConvertTo-Json -Depth 3 | Set-Content $configFile -Encoding UTF8
    Write-Ok "Wrote config.json"
}

# ── Scheduler (optional) ─────────────────────────────────────────────────────

Write-Step "Scheduler (optional)"

$existingAM = Get-ScheduledTask -TaskName "Dayarc-AM" -ErrorAction SilentlyContinue
$existingPM = Get-ScheduledTask -TaskName "Dayarc-PM" -ErrorAction SilentlyContinue

if ($existingAM -and $existingPM) {
    Write-Skip "Scheduler tasks already registered (Dayarc-AM, Dayarc-PM)"
} else {
    $install = Read-Host "    Install daily scheduler? (AM 8:00 + PM 20:00, Mon-Fri) [y/N]"
    if ($install -match '^[Yy]') {
        $schedulerScript = Join-Path $agentDir "scheduler.ps1"

        $action_am  = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -File `"$schedulerScript`" -trigger am"
        $action_pm  = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -File `"$schedulerScript`" -trigger pm"
        $trigger_am = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday,Tuesday,Wednesday,Thursday,Friday -At 8:00AM
        $trigger_pm = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday,Tuesday,Wednesday,Thursday,Friday -At 8:00PM
        $settings   = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

        Register-ScheduledTask -TaskName "Dayarc-AM" -Action $action_am -Trigger $trigger_am -Settings $settings -Description "Dayarc morning brief" | Out-Null
        Register-ScheduledTask -TaskName "Dayarc-PM" -Action $action_pm -Trigger $trigger_pm -Settings $settings -Description "Dayarc evening brief" | Out-Null

        Write-Ok "Scheduled: Dayarc-AM (8:00) + Dayarc-PM (20:00), Mon-Fri"

        # Record this machine's scheduler entry in config.json
        if (Test-Path $configFile) {
            $cfg = Get-Content $configFile -Raw | ConvertFrom-Json
            $entry = [PSCustomObject]@{ machine = $env:COMPUTERNAME; am_time = "08:00"; pm_time = "20:00" }
            if (-not $cfg.scheduler) {
                $cfg | Add-Member -NotePropertyName "scheduler" -NotePropertyValue @($entry)
            } else {
                $existing = @($cfg.scheduler) | Where-Object { $_.machine -eq $env:COMPUTERNAME }
                if ($existing) {
                    $existing.am_time = "08:00"
                    $existing.pm_time = "20:00"
                } else {
                    $cfg.scheduler = @($cfg.scheduler) + $entry
                }
            }
            $cfg | ConvertTo-Json -Depth 3 | Set-Content $configFile -Encoding UTF8
        }
    } else {
        Write-Skip "Skipped — run setup again anytime to add it"
    }
}

# ── Done ─────────────────────────────────────────────────────────────────────

$version = git -C $agentDir describe --tags --always 2>$null
if (-not $version) { $version = git -C $agentDir rev-parse --short HEAD }

Write-Host "`n╔══════════════════════════════════════╗" -ForegroundColor Green
Write-Host   "║        Dayarc installed ✓            ║" -ForegroundColor Green
Write-Host   "╚══════════════════════════════════════╝" -ForegroundColor Green
Write-Host   "  Version:  $version"
Write-Host   "  Agent:    $agentDir"
Write-Host   "  Data:     $dataDir"
Write-Host   "  Start:    copilot --agent=dayarc"
Write-Host   ""
