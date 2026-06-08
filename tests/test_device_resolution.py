import unittest
from unittest.mock import MagicMock, patch

from ml.train_models import resolve_xgb_device


class DeviceResolutionTests(unittest.TestCase):
    def test_cpu_returns_cpu(self):
        self.assertEqual(resolve_xgb_device("cpu"), "cpu")

    def test_cuda_returns_cuda_string(self):
        self.assertEqual(resolve_xgb_device("cuda"), "cuda")

    def test_auto_returns_cpu_or_cuda(self):
        resolved = resolve_xgb_device("auto")
        self.assertIn(resolved, {"cpu", "cuda"})

    def test_auto_falls_back_to_cpu_when_cuda_unavailable(self):
        mock_model = MagicMock()
        mock_model.fit.side_effect = RuntimeError("cuda unavailable")
        with patch("xgboost.XGBRegressor", return_value=mock_model):
            self.assertEqual(resolve_xgb_device("auto"), "cpu")


if __name__ == "__main__":
    unittest.main()
