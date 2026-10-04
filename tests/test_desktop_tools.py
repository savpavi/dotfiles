import os
import subprocess
import tempfile
import unittest
from pathlib import Path

BIN = Path(__file__).resolve().parents[1] / 'bin'

class DesktopTools(unittest.TestCase):
    def test_record_rejects_invalid_geometry_before_touching_session(self):
        r = subprocess.run([str(BIN/'dot-record'), '--geometry', 'invalid'], capture_output=True, text=True)
        self.assertEqual(r.returncode, 2)
        self.assertIn('geometry', r.stderr)

    def test_webapp_rejects_non_web_urls(self):
        with tempfile.TemporaryDirectory() as tmp:
            r = subprocess.run([str(BIN/'dot-webapp'), 'Test', 'file:///etc/passwd', '--directory', tmp], capture_output=True)
            self.assertNotEqual(r.returncode, 0)
            self.assertEqual(list(Path(tmp).iterdir()), [])

    def test_webapp_handles_exec_metacharacters_and_never_overwrites(self):
        with tempfile.TemporaryDirectory() as tmp:
            args = [str(BIN/'dot-webapp'), 'Example', 'https://example.com/?q=%20&v=$HOME', '--directory', tmp]
            r = subprocess.run(args, capture_output=True, text=True)
            self.assertEqual(r.returncode, 0, r.stderr)
            p = Path(tmp)/'webapp-example.desktop'
            content = p.read_text()
            self.assertIn('%%20', content)
            self.assertEqual(subprocess.run(['desktop-file-validate', str(p)], capture_output=True).returncode, 0)
            again = subprocess.run(args, capture_output=True)
            self.assertNotEqual(again.returncode, 0)
            self.assertEqual(p.read_text(), content)

if __name__ == '__main__': unittest.main()
