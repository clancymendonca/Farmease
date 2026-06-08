param(
    [switch]$WithCloudSync
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$PythonExe = Join-Path $ProjectRoot ".venv\Scripts\python.exe"
$HealthcheckScript = Join-Path $PSScriptRoot "run_retraining_healthcheck.ps1"
$CloudSyncScript = Join-Path $PSScriptRoot "run_cloud_sync.ps1"

if (-not (Test-Path $PythonExe)) {
    throw "Python environment not found at $PythonExe. Create .venv and install dependencies first."
}

Push-Location $ProjectRoot
try {
    Write-Host "[1/3] Running syntax checks..." -ForegroundColor Cyan
    & $PythonExe -m py_compile dashboard.py telegram_notifier.py
    if ($LASTEXITCODE -ne 0) { throw "Syntax check failed" }

    Write-Host "[2/3] Running unit tests..." -ForegroundColor Cyan
    & $PythonExe -m unittest discover -s tests -p "test_*.py"
    if ($LASTEXITCODE -ne 0) { throw "Unit tests failed" }

    Write-Host "[3/3] Running retraining + prediction + evidence..." -ForegroundColor Cyan
    & $HealthcheckScript -SkipHealthReport
    if ($LASTEXITCODE -ne 0) { throw "Retraining smoke test failed" }

    if ($WithCloudSync) {
        Write-Host "[Optional] Running one cloud sync cycle..." -ForegroundColor Cyan
        & $CloudSyncScript -Once
        if ($LASTEXITCODE -ne 0) { throw "Cloud sync failed" }
    }

    Write-Host "Event rehearsal completed successfully." -ForegroundColor Green
}
finally {
    Pop-Location
}
