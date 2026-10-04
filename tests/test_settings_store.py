import sys,unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'lib'))
from settings_store import set_node,scalar,rebind,nodes,set_toml_values
class SettingsTests(unittest.TestCase):
 def test_preserves_other_input_and_comments(self):
  s='// hello\ninput { keyboard { repeat-rate 35; } touchpad { tap; } }\nlayout { gaps 12; }'
  changed=set_node(s,['input','keyboard','repeat-rate'],'repeat-rate 40')
  self.assertIn('touchpad { tap; }',changed);self.assertIn('// hello',changed)
  self.assertEqual(scalar(changed,['input','keyboard','repeat-rate'],0),40)
 def test_add_nested_and_remove_flag(self):
  s=set_node('input { touchpad { tap; natural-scroll; } }',['input','mouse','accel-speed'],'accel-speed 0.3')
  self.assertEqual(scalar(s,['input','mouse','accel-speed'],0.0),0.3)
  self.assertNotIn('natural-scroll',set_node(s,['input','touchpad','natural-scroll'],None))
 def test_rebind_preserves_action_and_detects_order_alias(self):
  s='binds { Mod+P { spawn "a{b}"; }\n Mod+Shift+X { quit; } }'
  self.assertIn('Mod+Z { spawn "a{b}"; }',rebind(s,'Mod+P','Super+Z'))
  with self.assertRaises(ValueError):rebind(s,'Mod+P','Shift+Super+X')
 def test_power_update_preserves_other_settings(self):
  import tomllib
  text='[idle.behavior.lock]\nenabled = false\ntimeout = 600\naction = "lock"\n[shell]\nvalue = 1\n'
  data=tomllib.loads(set_toml_values(text,'idle.behavior.lock',{'enabled':True,'timeout':900}))
  self.assertEqual(data['idle']['behavior']['lock'],{'enabled':True,'timeout':900,'action':'lock'})
  self.assertEqual(data['shell']['value'],1)
 def test_raw_regex_not_a_block(self):
  self.assertEqual(len(list(nodes('window-rule { match app-id=r#"a{b}"#; }\nlayout { gaps 1; }'))),2)
if __name__=='__main__':unittest.main()
