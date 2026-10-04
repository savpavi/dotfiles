"""Comment-preserving edits and verified snapshots for the desktop settings GUI."""
import datetime,json,os,re,shutil,subprocess,tempfile
from pathlib import Path

# Skip strings and comments while locating KDL blocks (including Niri raw regex strings).
TOKEN=re.compile(r'//[^\n]*|/\*.*?\*/|r(?P<h>#+)".*?"(?P=h)|"(?:\\.|[^"\\])*"|[{};\n]|[^\s{};"/]+|/',re.S)

def nodes(text,start=0,end=None):
 end=len(text) if end is None else end
 tokens=list(TOKEN.finditer(text,start,end));i=0
 while i<len(tokens):
  t=tokens[i];v=t.group();i+=1
  if v.startswith(('//','/*')) or v in (';','\n'):continue
  if v=='}':break
  begin=t.start();name=v;opening=None;closing=None;finish=t.end()
  while i<len(tokens):
   x=tokens[i];i+=1;v=x.group();finish=x.end()
   if v.startswith(('//','/*')):continue
   if v in (';','\n'):break
   if v=='{':
    opening=x.end();depth=1
    while i<len(tokens):
     x=tokens[i];i+=1
     if x.group()=='{':depth+=1
     if x.group()=='}':depth-=1
     if depth==0:closing=x.start();finish=x.end();break
    break
  yield {'name':name,'start':begin,'end':finish,'open':opening,'close':closing}

def find(text,path):
 a=0;b=len(text);node=None
 for part in path:
  matches=[x for x in nodes(text,a,b) if x['name']==part]
  if len(matches)>1:raise ValueError('Birden çok '+part+' bloğu var; dosyayı elle kontrol edin.')
  if not matches:return None
  node=matches[0];a=node['open'];b=node['close']
  if part!=path[-1] and a is None:return None
 return node

def set_node(text,path,value):
 node=find(text,path)
 if node:
  replacement='' if value is None else value
  # Preserve separator on leaf removal/replacement.
  if node['open'] is None and text[node['end']-1:node['end']] in (';','\n'):replacement+='\n'
  return text[:node['start']]+replacement+text[node['end']:]
 if value is None:return text
 parent=find(text,path[:-1]) if len(path)>1 else None
 if len(path)>1 and parent is None:
  text=set_node(text,path[:-1],path[-2]+' {\n}\n');parent=find(text,path[:-1])
 pos=parent['close'] if parent else len(text)
 return text[:pos]+'\n'+value+'\n'+text[pos:]

def scalar(text,path,default):
 n=find(text,path)
 if not n:return default
 value=text[n['start']+len(n['name']):n['end']].strip(' \n;')
 if isinstance(default,bool):return True
 if isinstance(default,(int,float)):
  try:return type(default)(value)
  except ValueError:raise ValueError('/'.join(path)+' basit sayı değil; elle kontrol edin.')
 try:return json.loads(value)
 except Exception:return value

def key_id(value):
 parts=value.replace('Super+','Mod+').split('+');mods=[p.lower() for p in parts[:-1]]
 return '+'.join(sorted(mods)+[parts[-1].lower()])

def rebind(text,old,new):
 if not re.fullmatch(r'(?:[A-Za-z0-9]+\+)*[A-Za-z0-9_]+',new):raise ValueError('Örnek: Mod+Shift+P veya Super+P')
 new=new.replace('Super+','Mod+')
 b=find(text,['binds']);items=list(nodes(text,b['open'],b['close']))
 if any(key_id(n['name'])==key_id(new) and n['name']!=old for n in items):raise ValueError('Bu kısayol zaten kullanılıyor.')
 n=next(x for x in items if x['name']==old)
 return text[:n['start']]+new+text[n['start']+len(old):]

class Store:
 def __init__(self,home=None):
  self.home=Path(home or Path.home());self.config=self.home/'.config/niri/config.kdl'
  self.root=self.home/'.local/state/desktop-settings/backups'
 def tracked(self):
  files={self.config,self.home/'.config/mimeapps.list',self.home/'.local/share/applications/mimeapps.list',self.home/'.local/state/noctalia/settings.toml'}
  for folder,pattern in [('.config/niri','*.kdl'),('.config/noctalia','*.toml'),('.config/autostart','*.desktop'),('.config/nwg-displays','*')]:
   files.update(p for p in (self.home/folder).glob(pattern) if p.is_file())
  return sorted(files)
 def snapshot(self,label='Elle yedek'):
  self.root.mkdir(parents=True,exist_ok=True,mode=0o700)
  dest=Path(tempfile.mkdtemp(prefix=datetime.datetime.now().strftime('%Y%m%d-%H%M%S-'),dir=self.root));entries={}
  for p in self.tracked():
   rel=str(p.relative_to(self.home))
   if p.is_symlink():raise ValueError('Yedeklenecek ayar symlink: '+rel)
   entries[rel]=p.exists()
   if p.exists():
    out=dest/rel;out.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,out)
  (dest/'manifest.json').write_text(json.dumps({'label':label,'files':entries},ensure_ascii=False))
  return dest
 def validate(self,text):
  fd,tmp=tempfile.mkstemp(prefix='.settings-',suffix='.kdl',dir=self.config.parent)
  try:
   with os.fdopen(fd,'w') as f:f.write(text)
   r=subprocess.run(['niri','validate','-c',tmp],capture_output=True,text=True)
   if r.returncode:raise ValueError(r.stderr or r.stdout)
  finally:Path(tmp).unlink(missing_ok=True)
 def apply(self,original,updated,label):
  if self.config.read_text()!=original:raise ValueError('Ayar dosyası başka yerde değişti. Pencereyi yeniden açın.')
  self.validate(updated);self.snapshot(label)
  if self.config.read_text()!=original:raise ValueError('Ayar dosyası kayıt sırasında değişti.')
  self.atomic(self.config,updated.encode())
 @staticmethod
 def atomic(path,data):
  path.parent.mkdir(parents=True,exist_ok=True)
  if path.is_symlink():raise ValueError('Symlink üzerine yazılmadı: '+str(path))
  fd,tmp=tempfile.mkstemp(prefix='.settings-',dir=path.parent)
  try:
   with os.fdopen(fd,'wb') as f:f.write(data);f.flush();os.fsync(f.fileno())
   os.chmod(tmp,path.stat().st_mode & 0o777 if path.exists() else 0o600)
   os.replace(tmp,path)
  finally:Path(tmp).unlink(missing_ok=True)
 def restore(self,backup):
  backup=Path(backup).resolve()
  if backup.parent!=self.root.resolve():raise ValueError('Geçersiz yedek yolu')
  manifest=json.loads((backup/'manifest.json').read_text());files=manifest['files']
  allowed={str(p.relative_to(self.home)) for p in self.tracked()}
  if not set(files)<=allowed:raise ValueError('Yedek kapsamı değişmiş; elle inceleme gerekli.')
  with tempfile.TemporaryDirectory() as tmp:
   stage=Path(tmp)
   for p in self.config.parent.glob('*.kdl'):shutil.copy2(p,stage/p.name)
   for rel,exists in files.items():
    if rel.startswith('.config/niri/') and exists:shutil.copy2(backup/rel,stage/Path(rel).name)
   r=subprocess.run(['niri','validate','-c',str(stage/'config.kdl')],capture_output=True,text=True)
   if r.returncode:raise ValueError(r.stderr)
  state_rel='.local/state/noctalia/settings.toml'
  if files.get(state_rel):
   r=subprocess.run(['noctalia','config','validate',str(backup/state_rel)],capture_output=True,text=True)
   if r.returncode:raise ValueError(r.stderr or r.stdout)
  self.snapshot('Geri alma öncesi')
  # Included files first, main config last. No unrelated/new files are removed.
  for rel,exists in sorted(files.items(),key=lambda x:x[0]=='.config/niri/config.kdl'):
   target=self.home/rel
   if exists:self.atomic(target,(backup/rel).read_bytes())
   elif target.exists():
    if target.is_symlink():raise ValueError('Symlink geri alınmadı')
    target.unlink()


def set_toml_values(text,section,values):
 """Change scalar keys in one exact TOML table without discarding other tables."""
 import tomllib
 pattern=re.compile(r'^\['+re.escape(section)+r'\][ \t]*(?:#.*)?$',re.M)
 match=pattern.search(text)
 if match:
  start=match.end();next_table=re.search(r'^\[',text[start:],re.M);end=start+next_table.start() if next_table else len(text)
  block=text[start:end]
 else:start=end=len(text);block='\n['+section+']\n'
 for key,value in values.items():
  line=key+' = '+json.dumps(value)
  expression=re.compile(r'^'+re.escape(key)+r'\s*=.*$',re.M)
  if expression.search(block):block=expression.sub(lambda _:line,block)
  else:block+='\n'+line+'\n'
 result=text[:start]+block+text[end:];tomllib.loads(result);return result
