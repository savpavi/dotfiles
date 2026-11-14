# dwl (savpavi dalı)

dwl v0.9 üstüne kişisel kurulum: çalışırken değişen temalar, Quickshell bar, hareketli duvar,
kilit ve giriş ekranı. Upstream `README.md` olduğu gibi duruyor; bu dosya bu dalı anlatır.

Hyprland + savpavi-shell kurulumuna dokunmaz; SDDM'de ayrı bir oturum olarak durur.

## Kurulum

```sh
./install.sh            # paketler, derleme, kurulum, giriş ekranı, kullanıcı ayarları, güvenlik duvarı
./install.sh --dry-run  # ne yapacağını yalnız yazdır
./install.sh derle kur  # yalnız seçilen adımlar
```

Depo `/home/savpavi/Projects/dwl` altında durmalı (`config.h` ve `dwl.desktop` bu yolu kullanır).

`dwl.c` ya da `config.h` değişince: `sudo make install`, sonra çıkış-giriş.
Bar (`bar/*.qml`), temalar ve `bin/` altındaki betikler değişince kurulum gerekmez; bar dosya
kaydedilince kendini yeniden yükler.

## Neresi ne

| Yol | İçerik |
|---|---|
| `dwl.c`, `config.h` | compositor ve tuşlar. Yamalar: ipc, monitorconfig, autostart, animation, scenefx |
| `bin/dwl-session` | SDDM'in çalıştırdığı sarmalayıcı: ekran kartını sabitler, ortamı kurar |
| `bin/dwl-autostart` | oturumla başlayan her şey (bar, bildirim, polkit, pano...) |
| `bin/dwl-theme` | tema seçici ve üretici |
| `bin/dwl-keys`, `dwl-shot`, `dwl-clip`, `dwl-grab` | kısayol listesi, ekran görüntüsü, pano, indirme |
| `themes/*.json` | temalar; her biri tek dosya |
| `bar/` | Quickshell bar; `ipc/` altında dwl ile konuşan küçük istemci |
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

Qt/KDE/GTK renk dosyaları Hyprland oturumuyla ortaktır. dwl ilk yazmadan önce yedekler, çıkışta
geri koyar. Elle geri almak için: `dwl-theme host-restore`.

### Uygulamalar

Tema değişince bunlar da canlı döner (uygulamayı yeniden başlatmak gerekmez):

- **Obsidian:** `<kasa>/.obsidian/snippets/dwl-theme.css` (yalnız masaüstü; kasa yolu
  `DWL_THEME_OBSIDIAN`, varsayılan Aktif Kasa). Snippet kasanın `.stignore`'unda, telefona gitmez.
- **Discord (Vesktop):** `~/.config/vesktop/themes/savpavi.css`, `~/dotfiles/templates/apps/vesktop.css`
  şablonundan. Hyprland'deki dot-shell-theme aynı dosyayı yazar; dwl yedekler, çıkışta geri koyar.
  Açılış ekranı rengi de `~/.config/vesktop/settings.json`'a yazılır.
- **Spotify:** spicetify (Sleek) `color.ini` içine `[dwl]` şeması + `spicetify refresh -n`, ardından
  `dwl-theme spotify-live` açık istemcide colors.css'i yeniden yükler (sayfa yenilenmez, müzik sürer).
  Bunun için `~/.config/spotify-launcher.conf`: `extra_arguments = ["--remote-debugging-port=9333"]`
  (yalnız 127.0.0.1). spotify-launcher Spotify'ı güncelleyince: `spicetify backup apply -n`.
- **Telegram:** `~/.config/dwl-theme/telegram/dwl-theme.tdesktop-theme` (`templates/` altındaki
  matugen-themes şablonu, MIT). Bir kez uygulanır: dosyayı Kayıtlı Mesajlar'a gönder, mesajdaki
  dosyaya tıkla, Uygula. Telegram o yerel dosyayı izler. (Ayarlar'dan dosya seçme ya da pencereye
  sürükleme 7.4.4'te çalışmıyor.)

Hyprland'e dönünce Discord kendi rengine döner; Obsidian, Spotify ve Telegram son dwl renginde kalır.

## Tuşlar

Tam liste Super+K ile açılır (`config.h`'den üretilir). En sık kullanılanlar:

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
XDG_STATE_HOME=/tmp/dwl-deneme DWL_NESTED=1 DWL_THEME_NO_WALL=1 ./dwl
```

- `DWL_NESTED=1`: yalnız bar başlar; gerçek oturumun polkit ajanı, bildirim servisi ve duvarı
  etkilenmez. Bu olmadan açılan deneme oturumu gerçek oturumun yetki pencerelerini düşürür.
- `XDG_STATE_HOME`: deneme, gerçek temaya dokunmadan kendi temasını kullanır.
- Panel açmak: `quickshell ipc --pid PID call panel toggle theme|notif|power|drive|send|net|claude`.
- Görüntü: `WAYLAND_DISPLAY=wayland-N timeout 3 grim dosya.png`. Deneme penceresi ekranda
  görünür değilken kare üretilmez; `timeout` olmadan `grim` sonsuza dek bekler.

## Geri dönüş noktaları

Her çalışan aşama etiketli (`git tag`). Bir etikete dönmek:

```sh
git checkout ETIKET && sudo make install
```

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

- `~/dotfiles/bin/dot-drive`, `dot-send`, `dot-grab` ve
  `~/dotfiles/config/savpavi-shell/scripts/claude-usage.sh` (bar ve indirme kısayolu çağırır)
- `~/dotfiles/bin/dot-wallfx` ve duvar geçişinin QML'i + shader'ı: `bar/WallFx.qml` ve `bar/shaders`
  bu depoda `~/dotfiles/config/savpavi-shell/wallpaper/` altına göreli bağlantıdır (tek kopya orada;
  depo `~/Projects/dwl`, dotfiles `~/dotfiles` altında durmalı). Eksikleri `./install.sh dotfiles` söyler.
- waywallen (Flatpak) ve `~/.local/bin/waywallen-layer-shell` (hareketli duvar)
- `brave-origin-bin` (AUR)
- `vesktop-bin` (AUR), spicetify + `spotify-launcher`, `telegram-desktop` (uygulama renkleri)
