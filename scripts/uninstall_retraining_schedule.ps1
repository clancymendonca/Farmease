param(
    [string]$TaskName = "FarmEase-RetrainingHealthcheck"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

try {
    $existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "Removed scheduled task '$TaskName'." -ForegroundColor Green
}
catch {
    if ($_.Exception.Message -like "*cannot find the file specified*") {
        Write-Host "Scheduled task '$TaskName' was not found; nothing to remove." -ForegroundColor Yellow
    }
    else {
        throw
    }
}
