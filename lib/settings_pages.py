"""Additional GTK pages for the desktop settings window."""
import configparser,json,re,subprocess
from pathlib import Path
import gi
gi.require_version('Gtk','3.0')
from gi.repository import Gtk,Gio
from settings_store import Store,find,nodes,scalar,set_node,rebind

class Pages:
 def __init__(self,app,stack):
  self.app=app;self.stack=stack;self.store=Store()
  self.input();self.shortcuts();self.sound();self.power();self.startup();self.layout();self.backups()
 def page(self,title,description,key):
  box=self.app.page(title,description)
  scroll=Gtk.ScrolledWindow();scroll.set_policy(Gtk.PolicyType.NEVER,Gtk.PolicyType.AUTOMATIC);scroll.add(box)
  self.stack.add_titled(scroll,key,title);return box
 def button(self,box,label,callback):
  b=Gtk.Button(label=label);b.connect('clicked',lambda _:self.safe(callback));box.pack_start(b,False,False,5);return b
 def safe(self,fn):
  try:fn()
  except Exception as e:self.app.error(str(e))
 def message(self,text):
  d=Gtk.MessageDialog(transient_for=self.app.window,modal=True,buttons=Gtk.ButtonsType.OK,text=text);d.run();d.destroy()
 def confirm(self,text):
  d=Gtk.MessageDialog(transient_for=self.app.window,modal=True,message_type=Gtk.MessageType.QUESTION,buttons=Gtk.ButtonsType.OK_CANCEL,text=text)
  d.set_default_response(Gtk.ResponseType.CANCEL);result=d.run()==Gtk.ResponseType.OK;d.destroy();return result
 def edit(self,title,value):
  d=Gtk.Dialog(title=title,transient_for=self.app.window,modal=True)
  d.add_buttons('Vazgeç',Gtk.ResponseType.CANCEL,'Kaydet',Gtk.ResponseType.OK)
  e=Gtk.Entry(text=value);e.set_width_chars(45);d.get_content_area().add(e);d.show_all()
  result=e.get_text() if d.run()==Gtk.ResponseType.OK else None;d.destroy();return result
 def field(self,box,label,value,limits=None):
  row=Gtk.Box(spacing=12);row.pack_start(Gtk.Label(label=label,xalign=0),True,True,0)
  if isinstance(value,bool):widget=Gtk.Switch(active=value)
  elif limits:
   widget=Gtk.SpinButton.new_with_range(*limits);widget.set_value(value);widget.set_digits(2 if isinstance(value,float) else 0)
  else:widget=Gtk.Entry(text=str(value))
  row.pack_end(widget,False,False,0);box.pack_start(row,False,False,3);return widget
 def input(self):
  box=self.page('Klavye ve fare','Değişiklikler Kaydet ile uygulanır. Dil kodları örneği: tr,us.','input')
  original=[self.store.config.read_text()];s=original[0];controls=[]
  specs=[('Klavye dilleri',['input','keyboard','xkb','layout'],'tr,us',None),('Tuş tekrar gecikmesi (ms)',['input','keyboard','repeat-delay'],600,(100,2000,10)),('Tuş tekrar hızı',['input','keyboard','repeat-rate'],25,(1,100,1)),('Fare hızı (−1…1)',['input','mouse','accel-speed'],0.0,(-1,1,.05)),('Fare kaydırma çarpanı',['input','mouse','scroll-factor'],1.0,(.1,5,.1)),('Fare doğal kaydırma',['input','mouse','natural-scroll'],False,None),('Touchpad hızı',['input','touchpad','accel-speed'],0.0,(-1,1,.05)),('Touchpad dokunarak tıklama',['input','touchpad','tap'],False,None),('Touchpad doğal kaydırma',['input','touchpad','natural-scroll'],False,None)]
  for label,path,default,limits in specs:
   value=scalar(s,path,default);controls.append((path,default,self.field(box,label,value,limits)))
  def save():
   updated=original[0]
   for path,default,w in controls:
    if isinstance(default,bool):node=path[-1] if w.get_active() else None
    elif isinstance(default,(int,float)):node=path[-1]+' '+str(w.get_value_as_int() if isinstance(default,int) else round(w.get_value(),2))
    else:
     value=w.get_text().strip()
     if not re.fullmatch('[A-Za-z0-9_,()-]+',value):raise ValueError('Geçerli klavye dil kodları girin: tr,us')
     node=path[-1]+' '+json.dumps(value)
    updated=set_node(updated,path,node)
   self.store.apply(original[0],updated,'Klavye/fare öncesi');original[0]=updated;self.message('Klavye ve fare ayarları kaydedildi.')
  self.button(box,'Kaydet',save)
 def shortcuts(self):
  box=self.page('Kısayollar','Satırı seçip kombinasyonu değiştir. Örnek: Super+Shift+P. Mevcut eylem korunur.','shortcuts')
  model=Gtk.ListStore(str,str);tree=Gtk.TreeView(model=model)
  for i,name in enumerate(['Kombinasyon','Eylem']):tree.append_column(Gtk.TreeViewColumn(name,Gtk.CellRendererText(),text=i))
  def refresh():
   model.clear();s=self.store.config.read_text();b=find(s,['binds'])
   for n in nodes(s,b['open'],b['close']):
    text=s[n['start']:n['end']];m=re.search('hotkey-overlay-title="([^"]*)"',text)
    model.append([n['name'],m.group(1) if m else text[:100]])
  refresh();box.pack_start(tree,True,True,4)
  def change():
   m,it=tree.get_selection().get_selected()
   if it is None:return
   old=m[it][0];new=self.edit('Yeni kombinasyon',old)
   if new is None:return
   s=self.store.config.read_text();self.store.apply(s,rebind(s,old,new),'Kısayol öncesi');refresh()
  self.button(box,'Seçili kısayolu değiştir',change)
 def sound(self):
  box=self.page('Ses','Çıkış/giriş cihazı, mikrofon seviyesi ve uygulama bazında ses düzeyleri.','sound')
  self.button(box,'Ses mikserini aç',lambda:self.app.launch(['pavucontrol']))
 def power(self):
  import tomllib
  box=self.page('Güç ve ekran kilidi','Süreler dakika cinsindedir. Açık anahtarları Kaydet ile etkinleştir; kapalı seçenekler çalışmaz.','power')
  data=tomllib.loads(subprocess.run(['noctalia','config','export','full'],capture_output=True,text=True,check=True).stdout)
  state=Path.home()/'.local/state/noctalia/settings.toml';original=[state.read_text() if state.exists() else ''];controls=[]
  for name,title in [('lock','Otomatik kilitle'),('screen-off','Ekranı kapat'),('lock-and-suspend','Kilitle ve uyut')]:
   settings=data['idle']['behavior'][name]
   enabled=self.field(box,title,bool(settings['enabled']))
   timeout=self.field(box,title+' — dakika',float(settings['timeout'])/60,(1,1440,1))
   controls.append((name,enabled,timeout))
  def save():
   from settings_store import set_toml_values
   updated=original[0]
   for name,enabled,timeout in controls:
    updated=set_toml_values(updated,'idle.behavior.'+name,{'enabled':enabled.get_active(),'timeout':round(timeout.get_value()*60,2)})
   tomllib.loads(updated)
   if (state.read_text() if state.exists() else '')!=original[0]:raise ValueError('Noctalia ayarları başka yerde değişti; pencereyi yeniden açın.')
   self.store.snapshot('Güç ayarları öncesi');self.store.atomic(state,updated.encode());original[0]=updated
   subprocess.run(['noctalia','msg','config-reload'],capture_output=True,check=True)
   self.message('Güç ve kilit ayarları kaydedildi.')
  self.button(box,'Güç ayarlarını kaydet',save)
 def external(self,args,label):
  self.app.launch(args)
 def startup(self):
  box=self.page('Başlangıç uygulamaları','Seçimler sonraki oturum açılışında geçerli olur; çalışan uygulamalar kapatılmaz.','startup')
  original=[self.store.config.read_text()];s=original[0];items=[]
  for line in s.splitlines(keepends=True):
   stripped=line.strip();disabled=stripped.startswith('// settings-disabled: ')
   raw=stripped.removeprefix('// settings-disabled: ')
   if raw.startswith('spawn-at-startup '):
    w=self.field(box,raw.removeprefix('spawn-at-startup ')[:65],not disabled);items.append((line,raw,w))
  desktop=[]
  for path in sorted((Path.home()/'.config/autostart').glob('*.desktop')):
   cp=configparser.ConfigParser(interpolation=None,strict=False);cp.optionxform=str;cp.read(path)
   sec=cp['Desktop Entry'];on=sec.get('Hidden','false')!='true' and sec.get('X-GNOME-Autostart-enabled','true')!='false'
   w=self.field(box,sec.get('Name',path.stem),on);desktop.append((path,path.read_text(),cp,w))
  def save():
   if not self.confirm('Başlangıç seçimleri kaydedilsin mi? Panel ve pano gibi bileşenleri kapatmak sonraki oturumu etkiler.'):return
   updated=original[0]
   for line,raw,w in items:updated=updated.replace(line,(raw if w.get_active() else '// settings-disabled: '+raw)+'\n',1)
   for path,old,cp,w in desktop:
    if path.read_text()!=old:raise ValueError('Başlangıç dosyası değişti; pencereyi yeniden açın.')
   self.store.apply(original[0],updated,'Başlangıç öncesi')
   import io
   for path,old,cp,w in desktop:
    cp['Desktop Entry']['Hidden']='false' if w.get_active() else 'true';cp['Desktop Entry']['X-GNOME-Autostart-enabled']='true' if w.get_active() else 'false'
    out=io.StringIO();cp.write(out,space_around_delimiters=False);self.store.atomic(path,out.getvalue().encode())
   self.message('Kaydedildi. Başka başlangıç değişikliği için pencereyi yeniden açın.')
  self.button(box,'Başlangıç seçimlerini kaydet',save)
 def layout(self):
  box=self.page('Pencere düzeni','Boşluk, kenarlık ve odak davranışı. Renkler Noctalia temasından gelir.','layout')
  original=[self.store.config.read_text()];s=original[0]
  gaps=self.field(box,'Pencereler arası boşluk',scalar(s,['layout','gaps'],16),(0,64,1))
  width=self.field(box,'Kenarlık kalınlığı',scalar(s,['layout','border','width'],4),(0,16,1))
  focus=self.field(box,'Fareyi izleyen odak',find(s,['input','focus-follows-mouse']) is not None)
  center=Gtk.ComboBoxText()
  for v in ['never','always','on-overflow']:center.append(v,{'never':'Asla','always':'Her zaman','on-overflow':'Taşınca'}[v])
  center.set_active_id(scalar(s,['layout','center-focused-column'],'never'));box.pack_start(Gtk.Label(label='Odaklı sütunu ortala',xalign=0),False,False,0);box.pack_start(center,False,False,0)
  def save():
   updated=set_node(original[0],['layout','gaps'],'gaps '+str(gaps.get_value_as_int()))
   updated=set_node(updated,['layout','border','width'],'width '+str(width.get_value_as_int()))
   updated=set_node(updated,['layout','center-focused-column'],'center-focused-column '+json.dumps(center.get_active_id()))
   # Preserve existing focus options unless the switch is changed.
   if focus.get_active()!=(find(original[0],['input','focus-follows-mouse']) is not None):updated=set_node(updated,['input','focus-follows-mouse'],'focus-follows-mouse' if focus.get_active() else None)
   self.store.apply(original[0],updated,'Pencere düzeni öncesi');original[0]=updated;self.message('Pencere düzeni kaydedildi.')
  self.button(box,'Pencere düzenini kaydet',save)
  self.button(box,'Uygulamaya özel açılış kuralı ekle',self.rule)
 def rule(self):
  result=subprocess.run(['niri','msg','-j','windows'],capture_output=True,text=True,check=True)
  ids=sorted({x['app_id'] for x in json.loads(result.stdout) if x.get('app_id')})
  d=Gtk.Dialog(title='Uygulama açılış kuralı',transient_for=self.app.window,modal=True);d.add_buttons('Vazgeç',Gtk.ResponseType.CANCEL,'Ekle',Gtk.ResponseType.OK)
  box=d.get_content_area();app=Gtk.ComboBoxText()
  for value in ids:app.append_text(value)
  app.set_active(0);box.pack_start(Gtk.Label(label='Açık uygulama'),False,False,4);box.pack_start(app,False,False,4)
  mode=Gtk.ComboBoxText()
  for value in ['Yüzen pencere','Döşeli pencere','Tam ekran']:mode.append_text(value)
  mode.set_active(0);box.pack_start(mode,False,False,4)
  output=self.field(box,'Monitör (boş: otomatik)','');d.show_all()
  if d.run()==Gtk.ResponseType.OK and app.get_active_text():
   rules=['open-fullscreen false\n    open-floating true','open-fullscreen false\n    open-floating false','open-fullscreen true'];body='    '+rules[mode.get_active()]+'\n'
   if output.get_text().strip():body+='    open-on-output '+json.dumps(output.get_text().strip())+'\n'
   s=self.store.config.read_text();new=s+'\n// Ayar merkezi: uygulama açılış tercihi\nwindow-rule {\n    match app-id='+json.dumps('^'+re.escape(app.get_active_text())+'$')+'\n'+body+'}\n'
   try:self.store.apply(s,new,'Uygulama kuralı öncesi')
   except Exception as e:self.app.error(str(e))
  d.destroy()
 def backups(self):
  box=self.page('Ayar yedekleri','Niri, Noctalia, ekranlar, başlangıç ve varsayılan uygulama dosyaları. Ses cihazlarının anlık durumu kapsam dışıdır.','backups')
  combo=Gtk.ComboBoxText();box.pack_start(combo,False,False,4)
  def refresh():
   combo.remove_all()
   for path in sorted(self.store.root.glob('*/manifest.json'),reverse=True):
    info=json.loads(path.read_text());combo.append(str(path.parent),path.parent.name+' · '+info['label'])
   combo.set_active(0)
  def create():self.store.snapshot();refresh();self.message('Ayar yedeği alındı.')
  def restore():
   path=combo.get_active_id()
   if path and self.confirm('Seçilen yedeğin ayarları geri yüklensin mi? Mevcut ayarlar önce ayrıca yedeklenir. Ekran düzeni de değişebilir.'):
    self.store.restore(path);refresh();self.message('Geri yüklendi. Güncel değerleri görmek için ayar merkezini yeniden açın.')
  self.button(box,'Listeyi yenile',refresh);self.button(box,'Şimdi yedek al',create);self.button(box,'Seçili yedeği geri yükle',restore);refresh()
