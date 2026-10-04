# Niri / Noctalia günlük araçları

11 Eylül 2026: dwm-titus ve Omarchy incelemesinden seçilen 1, 3, 5, 6, 7, 9, 10 maddeleri.

| Kısayol | İşlev |
|---|---|
| Super+A | ChatGPT uygulamasını aç |
| Print | Odaklı monitörü Satty'de düzenle |
| Shift+Print | Bölge seç, Satty'de düzenle |
| Alt+Print | Niri ile pencere görüntüsünü kaydet |
| Ctrl+Tab | Sessiz bölge kaydı başlat; yeniden basınca durdur |
| Super+Ctrl+Print | Bölge/monitör ve sessiz/sistem sesi/mikrofon seç; kayıt varsa durdur |
| Super+Shift+S | Türkçe Niri kısayol rehberi |
| Super+Ctrl+H | Ghostty'de salt okunur masaüstü sağlık raporu |
| Super+Ctrl+G | Dotfiles reposunu Lazygit'te aç |
| Alt+Space → Gemini / Claude | Brave uygulama penceresi aç |

## Kayıt

`dot-record` Niri IPC, slurp, wf-recorder ve kullanıcı systemd birimi `dot-record.service` kullanır. Başka kayıt süreçlerine sinyal göndermez. Varsayılan sessizdir. `--fullscreen`, `--sound`, `--microphone`, `--menu`, `--status`, `--stop` seçenekleri vardır; sistem sesi ve mikrofon ayrı seçeneklerdir, birlikte mikslenmez.

Çıktı: `~/Videos/Recordings/`, MP4/H.264, 30 FPS hedefi. Fedora'daki libx264 mevcut olmadığından kurulu `libopenh264` kullanılır; GPU kodlama uygulanmadı. Sesli kayıtta AAC. `DOT_RECORD_DIR` çıktı dizinini değiştirebilir. Son dosya: `~/.local/state/dot-record/last-file`. Hata ayrıntısı: `journalctl --user -u dot-record.service -n 30`.

Canlı doğrulama: 640×360 sessiz ve 1920×1080 sistem sesli kayıtlar düzgün kapandı; ffprobe H.264/AAC, ffmpeg tam çözümleme başarılı. Mikrofonun gerçek ses kalitesi ve uzun kayıt performansı test edilmedi.

## Tema

Noctalia'nın sabit yerleşik `Nord` paleti, kullanıcı şablonları üzerinden Ghostty `theme.conf` ve Niri `noctalia.kdl` dosyalarına uygulanır. Ghostty'nin mevcut font, sekme, scroll ve diğer tercihleri korunur. Niri renk dosyası ana config'in sonunda include edilir. Şablonlar `~/.config/noctalia/templates/`; tanımlar Noctalia config'indeki `theme.templates.user.desktop_*` tablolarında. `noctalia msg templates-apply` yeniden uygular. Ghostty yeniden yüklemesi GTK D-Bus action kullanır, süreç öldürmez.

Yedek kaynaklar `extras/noctalia/` altında. `nord-theme.toml` ve `desktop-templates.toml` dosyalarını mevcut Noctalia config'ine **bir kez birleştir**; bütün config yerine kopyalama. İki şablonu `~/.config/noctalia/templates/` altına kopyala. Ghostty ana config'i `config-file = theme.conf` içermeli. Şablon tanımları [Noctalia resmî şablon yapısını](https://docs.noctalia.dev/noctalia/theming/templates/) kullanır.

Noctalia uygulama menüsü minimal liste düzenindedir: kategoriler, alt açıklamalar ve paket kaynağı rozetleri gizli; ikonlar ve kullanım sıralaması açıktır. Taşınabilir parça `extras/noctalia/minimal-launcher.toml`; mevcut `~/.config/noctalia/config.toml` dosyasına birleştirilir. Canlı değişiklik öncesi yedek `~/.local/state/noctalia-launcher-minimal-20260917/` altındadır.

## Web uygulamaları ve Lazygit

`dot-webapp İsim https://adres` yeni Brave `.desktop` başlatıcısı üretir. Mevcut dosyanın üzerine yazmaz; yalnız HTTP/HTTPS kabul eder. Gemini ve Claude dosyaları `extras/applications/` içinde yedekli. Kullanıcı dizinine kopyaladıktan sonra `update-desktop-database ~/.local/share/applications` çalıştırılabilir. İki başlatıcı gerçek Brave oturumunda ayrı uygulama penceresi olarak doğrulandı.

Lazygit 0.65.0, resmî GitHub release SHA256 listesiyle doğrulanıp `~/.local/bin/lazygit` konumuna kuruldu; RPM/COPR eklenmedi. Binary repoya eklenmez. Herhangi bir Git reposunda `lazygit` çalıştırılabilir. Gerçek Ghostty/TUI açılışı görsel doğrulandı.

## Kaynaklar, test ve geri dönüş

Çalışan yardımcılar `~/dotfiles/bin/`; repo kaynakları `bin/`. Yalnız bu görevin değişiklikleri yedek repoya aktarıldı; repo ile canlı Niri düzeninin eski farkları tamamen eşitlenmiş sayılmaz.

Kontroller: `python3 -m unittest discover -s tests -v`, `niri validate`, `ghostty +validate-config`, `desktop-file-validate`, `dot-health`, `git diff --check`. Fiziksel klavye kısayollarının kullanıcı deneyimi ve interaktif bölge/menü seçimi ayrıca denenmeli.

Önceki dosyalar: `~/.local/state/desktop-upgrade/20260911-085936/`. Geri dönüşte önce `dot-record --stop` çalıştır; yedek Noctalia config'ini geri koyarak şablonları kapat, sonra yedek Niri config ve Ghostty theme.conf dosyalarını geri koy. `niri validate`, `niri msg action load-config-file` ve Ghostty config reload uygula. Yedekler gerçek dosya içeriklerini taşır; mevcut Ghostty symlink'ini değiştirme. Eklenen Gemini/Claude başlatıcıları ve kullanıcı Lazygit binary'si ayrı kaldırılabilir. Kayıt videoları kullanıcı verisidir, geri dönüşte silinmez.


## Omarchy fikirlerinden uyarlanan araçlar — 11 Eylül 2026

Orijinal eklentiler topluca kurulmadı; Fedora/Niri/Noctalia için yerel adaptörler eklendi.

- Bar: servis hataları (sağlıklıyken gizlenir), yedek durumu, Tailscale, mevcut not seçimi ve çizim düğmeleri.
- `Super+Alt+D`: odaklı monitörde çizim; `Super+Alt+P`: spotlight. Esc veya kısayolu tekrar kullanmak kapatır. D/A/R kalem/ok/dikdörtgen, U/Y geri/ileri, C temizle, 1–4 renk, T araç çubuğu. Katman açıkken tıklamalar alttaki uygulamaya geçmez.
- `Super+Alt+N`: Aktif Kasa mevcut Markdown notlarını arayarak seç; Kaydet ile yaz, Vazgeç ile iptal. Harici değişiklik tespit edilirse üzerine yazılmaz. Yeni not üretilmez.
- Thunar video sağ tık → **Resolve için sesi hazırla**. Ayrı `_resolve.mov`; video aynen kopyalanır, tüm ses akışları PCM olur. Altyazı/veri akışları aktarılmaz. Hedef varsa üzerine yazılmaz. Resolve video codec desteği bu işlemle değişmez.
- Tailscale: cihazlar, IP/DNS kopyalama; destekleyen çevrimiçi hedeflere dosya seçimi ve açık gönderim onayıyla Taildrop. Ağ ayarlarına dokunmaz.

Kaynak `bin/dot-desktop`, `lib/desktop_panels.py`, `bin/dot-presenter`; canlı kopyaları `~/dotfiles/` altında. Tek `desktop-panels.service` 30 saniye aralıklarla durumu okur; Niri oturum başında başlatır. Bar eklentisi `~/.config/noctalia/zz-desktop-tools.toml` üretilir. Yedekler yalnız kullanıcı servisleri: archive-critical-backup, vault-git-backup, proton-backup. Son başarı son 14 gün/100 journal satırı üzerinden okunur; snapshot veya geri yükleme testi değildir.

Presenter çizim bileşenleri MIT kaynak `extras/presenter/LICENSE.upstream` ile korunur. Yerel Fedora Quickshell RPM runtime'ı `~/.local/lib/quickshell-fedora/` altında; sistem paket kurulumu yapılmadı. Yeniden kurulumda Fedora quickshell RPM'i `dnf download quickshell --destdir /tmp/desktop-quickshell` ile indirip ayrı dizinde `rpm2cpio DOSYA.rpm | cpio -idm` ile aç; bu dizini runtime konumuna taşı. RPM ve binary Git'e dahil değildir. QML kaynaklarını `~/.config/quickshell/niri-presenter/` altına kopyala. Thunar eylemini mevcut uca.xml'e birleştir; yedek XML ile bütün ayarları ezme.

Doğrulama: 8 birim testi, Niri/Noctalia config geçerliliği; gerçek ffmpeg örneğinde PCM ses, aynı video akış hash'i, değişmeyen kaynak ve mevcut hedefe yazmama doğrulandı. Presenter DP-3 üzerinde IPC çizim/spot komutları, araç çubuğu görünümü ve temiz çıkış doğrulandı. Diğer monitörde fiziksel kısayol kullanımı, not editörünün etkileşimli Kaydet akışı, Taildrop transferi ve Resolve içe aktarma henüz denenmedi.

İlk canlı taramada ydotool.service başarısız, üç yedek timer'ı kapalı ve başarı kaydı yoktu. Otomatik onarım/başlatma yapılmadı.

Geri dönüş: `systemctl --user stop desktop-panels.service dot-presenter.service`; Niri'den eklenen startup/kısayolları, Noctalia `zz-desktop-tools.toml` ve Thunar `desktop-resolve-audio` eylemini kaldır. Önceki config yedeği `~/.local/state/desktop-upgrade/plugins-20260911-093600/` altında. Niri validate ile kontrol et. Bu geri dönüş notları/video çıktılarını değiştirmez.


### 11 Eylül yedek bakımı düzeltmesi

Proton 23 Ağustos'ta bilinçli kaldırılmıştır; izlenen işler yalnız archive-critical-backup ve vault-git-backup. İki timer yeniden etkinleştirildi. Kalıcı script başarı kayıtları journal'a ek kanıt olarak okunur. Vault Git timer'ı açılışlarda plansız `active (elapsed)` durumuna düşmemesi için `00:00`, `06:00`, `12:00`, `18:00` takvim zamanlarını ve `Persistent=true` kullanır; panel sonraki zamanı `list-timers` JSON üzerinden okur. Kritik arşiv işi Python sqlite3 backup API kullanır; gerçek Restic çalışması ve %2 kontrol başarılı. Git işi kullanıcı seçimiyle `backup/fedora-host-20260911` dalını iki mevcut hedefe gönderir; main geçmişleri birleştirilmedi. Değişiklik yokken de push yeniden denenir.


## Grafik ayar merkezi — 11 Eylül 2026

`Super+P` veya uygulama menüsünde **Masaüstü Ayarları** → `dot-settings`. GTK3/Gio tabanlı yerel pencere: Ekranlar, Varsayılan uygulamalar, Görünüm ve panel. Son bölüm mevcut Noctalia ayarlarını açar. Varsayılanlar seçici onayıyla Gio/XDG MIME tercihlerine yazılır; kategori kapsamları UI üzerinde belirtilir. Uygulama içi tercihler ve terminal emülatörü seçimi bu sayfanın kapsamı dışındadır.

Ekran GUI: [nwg-displays](https://github.com/nwg-piotr/nwg-displays), commit `fd79522cb91ef2ba080ba51838c0f307e1d4fb83` (setup sürümü 0.4.4). Kaynak ve MIT lisansı `~/.local/share/nwg-displays/`, başlatıcı `~/.local/bin/nwg-displays`. Mevcut GTK3, GtkLayerShell ve Python bağımlılıkları kullanıldı; sistem paketi eklenmedi. Yeniden kurulumda bu commit'in nwg_displays dizinini ve LICENSE dosyasını aynı yere kopyala; başlatıcı bu yolu sys.path'e ekleyerek nwg_displays.main.main çalıştırır. GDK_BACKEND=wayland.

Canlı Niri'nin mevcut iki output bloğu değiştirilmeden `~/.config/niri/monitor.kdl` dosyasına taşındı; ana config include eder. GUI'nin Apply işlemi bu dosyaya yazar. Repo kopyası kendi önceki output değerlerini monitor.kdl içinde korur; canlı/repo tüm dosyaları birbirinin üzerine kopyalanmadı. İki araç için floating pencere kuralları eklendi. Eski config `~/.local/state/desktop-upgrade/settings-20260911/config.kdl`.

Doğrulama: Niri validate, Python derleme, desktop-file-validate, git diff --check; iki monitör GUI tarafından algılandı, iki pencere görsel kontrol edildi. Gio varsayılan yazma/okuma testi izole XDG_CONFIG_HOME içinde geçti. Gerçek ekran konumu/Hz veya kullanıcının MIME tercihleri test için değiştirilmedi; fiziksel ekran değişikliği ve Apply geri sayımını kullanıcı kullanımında doğrulamak gerekir.


### Yedi ek ayar bölümü

Super+P merkezine klavye/fare, kısayollar, ses, güç/kilit, başlangıç, pencere düzeni ve yedekler eklendi. Kaynaklar `lib/settings_store.py`, `lib/settings_pages.py`; canlı kopyalar `~/dotfiles/lib/`.

Klavye/fare formu dil, tekrar, hız ve kaydırma seçeneklerini; pencere formu gaps, border width ve odak/ortalama seçeneklerini değiştirir. KDL yorumları ve diğer seçenekler korunur; aday dosya niri validate işleminden geçmeden yazılmaz. Kısayol formu ana config binds bölümünü düzenler, modifier sırası/Super alias çakışmasını kontrol eder. Niri validate ayrıca geçersiz tuşları reddeder. Dahil edilen ayrı dosyalardaki kısayollar bu ilk sürümün listesinde değildir.

Ses, kurulu pavucontrol açar. Güç formu Noctalia full effective config'ten mevcut üç davranışı okur ve state settings.toml içindeki ilgili enabled/timeout alanlarını değiştirir; diğer alanlar korunur. Süre birimi dakika. Noctalia kaynak modeli: https://docs.noctalia.dev/noctalia/configuration/ . Ekran kilitleme/uyutma test amacıyla tetiklenmedi.

Başlangıç formu mevcut Niri spawn-at-startup satırlarını ve kullanıcı ~/.config/autostart desktop dosyalarını açıp kapatır; etkisi sonraki oturumdadır. Yeni uygulama ekleme bu sürümde yok. Uygulama kuralı açık uygulamanın app-id'sinden tam eşleşme üretir, floating/tiling/fullscreen ve isteğe bağlı monitör belirtir; yeni açılan pencerelere uygulanır. Sonradan eklenen kurallar öncekilerin ilgili alanını geçersiz kılabilir; geri dönüş snapshot ile.

Ayar yedekleri ~/.local/state/desktop-settings/backups altında tarihli manifestli klasörlerdir. Merkezde kayıt öncesi ve dış ekran/Noctalia ayar penceresini açmadan önce snapshot alınır. Dış GUI'deki her Apply ayrı snapshot değildir. Yedekler Niri KDL, Noctalia TOML, MIME ve kullanıcı autostart dosyalarını kapsar; sesin anlık PipeWire durumu kapsam dışıdır. Geri almadan önce Niri/Noctalia dosyaları doğrulanır ve mevcut durum ayrıca yedeklenir. Sonradan eklenen ilgisiz dosyalar silinmez. Geri yüklemeden sonra merkezi yeniden aç.

Kontroller: 13 otomatik test; gerçek Niri config üzerinde değişiklik adayları; izole kopyada snapshot-edit-restore byte eşitliği; güç TOML adayı Noctalia validate; gerçek GUI açılışı ve bölüm listesi görsel doğrulaması. Kullanıcının canlı input, güç, ses ve başlangıç tercihleri test için değiştirilmedi.


## KDE uygulamalarından geçiş — 12 Eylül 2026

Kullanıcı seçimiyle Fedora RPM paketleri kuruldu: `file-roller`, `loupe`, `qalculate-gtk`, `papers`, `openssh-askpass`; `zenity` zaten kurulu. Arşiv varsayılanları File Roller, mevcut görsel varsayılanları Loupe, PDF/CBZ/CBR Papers oldu. Papers EPUB desteklemediğinden `application/epub+zip` Okular olarak korundu. Eski KDE paketleri kaldırılmadı.

MIME eşleştirmelerinin taşınabilir alt kümesi `extras/mimeapps/desktop-apps.list`; mevcut `~/.config/mimeapps.list` içindeki `[Default Applications]` bölümüne birleştir, bütün dosyanın üzerine yazma. Thunar'ın kurulu `org.gnome.FileRoller.tap` adaptörü yeni arşiv varsayılanını kullanır. Hesap makinesi tuşu (`XF86Calculator`) Niri'de `qalculate-gtk` açar.

SSH parola yardımcısı `SSH_ASKPASS=/usr/libexec/openssh/gnome-ssh-askpass`. `sudo -A` yardımcısı `SUDO_ASKPASS=/home/savpavi/.local/bin/dot-askpass`; betik Zenity parola penceresini açar ve stdout/iptal kodunu çağırana aktarır. Normal terminal `sudo` davranışı değişmez. Kaynak `bin/dot-askpass`, çalışan kopyalar `~/.local/bin/dot-askpass` ve `~/dotfiles/bin/dot-askpass`. Yeniden kurulumda betiği bu yollara çalıştırılabilir kopyala; `config/environment.d/70-askpass.conf` dosyasını `~/.config/environment.d/` içine birleştir. Niri environment bloğu da aynı yolları içerir. Mevcut kullanıcı systemd/D-Bus ortamı güncellendi; önceden açık terminal süreçleri için yeni terminal açmak gerekir.

Aktif Niri, dotfiles, kullanıcı betikleri ve başlangıç ayarlarında KDialog/KSSHAskPass çağrısı bulunmadı; zaten Zenity kullanan yardımcılar korundu. KDE'ye ait sistem Plasma başlangıç dosyası değiştirilmedi.

Doğrulama: RPM sürümleri, XDG MIME sorguları, iki Niri config validate, yeni Niri sürecinin Askpass ortamı, `test_askpass.py` içindeki iki test (literal başlık/yalnız stdout, iptal kodu), diff kontrolü geçti. ZIP/PNG/PDF dosyaları XDG üzerinden yeni uygulamalarda açıldı; dört pencere görsel kontrol edildi, Qalculate! 2+2=4 gösterdi. Thunar adaptörü örnek ZIP'i çıkardı; içerik doğrulandı. OpenSSH Askpass ve Zenity pencereleri parola girilmeden açılıp kapatıldı; Zenity 1, OpenSSH Askpass 255 iptal kodu döndürdü. Gerçek SSH/sudo kimlik doğrulaması test için yapılmadı.

Geri dönüş yedeği: `~/.local/state/kde-app-migration-20260912/before/`. MIME ve canlı/repo Niri dosyalarının önceki içerikleri burada. Geri alırken sonraki değişiklikleri karşılaştır; yeni `70-askpass.conf` ve `dot-askpass` kopyalarını ayrıca kaldır, Niri'yi doğrula ve oturumu yeniden aç. Paket kurulum günlüğü ve test kanıtları aynı üst dizinde. Bu geçiş commit/push yapılmadan yerel repoya işlendi.


### Eski uygulamaların kaldırılması — 12 Eylül 2026

Kullanıcı onayıyla `ark`, `ark-libs`, `gwenview`, `gwenview-libs`, `kcalc`, `kdialog`, `ksshaskpass` kaldırıldı. DNF yalnız bu 7 paketi içeren işlemde yaklaşık 21 MiB alan kazanımı bildirdi; çıkış kodu 0. `clean_requirements_on_remove=False` kullanıldı: otomatik temizlik önerisindeki Tcl/Tk, Qt görüntü eklentileri ve diğer ortak/isteğe bağlı yardımcılar korunuyor. EPUB varsayılanı Okular olarak kaldı. Kurulum ve eski paketlerin korunmasıyla ilgili üstteki bölüm önceki geçiş adımını anlatır.

Kaldırma günlüğü `~/.local/state/kde-app-migration-20260912/remove.log`. Geri kurmak gerekirse kaldırılan yedi paket `sudo dnf install ark ark-libs gwenview gwenview-libs kcalc kdialog ksshaskpass` ile kurulabilir; dosya varsayılanlarını ayrıca önceki yedekle karşılaştır. DNF bekleyen çevrimdışı işlemi geçersiz kıldığı uyarısını yine verdi; güncelleme yeniden planlanmadı.
