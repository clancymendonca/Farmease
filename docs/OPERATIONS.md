# FarmEase Operations Runbook

## Goal

Provide repeatable startup, retraining, and validation for day-to-day operation.

## Prerequisites

- Python virtual environment exists at `.venv`
- Dependencies installed from `requirements-ml.txt`
- Optional `.env` configured for Telegram integration
- Arduino/serial device connected for live dashboard mode

## Start dashboard

From PowerShell:

```powershell
.\scripts\run_dashboard.ps1
```

This script validates key paths and starts `dashboard.py` with the project venv Python.

## Retrain models (manual)

Quick retrain + predict smoke check:

```powershell
.\scripts\retrain_models.ps1
```

Full retraining healthcheck (train, predict, evidence, health report):

```powershell
.\scripts\run_retraining_healthcheck.ps1
```

Stricter relay quality gate:

```powershell
.\scripts\retrain_models.ps1 -StrictRelayQuality
```

Direct Python entry point (defaults to `--device auto`):

```powershell
python train_models.py --walk-forward-splits 6 --no-progress
python train_models.py --strict-relay-quality
```

Manual retraining runs:
1. `train_models.py` with configurable walk-forward splits
2. `predict_next.py` smoke check to verify artifacts load and infer

### Script matrix

| Script | Use when |
|--------|----------|
| `retrain_models.ps1` | Quick manual retrain + predict only |
| `run_retraining_healthcheck.ps1` | Full ops check including `docs/HEALTH_CHECK.md` |
| `event_rehearsal.ps1` | Pre-event validation (tests + retrain + evidence) |
| `install_retraining_schedule.ps1` | Enable daily scheduled retraining |
| `uninstall_retraining_schedule.ps1` | Disable scheduled retraining |

### Scheduled retraining

Install daily retraining at 2:00 AM (fails on health issues by default):

```powershell
.\scripts\install_retraining_schedule.ps1
```

Remove scheduled retraining:

```powershell
.\scripts\uninstall_retraining_schedule.ps1
```

Run immediately:

```powershell
Start-ScheduledTask -TaskName "FarmEase-RetrainingHealthcheck"
```

When Telegram is configured (`TELEGRAM_ALERTS=true`), scheduled runs can notify on health failures via `-NotifyTelegram` (enabled automatically by the install script when alerts are on).

Review health output:
- `docs/HEALTH_CHECK.md`
- `models/health_check_report.json`

### Dashboard at logon (optional)

```powershell
.\scripts\install_dashboard_service.ps1
.\scripts\uninstall_dashboard_service.ps1
```

## Validation checklist

```powershell
python -m py_compile dashboard.py telegram_notifier.py
python -m unittest discover -s tests -p "test_*.py"
```

Generate event evidence summary:

```powershell
python scripts/generate_event_evidence.py
```

## Event-day rehearsal (recommended)

Run the complete pre-event sequence in one command:

```powershell
.\scripts\event_rehearsal.ps1
```

This sequence executes:
1. Syntax checks (`py_compile`)
2. Unit tests
3. Retraining + prediction + event evidence (`docs/EVENT_EVIDENCE.md`)

Optional cloud sync during rehearsal:

```powershell
.\scripts\event_rehearsal.ps1 -WithCloudSync
```

## Optional cloud-sync worker

Cloud sync is optional and does not replace local control.

Start demo cloud ingest API (optional):

```powershell
.\scripts\run_cloud_api.ps1
```

Run one cloud sync cycle:

```powershell
.\scripts\run_cloud_sync.ps1 -Once
```

Run continuous cloud sync worker:

```powershell
.\scripts\run_cloud_sync.ps1
```

Setup notes:
- `docs/CLOUD_SYNC_PREP.md`
- `docs/CLOUD_BACKEND_SETUP.md`

Review generated artifacts:
- `models/training_report.json`
- `models/light_forecast_model.joblib`
- `models/relay_light_model.joblib` (if quality gate passes)
- `models/feature_columns.json`
- `docs/EVENT_EVIDENCE.md`
- `docs/HEALTH_CHECK.md`

## Operational notes

- Set `FARMEASE_SERIAL_PORT` in `.env` if your Arduino is not on `COM3`.
- Generated logs under `data/` are local runtime artifacts and should stay untracked.
- If relay class balance degrades, retraining may skip relay classifier by design.
- Prefer walk-forward fold consistency over one-shot split metrics when selecting production models.
