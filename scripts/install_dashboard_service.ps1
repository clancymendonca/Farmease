param(
    [string]$TaskName = "FarmEase-Dashboard",
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$RunnerScript = Join-Path $PSScriptRoot "run_dashboard.ps1"

if (-not (Test-Path $RunnerScript)) {
    throw "Runner script not found at $RunnerScript"
}

try {
    $existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
    if (-not $Force) {
        throw "Task '$TaskName' already exists. Re-run with -Force to replace it."
    }
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}
catch {
    if ($_.Exception.Message -notlike "*cannot find the file specified*") {
        if (-not $Force) {
            throw
        }
    }
}

$argumentParts = @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", "`"$RunnerScript`""
)

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument ($argumentParts -join " ") -WorkingDirectory $ProjectRoot
$trigger = New-ScheduledTaskTrigger -AtLogOn
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Description "FarmEase dashboard at user logon"

Write-Host "Scheduled task '$TaskName' created to run dashboard at logon." -ForegroundColor Green
