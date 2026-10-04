"""Masaüstü yardımcılarının durum ve dosya işlemleri."""
import os
from pathlib import Path
import stat
import subprocess as sp
import tempfile
import json

def backup_status(state,timer_on,last_success,now,max_age):
    if state.get('LoadState')=='not-found':return 'MISSING'
    if state.get('ActiveState') in ('active','activating'):return 'RUNNING'
    if state.get('Result','success')!='success':return 'FAILED'
    if not timer_on:return 'TIMER OFF'
    if last_success is None:return 'UNKNOWN'
    if now-last_success>max_age:return 'STALE'
    return 'OK'

def save_note(path,original,updated):
    path=Path(path)
    if path.is_symlink() or not path.is_file():raise RuntimeError('Normal bir not dosyası gerekli')
    if path.read_bytes()!=original:raise RuntimeError('Not başka bir uygulamada değişti; üzerine yazılmadı. Yeniden açın.')
    mode=stat.S_IMODE(path.stat().st_mode)
    fd,tmp=tempfile.mkstemp(prefix='.quick-note-',dir=path.parent)
    try:
        with os.fdopen(fd,'wb') as f:f.write(updated);f.flush();os.fsync(f.fileno())
        os.chmod(tmp,mode)
        if path.read_bytes()!=original:raise RuntimeError('Not kayıt sırasında değişti; üzerine yazılmadı.')
        os.replace(tmp,path)
    finally:
        Path(tmp).unlink(missing_ok=True)

def convert_resolve(source):
    source=Path(source).resolve(strict=True)
    if not source.is_file():raise RuntimeError('Video dosyası gerekli')
    dest=source.with_name(source.stem+'_resolve.mov')
    if dest.exists():raise FileExistsError('Hedef zaten var: '+str(dest))
    info=sp.run(['ffprobe','-v','error','-show_streams','-of','json',str(source)],capture_output=True,text=True,check=True)
    streams=json.loads(info.stdout)['streams']
    if not any(x.get('codec_type')=='video' for x in streams):raise RuntimeError('Video akışı bulunamadı')
    if not any(x.get('codec_type')=='audio' for x in streams):raise RuntimeError('Ses akışı yok; dönüştürmeye gerek yok')
    fd,tmp=tempfile.mkstemp(prefix='.'+source.stem+'-',suffix='.mov',dir=source.parent);os.close(fd)
    try:
        result=sp.run(['ffmpeg','-nostdin','-hide_banner','-loglevel','error','-i',str(source),'-map','0:v','-map','0:a','-c:v','copy','-c:a','pcm_s16le','-f','mov','-y',tmp],capture_output=True,text=True)
        if result.returncode:raise RuntimeError(result.stderr[-1200:])
        os.link(tmp,dest) # Var olan dosyayı atomik olarak koru.
        return dest
    finally:Path(tmp).unlink(missing_ok=True)
