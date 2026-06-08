Set-StrictMode -Version Latest

$Script:DefaultWalkForwardSplits = 6
$Script:DefaultDevice = "auto"

function Get-TrainModelArgs {
    param(
        [switch]$StrictRelayQuality,
        [int]$WalkForwardSplits = $Script:DefaultWalkForwardSplits,
        [string]$Device = $Script:DefaultDevice,
        [switch]$ShowProgress
    )

    $args = @(
        "train_models.py",
        "--walk-forward-splits", "$WalkForwardSplits",
        "--device", $Device
    )

    if (-not $ShowProgress) {
        $args += "--no-progress"
    }

    if ($StrictRelayQuality) {
        $args += "--strict-relay-quality"
    }

    return $args
}
