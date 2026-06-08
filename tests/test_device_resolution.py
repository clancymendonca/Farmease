import unittest

from ml.train_models import resolve_xgb_device


class DeviceResolutionTests(unittest.TestCase):
    def test_cpu_returns_cpu(self):
        self.assertEqual(resolve_xgb_device("cpu"), "cpu")

    def test_cuda_returns_cuda_string(self):
        self.assertEqual(resolve_xgb_device("cuda"), "cuda")

    def test_auto_returns_cpu_or_cuda(self):
        resolved = resolve_xgb_device("auto")
        self.assertIn(resolved, {"cpu", "cuda"})


if __name__ == "__main__":
    unittest.main()
