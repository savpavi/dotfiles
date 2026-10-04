import importlib.util
from pathlib import Path
import tempfile
import unittest

spec=importlib.util.spec_from_file_location('desktop_panels',Path(__file__).resolve().parents[1]/'lib/desktop_panels.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)

class PanelTests(unittest.TestCase):
    def test_never_run_success_is_not_healthy(self):
        self.assertEqual(m.backup_status({'Result':'success','ActiveState':'inactive'},True,None,100000,3600),'UNKNOWN')
    def test_old_success_and_missing_timer_remain_visible(self):
        self.assertEqual(m.backup_status({'Result':'success'},True,1,10000,3600),'STALE')
        self.assertEqual(m.backup_status({'Result':'success'},False,9000,10000,3600),'TIMER OFF')
    def test_failed_run_is_not_masked_by_old_success(self):
        self.assertEqual(m.backup_status({'Result':'exit-code'},True,9000,10000,3600),'FAILED')
    def test_concurrent_note_edit_is_not_overwritten(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/'note.md';p.write_text('changed elsewhere')
            with self.assertRaises(RuntimeError):m.save_note(p,b'old',b'new')
            self.assertEqual(p.read_text(),'changed elsewhere')
    def test_note_save_preserves_permissions_and_text(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/'note.md';p.write_text('old');p.chmod(0o640)
            m.save_note(p,b'old','Türkçe\n'.encode())
            self.assertEqual(p.read_text(),'Türkçe\n');self.assertEqual(p.stat().st_mode&0o777,0o640)
if __name__=='__main__':unittest.main()
