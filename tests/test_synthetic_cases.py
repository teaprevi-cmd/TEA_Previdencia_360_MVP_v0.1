import json, unittest
from pathlib import Path

class SyntheticCaseTests(unittest.TestCase):
    def test_five_synthetic_cases_exist_and_are_synthetic(self):
        root = Path(__file__).resolve().parents[1] / "synthetic_cases"
        cases = sorted(root.glob("TEST-*.json"))
        self.assertEqual(len(cases), 5)
        for path in cases:
            data = json.loads(path.read_text())
            self.assertIs(data["synthetic"], True)
            self.assertIn("expected", data)

if __name__ == "__main__":
    unittest.main()
