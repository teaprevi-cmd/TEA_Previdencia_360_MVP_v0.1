import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

TARGETS = [
    "synthetic_cases",
    "docs/ux",
    "INSTRUCTIONS.md",
    "BASE_CONHECIMENTO.md",
]

EXTENSIONS = {".md", ".json", ".html"}

PATTERNS = [
    re.compile(r"(?<!\d)(?:\d{3}\.?\d{3}\.?\d{3}-?\d{2})(?!\d)"),
    re.compile(r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b"),
    re.compile(
        r"(?<!\d)(?:\+?55\s?)?(?:\(\d{2}\)|\d{2})\s?9?\d{4}[-\s]\d{4}(?!\d)"
    ),
]


class TestNoPII(unittest.TestCase):
    def assert_no_pii(self, text, path):
        for pattern in PATTERNS:
            match = pattern.search(text)
            if match:
                self.fail(f"Possible PII in {path}: {match.group(0)}")

    def test_targets(self):
        files = []

        for target in TARGETS:
            p = ROOT / target
            if p.is_file():
                files.append(p)
            elif p.is_dir():
                for f in p.rglob("*"):
                    if f.is_file() and f.suffix in EXTENSIONS:
                        files.append(f)

        self.assertTrue(files, "No files found to scan")

        for f in files:
            text = f.read_text(encoding="utf-8", errors="ignore")
            self.assert_no_pii(text, f.relative_to(ROOT))


if __name__ == "__main__":
    unittest.main()
