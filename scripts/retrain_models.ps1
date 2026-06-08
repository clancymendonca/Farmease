param(
    [switch]$StrictRelayQuality,
    [int]$WalkForwardSplits = 6,
    [string]$Device = "auto",
    [switch]$ShowProgress
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$PythonExe = Join-Path $ProjectRoot ".venv\Scripts\python.exe"
$PredictScript = Join-Path $ProjectRoot "predict_next.py"
$DefaultsScript = Join-Path $PSScriptRoot "lib\TrainingDefaults.ps1"

if (-not (Test-Path $PythonExe)) {
    throw "Python environment not found at $PythonExe. Create .venv and install dependencies first."
}

. $DefaultsScript

$trainArgs = Get-TrainModelArgs -StrictRelayQuality:$StrictRelayQuality -WalkForwardSplits $WalkForwardSplits -Device $Device -ShowProgress:$ShowProgress

Write-Host "Running model retraining..." -ForegroundColor Cyan
Push-Location $ProjectRoot
try {
    & $PythonExe @trainArgs

    Write-Host "Running prediction smoke check..." -ForegroundColor Cyan
    & $PythonExe $PredictScript

    Write-Host "Retraining workflow completed successfully." -ForegroundColor Green
}
finally {
    Pop-Location
}
