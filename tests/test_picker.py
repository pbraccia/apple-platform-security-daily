"""Exercise the real Swift picker without changing the repository's JSON files."""

import datetime as dt
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


class PickerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temporary = tempfile.TemporaryDirectory()
        cls.addClassCleanup(cls.temporary.cleanup)
        cls.directory = Path(cls.temporary.name)
        repository = Path(__file__).resolve().parents[1]
        shutil.copy(repository / "blurbs.json", cls.directory)
        cls.blurbs = json.loads((cls.directory / "blurbs.json").read_text())
        cls.binary = cls.directory / "picker"
        cache = str(cls.directory / "module-cache")
        subprocess.run(
            ["swiftc", str(repository / "pick_blurb.swift"), "-o", str(cls.binary)],
            env={**os.environ, "CLANG_MODULE_CACHE_PATH": cache, "SWIFT_MODULECACHE_PATH": cache},
            check=True,
        )

    def run_picker(self, day):
        subprocess.run(
            [str(self.binary), day.isoformat()], cwd=self.directory,
            check=True, capture_output=True, text=True,
        )
        today = json.loads((self.directory / "today.json").read_text())
        week = json.loads((self.directory / "week.json").read_text())
        return today, week

    def test_date_window_and_entries(self):
        # Cover year rollover, leap day, and US daylight-saving transitions.
        for day in [dt.date(2027, 1, 1), dt.date(2028, 2, 29),
                    dt.date(2027, 3, 14), dt.date(2027, 11, 7)]:
            with self.subTest(day=day):
                today, week = self.run_picker(day)
                self.assertEqual(set(week), {"days"})
                self.assertEqual(
                    [entry["date"] for entry in week["days"]],
                    [(day + dt.timedelta(days=offset)).isoformat() for offset in range(-1, 7)],
                )
                self.assertEqual(today, week["days"][1])
                for entry in week["days"]:
                    blurb = {key: value for key, value in entry.items() if key != "date"}
                    self.assertIn(blurb, self.blurbs)

    def test_repeatable_output(self):
        day = dt.date(2027, 1, 1)
        self.run_picker(day)
        first = [(self.directory / name).read_bytes() for name in ["today.json", "week.json"]]
        self.run_picker(day + dt.timedelta(days=1))
        self.run_picker(day)
        self.assertEqual(
            first,
            [(self.directory / name).read_bytes() for name in ["today.json", "week.json"]],
        )

    def test_complete_rotations(self):
        count = len(self.blurbs)
        epoch = dt.date(1970, 1, 1)
        cycle = (dt.date(2027, 1, 1) - epoch).days // count
        start = epoch + dt.timedelta(days=cycle * count)
        sections = []
        for offset in range(count * 3):
            today, _ = self.run_picker(start + dt.timedelta(days=offset))
            sections.append(today["section"])
        expected = [blurb["section"] for blurb in self.blurbs]
        for offset in range(0, count * 3, count):
            self.assertCountEqual(sections[offset:offset + count], expected)
        self.assertTrue(all(a != b for a, b in zip(sections, sections[1:])))


if __name__ == "__main__":
    unittest.main()
