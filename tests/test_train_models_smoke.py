import json
import tempfile
import unittest
from pathlib import Path

import pandas as pd

from ml.train_models import train_pipeline


class TrainModelsSmokeTests(unittest.TestCase):
    def _write_synthetic_dataset(self, path: Path, rows: int = 120) -> None:
        timestamps = pd.date_range("2026-01-01", periods=rows, freq="min")
        frame = pd.DataFrame(
            {
                "timestamp": timestamps.strftime("%Y-%m-%dT%H:%M:%S"),
                "temp_c": [25.0 + (index % 5) for index in range(rows)],
                "humidity_pct": [55.0 + (index % 3) for index in range(rows)],
                "soil_adc": [1800 - index for index in range(rows)],
                "light_lux": [100.0 + index for index in range(rows)],
                "relay_light": [index % 2 for index in range(rows)],
                "relay_fan": [0] * rows,
                "relay_pump": [0] * rows,
                "relay_buzzer": [0] * rows,
                "flame_detected": [0] * rows,
                "ir_detected": [0] * rows,
                "automation_on": [1] * rows,
            }
        )
        frame.to_csv(path, index=False)

    def test_train_pipeline_smoke_cpu(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            data_path = temp_root / "greenhouse_training_data.csv"
            output_dir = temp_root / "models"
            self._write_synthetic_dataset(data_path)

            report = train_pipeline(
                dataset_path=data_path,
                output_dir=output_dir,
                horizon_steps=1,
                train_ratio=0.8,
                random_state=42,
                device="cpu",
                requested_device="cpu",
                model_family="all",
                show_progress=False,
                walk_forward_splits=2,
                min_relay_class_count=5,
                strict_relay_quality=False,
            )

            self.assertTrue((output_dir / "light_forecast_model.joblib").exists())
            self.assertTrue((output_dir / "feature_columns.json").exists())
            self.assertTrue((output_dir / "training_report.json").exists())
            self.assertEqual(report["resolved_device"], "cpu")
            self.assertIn("completed_at_utc", report)


if __name__ == "__main__":
    unittest.main()
