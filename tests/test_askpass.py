import os
from pathlib import Path
import subprocess
import tempfile
import unittest


HELPER = Path(__file__).resolve().parents[1] / "bin/dot-askpass"


class AskpassTests(unittest.TestCase):
    def run_helper(self, cancel=False):
        self.assertTrue(HELPER.is_file(), "Zenity askpass yardımcısı bulunmalı")
        with tempfile.TemporaryDirectory() as directory:
            dialog = Path(directory) / "zenity"
            dialog.write_text(
                '#!/bin/sh\n'
                '[ "$#" = 2 ] && [ "$1" = --password ] || exit 9\n'
                '[ "$2" = \'--title=Parola: $(false); "test"\' ] || exit 8\n'
                + ('exit 1\n' if cancel else "printf '%s\\n' 'dummy-test-value'\n")
            )
            dialog.chmod(0o700)
            return subprocess.run(
                [str(HELPER), 'Parola: $(false); "test"'],
                env={**os.environ, "PATH": directory + ":" + os.environ["PATH"]},
                capture_output=True, text=True,
            )

    def test_password_only_on_stdout_and_prompt_is_literal(self):
        result = self.run_helper()
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "dummy-test-value\n")
        self.assertEqual(result.stderr, "")

    def test_cancel_propagates_without_password(self):
        result = self.run_helper(cancel=True)
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stdout, "")
        self.assertEqual(result.stderr, "")


if __name__ == "__main__":
    unittest.main()
