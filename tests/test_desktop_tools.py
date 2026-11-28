import os
import subprocess
import tempfile
import unittest
from pathlib import Path

BIN = Path(__file__).resolve().parents[1] / 'bin'

class DesktopTools(unittest.TestCase):
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

    def test_panel_actions_merge_hide_and_reject_bad_commands(self):
        with tempfile.TemporaryDirectory() as tmp:
            cfg = Path(tmp)/'dot-panel'; cfg.mkdir()
            (cfg/'actions.json').write_text('[{"id":"lock","hide":true},{"id":"x","label":"X","cmd":["true"]},'
                                            '{"id":"bad","cmd":"rm -rf ~"},{"id":"mic","label":"Mic"}]')
            r = subprocess.run([str(BIN/'dot-panel'), 'actions'], capture_output=True, text=True,
                               env=dict(os.environ, XDG_CONFIG_HOME=tmp))
            self.assertEqual(r.returncode, 0, r.stderr)
            ids = [l.split()[0] for l in r.stdout.splitlines()]
            self.assertNotIn('lock', ids); self.assertNotIn('bad', ids)
            self.assertEqual(ids[-1], 'x')
            self.assertIn('wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle', r.stdout)

    def test_panel_refuses_foreign_hosts_and_bare_posts(self):
        import socket, time, urllib.request, urllib.error
        with socket.socket() as s:
            s.bind(('127.0.0.1', 0)); port = s.getsockname()[1]
        with tempfile.TemporaryDirectory() as tmp:
            env = dict(os.environ, DOT_PANEL_PORT=str(port), XDG_CONFIG_HOME=tmp, DOT_PANEL_NO_ADB='1')
            srv = subprocess.Popen([str(BIN/'dot-panel')], env=env, stderr=subprocess.DEVNULL)
            try:
                def code(path, method='GET', headers=None):
                    req = urllib.request.Request(f'http://127.0.0.1:{port}{path}', method=method, headers=headers or {})
                    try:
                        return urllib.request.urlopen(req, timeout=2).status
                    except urllib.error.HTTPError as e:
                        return e.code
                for _ in range(50):
                    try:
                        code('/api/themes'); break
                    except OSError:
                        time.sleep(0.1)
                self.assertEqual(code('/api/themes'), 200)
                self.assertEqual(code('/api/themes', headers={'Host': 'evil.example'}), 403)
                self.assertEqual(code('/api/action/x', 'POST'), 403)
                self.assertEqual(code('/api/action/nope', 'POST', {'X-Dot-Panel': '1'}), 404)
                self.assertEqual(code('/api/theme/..%2fx', 'POST', {'X-Dot-Panel': '1'}), 404)
                self.assertEqual(code('/../bin/dot-panel'), 404)
            finally:
                srv.terminate(); srv.wait(5)

if __name__ == '__main__': unittest.main()
