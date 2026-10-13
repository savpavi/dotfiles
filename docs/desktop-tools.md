# Günlük masaüstü araçları

11 Eylül 2026: dwm-titus ve Omarchy incelemesinden seçilen 1, 3, 5, 6, 7, 9, 10 maddeleri.

| Kısayol | İşlev |
|---|---|
| Print | Odaklı monitörü Satty'de düzenle |
| Shift+Print | Bölge seç, Satty'de düzenle |
| Alt+Print | Niri ile pencere görüntüsünü kaydet |
| Ctrl+Tab | Sessiz bölge kaydı başlat; yeniden basınca durdur |
| Super+Ctrl+Print | Bölge/monitör ve sessiz/sistem sesi/mikrofon seç; kayıt varsa durdur |
| Super+Shift+S | Türkçe Niri kısayol rehberi |
| Super+Ctrl+H | Kitty'de salt okunur masaüstü sağlık raporu |
| Super+Ctrl+G | Dotfiles reposunu Lazygit'te aç |
| Alt+Space → Gemini / Claude | Helium uygulama penceresi aç |

## Kayıt

`dot-record` Niri IPC, slurp, wf-recorder ve kullanıcı systemd birimi `dot-record.service` kullanır. Başka kayıt süreçlerine sinyal göndermez. Varsayılan sessizdir. `--fullscreen`, `--sound`, `--microphone`, `--menu`, `--status`, `--stop` seçenekleri vardır; sistem sesi ve mikrofon ayrı seçeneklerdir, birlikte mikslenmez.

Çıktı: `~/Videos/Recordings/`, MP4/H.264, 30 FPS hedefi. Fedora'daki libx264 mevcut olmadığından kurulu `libopenh264` kullanılır; GPU kodlama uygulanmadı. Sesli kayıtta AAC. `DOT_RECORD_DIR` çıktı dizinini değiştirebilir. Son dosya: `~/.local/state/dot-record/last-file`. Hata ayrıntısı: `journalctl --user -u dot-record.service -n 30`.

Canlı doğrulama: 640×360 sessiz ve 1920×1080 sistem sesli kayıtlar düzgün kapandı; ffprobe H.264/AAC, ffmpeg tam çözümleme başarılı. Mikrofonun gerçek ses kalitesi ve uzun kayıt performansı test edilmedi.

## Web uygulamaları ve Lazygit

`dot-webapp İsim https://adres` yeni Helium `.desktop` başlatıcısı üretir. Mevcut dosyanın üzerine yazmaz; yalnız HTTP/HTTPS kabul eder. Gemini ve Claude dosyaları `extras/applications/` içinde yedekli. Kullanıcı dizinine kopyaladıktan sonra `update-desktop-database ~/.local/share/applications` çalıştırılabilir. İki başlatıcı Brave döneminde ayrı uygulama penceresi olarak doğrulandı; 12 Ekim 2026 itibarıyla Helium kullanılıyor.

Lazygit 0.65.0, resmî GitHub release SHA256 listesiyle doğrulanıp `~/.local/bin/lazygit` konumuna kuruldu; RPM/COPR eklenmedi. Binary repoya eklenmez. Herhangi bir Git reposunda `lazygit` çalıştırılabilir. Gerçek Ghostty/TUI açılışı görsel doğrulandı.

## Kaynaklar, test ve geri dönüş

Çalışan yardımcılar `~/dotfiles/bin/`; repo kaynakları `bin/`. Yalnız bu görevin değişiklikleri yedek repoya aktarıldı; repo ile canlı Niri düzeninin eski farkları tamamen eşitlenmiş sayılmaz.

Kontroller: `python3 -m unittest discover -s tests -v`, `niri validate`, `desktop-file-validate`, `dot-health`, `git diff --check`. Fiziksel klavye kısayollarının kullanıcı deneyimi ve interaktif bölge/menü seçimi ayrıca denenmeli.

Önceki dosyalar: `~/.local/state/desktop-upgrade/20260911-085936/`. Geri dönüşte önce `dot-record --stop` çalıştır; yedek Noctalia config'ini geri koyarak şablonları kapat, sonra yedek Niri config ve Ghostty theme.conf dosyalarını geri koy. `niri validate`, `niri msg action load-config-file` ve Ghostty config reload uygula. Yedekler gerçek dosya içeriklerini taşır; mevcut Ghostty symlink'ini değiştirme. Eklenen Gemini/Claude başlatıcıları ve kullanıcı Lazygit binary'si ayrı kaldırılabilir. Kayıt videoları kullanıcı verisidir, geri dönüşte silinmez.


## Resolve için ses hazırlama

Thunar video sağ tık → **Resolve için sesi hazırla** (`bin/dot-resolve`). Yanına `_resolve.mov` yazar; video akışı aynen kopyalanır, ses PCM olur, orijinal dosyaya dokunulmaz. 13 Ekim 2026'da Noctalia'ya bağlı `dot-desktop`'tan ayrıldı; `dot-desktop`, `dot-settings`, `dot-presenter` ve Niri config'i Noctalia ile birlikte repodan kaldırıldı (git geçmişinde duruyor).

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
