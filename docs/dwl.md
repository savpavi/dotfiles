# dwl masaüstü: ayrıntılar

dwl v0.9 üstüne kişisel kurulum: çalışırken değişen temalar, Quickshell bar, hareketli duvar,
kilit ve giriş ekranı. Genel bakış kökteki `README.md`'de; bu dosya ayrıntıları ve tuzakları tutar.
dwl'nin kendi (upstream) belgesi `dwl/README.md`.

## Kurulum

```sh
install/dwl.sh            # paketler, derleme, kurulum, giriş ekranı, kullanıcı ayarları, denetim, güvenlik duvarı
install/dwl.sh --dry-run  # ne yapacağını yalnız yazdır
install/dwl.sh derle kur  # yalnız seçilen adımlar
```

Depo nerede durursa dursun çalışır. İkiliye depo yolu gömülmez: `/usr/local/bin/dwl-session`
bu depodaki `bin/dwl-session`'a bağlantıdır, o da `DWL_HOME`'u (deponun kökü) verir; `config.h`'deki
kısayollar ve autostart `$DWL_HOME` üzerinden çağırır.

`dwl/dwl.c` ya da `dwl/config.h` değişince: `install/dwl.sh derle kur`, sonra çıkış-giriş.
Bar (`bar/*.qml`), temalar ve `bin/` altındaki betikler değişince kurulum gerekmez; bar dosya
kaydedilince kendini yeniden yükler.

## Neresi ne

| Yol | İçerik |
|---|---|
| `dwl/dwl.c`, `dwl/config.h` | compositor ve tuşlar (dwl kaynağı, git subtree). Yamalar: ipc, monitorconfig, autostart, animation, scenefx |
| `bin/dwl-session` | SDDM'in çalıştırdığı sarmalayıcı: ekran kartını sabitler, ortamı kurar |
| `bin/dwl-autostart` | oturumla başlayan her şey (bar, bildirim, polkit, pano...) |
| `bin/dwl-theme` | tema seçici ve üretici |
| `bin/dwl-keys`, `dwl-shot`, `dwl-clip`, `dwl-grab` | kısayol listesi, ekran görüntüsü, pano, indirme |
| `bin/dot-*` | oturumdan bağımsız araçlar (Drive, telefona gönderme, indirme, duvar geçişi haritası...) |
| `themes/*.json` | temalar; her biri tek dosya |
| `bar/` | Quickshell bar; `ipc/` altında dwl ile konuşan küçük istemci, `WallFx.qml` + `shaders/` duvar geçişi |
| `sddm/` | giriş ekranı teması, yenileme hızı betiği, kurulum |
| `portal/` | ekran paylaşımı için xdg-desktop-portal ayarları |

## Temalar

On iki tema var: Mürekkep, Kor, Fener, Evangelion, Bakır, Kar, Neon, Yosun, Nord, Catppuccin, Rosé Pine, Monokrom.

- Seç: Super+Ctrl+Shift+Space, bardaki palet düğmesi ya da `dwl-theme apply KIMLIK`.
- Tema değişince birlikte dönenler: pencere kenarlığı ve boşluğu, animasyon süresi, bar düzeni,
  Alacritty, fuzzel, dunst, hareketli duvar, kilit ekranı, giriş ekranı, Qt/KDE/GTK uygulama renkleri.
- Üretilen dosyalar `~/.local/state/dwl-theme/` altında; elle düzenlenmez.

Yuvarlak köşe, gölge ve blur (scenefx) tema başına açılır: `wm.radius`, `wm.shadow`, `wm.blur`
(yoksa kapalı). Şu an Kor ve Bakır kullanıyor; `term.opacity` terminali saydamlaştırır ki blur görünsün.

Yeni tema: `themes/` altına bir JSON kopyala, renkleri değiştir. `bar.layout` üç düzenden biri:
`strip` (üstte şerit), `islands` (yüzen adacıklar), `rail` (solda dikey ray). `live` listesi
Wallpaper Engine Workshop kimlikleridir (waywallen ile oynatılır).

Bilinen sınır: zaten açık Qt uygulamaları tema değişince yenilenmez, kapatıp açmak gerekir.

Qt/KDE/GTK renk dosyalarının tek yazarı dwl-theme'dir ve renkler oturumlar arasında kalır. (Kasım
2026'ya kadar bu dosyalar Hyprland oturumuyla ortaktı; dwl çıkışta eski hâllerini geri koyardı. O mantık
kaldırıldı. Yedek olarak duran Plasma oturumu da aynı `kdeglobals` renklerini görür.)

### Uygulamalar

Tema değişince bunlar da canlı döner (uygulamayı yeniden başlatmak gerekmez):

- **Obsidian:** `<kasa>/.obsidian/snippets/dwl-theme.css` (yalnız masaüstü; kasa yolu
  `DWL_THEME_OBSIDIAN`, varsayılan Aktif Kasa). Snippet kasanın `.stignore`'unda, telefona gitmez.
- **Discord (Vesktop):** `~/.config/vesktop/themes/savpavi.css`, `templates/vesktop.css` şablonundan.
  Açılış ekranı rengi de `~/.config/vesktop/settings.json`'a yazılır.
- **Spotify:** spicetify (Sleek) `color.ini` içine `[dwl]` şeması + `spicetify refresh -n`, ardından
  `dwl-theme spotify-live` açık istemcide colors.css'i yeniden yükler (sayfa yenilenmez, müzik sürer).
  Bunun için `~/.config/spotify-launcher.conf`: `extra_arguments = ["--remote-debugging-port=9333"]`
  (yalnız 127.0.0.1). spotify-launcher Spotify'ı güncelleyince: `spicetify backup apply -n`.
- **Telegram:** `~/.config/dwl-theme/telegram/dwl-theme.tdesktop-theme` (`templates/` altındaki
  matugen-themes şablonu, MIT). Bir kez uygulanır: dosyayı Kayıtlı Mesajlar'a gönder, mesajdaki
  dosyaya tıkla, Uygula. Telegram o yerel dosyayı izler. (Ayarlar'dan dosya seçme ya da pencereye
  sürükleme 7.4.4'te çalışmıyor.)

## Tuşlar

Tam liste Super+K ile açılır (`dwl/config.h`'den üretilir). En sık kullanılanlar:

| Tuş | İş |
|---|---|
| Super+Q / Alt+Space | terminal / uygulama başlatıcı |
| Super+C | pencereyi kapat |
| Super+1..9 | tag'e geç (Shift ile pencereyi taşı) |
| Super+ok tuşları | odak (Ctrl ile ana alanı boyutlandır) |
| Super+F / Super+M | tek pencere / döşeme |
| Super+L / Super+Esc | kilitle / güç menüsü |
| Super+X / Print | pano geçmişi / ekran görüntüsü |
| iki Shift birlikte | klavye düzeni tr / us |
| Super+Shift+Q | oturumu kapat |

## Deneme (çıkış yapmadan)

Çalışan oturumun içinde pencere olarak ikinci bir dwl açılabilir:

```sh
DWL_HOME=$PWD XDG_STATE_HOME=/tmp/dwl-deneme DWL_NESTED=1 DWL_THEME_NO_WALL=1 dwl/dwl
```

- `DWL_HOME`: deponun kökü; oturum sarmalayıcısı olmadan açınca elle verilir (yoksa bar ve kısayollar başlamaz).

- `DWL_NESTED=1`: yalnız bar başlar; gerçek oturumun polkit ajanı, bildirim servisi ve duvarı
  etkilenmez. Bu olmadan açılan deneme oturumu gerçek oturumun yetki pencerelerini düşürür.
- `XDG_STATE_HOME`: deneme, gerçek temaya dokunmadan kendi temasını kullanır.
- Panel açmak: `quickshell ipc --pid PID call panel toggle theme|notif|power|drive|send|net|claude`.
- Görüntü: `WAYLAND_DISPLAY=wayland-N timeout 3 grim dosya.png`. Deneme penceresi ekranda
  görünür değilken kare üretilmez; `timeout` olmadan `grim` sonsuza dek bekler.

## Geri dönüş noktaları

Eski ayrı dwl deposundaki (`savpavi/dwl`, arşiv) her çalışan aşama etiketliydi. Bu depoda geri dönüş
düz git: `git log`, `git checkout COMMIT`, sonra `install/dwl.sh derle kur`.

## Upstream'i güncelleme

dwl kaynağı `dwl/` altında git subtree: eski `savpavi` dalı geçmişiyle birlikte alındı. Taban v0.9
SÜRÜMÜ (etiket), upstream `main` değil; `dwl.c` yaklaşık 1100 satır ekleme taşıyor. C kaynağına dokunan değişiklikler
iki türlü ve aynı commit'lerde karışık: ayrı ayrı yama dosyası olarak DIŞA AKTARILMADI. Yeni bir dwl
sürümüne geçerken neyin nereden geldiğini bu tablo söyler (commit kimlikleri subtree geçmişinde durur).

**Üçüncü taraf yamalar** (`~/Projects/dwl-patches/patches/<ad>`; yeni sürümde önce bunların güncel hâli aranır):

| Yama | Girdiği commit | Elle uyarlanan |
|---|---|---|
| ipc, monitorconfig, autostart | `27541db` | yok |
| animation | `32f51b2` | `tile()` parçası elle; XWayland dalına `return 0`; tick 16→6 ms |
| scenefx | `e69b652` | `applygeom` parçası `animation_apply` içine; `snapshot` parçaları atıldı; `roundbuffer` `c->geom` kullanır |

**Kendi eklemelerim** (upstream'de karşılığı yok; her sürümde elle taşınır):

| Ne | İşlev / yer | Girdiği commit |
|---|---|---|
| Tema dosyasını canlı izleme (renk, kenarlık, gap, anim, radius, shadow, blur) | `themeread`, `themeapply`, `themewatch` | `27541db` |
| Monitör kuralında en yakın mod (`mode -2`), adaptive sync yalnız 1 ise | `monrule` çevresi | `27541db` |
| tile/monocle için gap, gap=0'da tek çizgi kenarlık | `tile`, `monocle` | `27541db`, `bf914c7` |
| Klavye düzenini dosyaya yazma | `kblayoutwrite` | `8fcef1d` |
| Kurallar: çıkış adıyla monitör, harf duyarsız eşleşme, `=` tam eşleşme, `panel` | `applyrules`, `Rule` | `436216e`, `a0c3106` |
| Aç ya da git | `focusorspawn`, `APP()` | `a9cd591` |
| Kopan ekranın pencerelerini geri götürme | `restoremons`, `Client.origmon` | `85ace62` |
| İmleç temasını canlı değiştirme | `cursorreload` | `27af7a6` |

Yol (önce çalışan durumu commit'le; geri dönüş noktası odur):

```sh
git subtree pull --prefix=dwl https://codeberg.org/dwl/dwl.git main
```

Bu, upstream'deki yeni commit'leri `dwl/` altına birleştirir. Derledikten sonra `tests/themes.sh`
çalıştır; kurulu ikiliyi değil yeni derlenen `dwl/dwl`'yi dener.

Deneme (14 Kas 2026, geçici çalışma ağacında, sonra iptal edildi): komut çalışıyor, tabanı (v0.9) doğru
buluyor. O gün upstream `main` v0.9'dan 75 commit ilerideydi (0.10-dev, yine wlroots 0.20) ve birleştirme
16 çakışma bloğu verdi: `dwl.c` 13, `client.h` 2, `config.def.h` 1. Yani güncelleme mekanik olarak hazır,
ama elle çözülecek gerçek bir iş. Geliştirme dalı yerine sürüm etiketini beklemek daha sakin bir yol:
`main` yerine etiket adı verilir (ör. `v0.10`).

## Denetim ve test

```sh
dwl-theme check            # tema dosyaları: eksik/yanlış tipte anahtar, bozuk renk (hata),
                           # yazım hatası, kurulu olmayan imleç, eksik duvar (uyarı)
tests/themes.sh            # her temayı başsız bir dwl oturumunda uygular
tests/themes.sh kor nord   # yalnız verilenler
```

`tests/themes.sh` önce `check` çalıştırır, sonra ekransız bir dwl açıp temaları sırayla uygular
ve her birinde statik duvarı değiştirir. dwl ya da bar çökerse, durum dosyaları yazılmazsa ya da
bar günlüğünde QML hatası çıkarsa başarısız olur. Gerçek oturuma dokunmaz (geçici durum dizini,
`DWL_NESTED=1`); 12 tema yaklaşık yarım dakika sürer. Görüntüyü denetlemez: "çökmedi" der,
"doğru göründü" demez. Yeni tema ekledikten ya da `bar/` ve `dwl-theme`'i değiştirdikten sonra çalıştır.

Temaya yeni bir anahtar eklenirse `bin/dwl-theme` içindeki `SCHEMA_REQUIRED` / `SCHEMA_OPTIONAL`
tablosuna da yazılmalı, yoksa `check` onu "tanınmayan anahtar" diye uyarır.

## Bağımlı olduğu, bu depoda olmayan şeyler

- waywallen (Flatpak) ve `~/.local/bin/waywallen-layer-shell` (hareketli duvar)
- `brave-origin-bin` (AUR)
- `vesktop-bin` (AUR), spicetify + `spotify-launcher`, `telegram-desktop` (uygulama renkleri)
- Kişisel dosyalar, repo dışında: `~/.config/dwl-theme/walls.json` (tema → statik duvar listesi),
  `~/.config/dwl-theme/telegram/` (üretilen Telegram teması)

Eksik komutları ve elle kurulanları `install/dwl.sh denetle` söyler.
