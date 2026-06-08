param(
    [switch]$StrictRelayQuality,
    [int]$WalkForwardSplits = 6,
    [string]$Device = "auto",
    [switch]$ShowProgress,
    [switch]$SkipHealthReport,
    [switch]$FailOnHealthIssue,
    [switch]$NotifyTelegram,
    [double]$MaxTrainingAgeHours = 48,
    [int]$MinRowsUsed = 500,
    [int]$MinWalkForwardFolds = 3,
    [double]$MinClassificationF1 = 0.40,
    [double]$MaxRegressionMae = 1000,
    [string]$LogFile = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$PythonExe = Join-Path $ProjectRoot ".venv\Scripts\python.exe"
$DefaultsScript = Join-Path $PSScriptRoot "lib\TrainingDefaults.ps1"
$TrainingReportPath = Join-Path $ProjectRoot "models\training_report.json"

if (-not (Test-Path $PythonExe)) {
    throw "Python environment not found at $PythonExe. Create .venv and install dependencies first."
}

. $DefaultsScript

function Invoke-LoggedCommand {
    param(
        [string[]]$CommandArgs
    )

    if ($LogFile) {
        $logDir = Split-Path -Parent $LogFile
        if ($logDir -and -not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        & $PythonExe @CommandArgs *>&1 | Tee-Object -FilePath $LogFile -Append
        if ($LASTEXITCODE -ne 0) {
            throw "Command failed: python $($CommandArgs -join ' ')"
        }
    }
    else {
        & $PythonExe @CommandArgs
        if ($LASTEXITCODE -ne 0) {
            throw "Command failed: python $($CommandArgs -join ' ')"
        }
    }
}

Push-Location $ProjectRoot
try {
    $trainArgs = Get-TrainModelArgs -StrictRelayQuality:$StrictRelayQuality -WalkForwardSplits $WalkForwardSplits -Device $Device -ShowProgress:$ShowProgress

    Write-Host "[1/4] Retraining models..." -ForegroundColor Cyan
    Invoke-LoggedCommand -CommandArgs $trainArgs

    if (Test-Path $TrainingReportPath) {
        $report = Get-Content $TrainingReportPath -Raw | ConvertFrom-Json
        $relayModel = $report.best_models.relay_light
        $gatePassed = $report.quality_gate.relay_light.passed
        if ($relayModel) {
            Write-Host "Relay classifier: produced ($relayModel), gate=$gatePassed" -ForegroundColor Green
        }
        else {
            Write-Host "Relay classifier: skipped (quality gate failed)" -ForegroundColor Yellow
        }
    }

    Write-Host "[2/4] Running prediction smoke check..." -ForegroundColor Cyan
    Invoke-LoggedCommand -CommandArgs @("predict_next.py")

    Write-Host "[3/4] Generating event evidence..." -ForegroundColor Cyan
    Invoke-LoggedCommand -CommandArgs @("scripts\generate_event_evidence.py")

    if (-not $SkipHealthReport) {
        Write-Host "[4/4] Generating health check report..." -ForegroundColor Cyan
        $healthArgs = @(
            "scripts\generate_health_report.py",
            "--max-training-age-hours", "$MaxTrainingAgeHours",
            "--min-rows-used", "$MinRowsUsed",
            "--min-walk-forward-folds", "$MinWalkForwardFolds",
            "--min-classification-f1", "$MinClassificationF1",
            "--max-regression-mae", "$MaxRegressionMae"
        )
        if ($FailOnHealthIssue) {
            $healthArgs += "--fail-on-health-issue"
        }
        if ($StrictRelayQuality) {
            $healthArgs += "--strict-relay-quality"
        }
        if ($NotifyTelegram) {
            $healthArgs += "--notify-telegram"
        }
        Invoke-LoggedCommand -CommandArgs $healthArgs
    }
    else {
        Write-Host "[4/4] Skipping health check report (SkipHealthReport)" -ForegroundColor DarkGray
    }

    Write-Host "Retraining healthcheck workflow completed." -ForegroundColor Green
}
finally {
    Pop-Location
}
