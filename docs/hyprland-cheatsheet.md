# Hyprland Kısayol Rehberi

`SUPER` = Windows tuşu. Aramak için `SUPER + K`.

## Uygulamalar

| Kısayol | İşlev |
|---|---|
| `SUPER + Q` | Kitty terminali aç |
| `SUPER + E` | Dolphin dosya yöneticisini aç |
| `Alt + Space` | Hyprlauncher uygulama menüsünü aç |
| `Alt + Space` sonra `=` | Hesap makinesi — sonuç panoya kopyalanır |
| `Alt + Space` sonra `u:` | Unicode karakter ara, seçilen panoya |
| `Alt + Space` sonra `f:` | Font ara, seçilen ad panoya |
| `SUPER + B` | Firefox'u aç |
| `SUPER + W` | Windows VM'yi Looking Glass ile aç |
| `SUPER + S` | Spotify'ı aç |
| `SUPER + T` | Telegram'ı aç |
| `SUPER + D` | Discord'u aç |
| `SUPER + Z` | Zed'i aç |
| `SUPER + O` | Obsidian'ı aç |
| `SUPER + A` | Ente Auth'u aç |
| `Ctrl + X` | Pano geçmişini aç; seçileni panoya kopyala |

## Pencere Yönetimi

| Kısayol | İşlev |
|---|---|
| `SUPER + C` | Aktif pencereyi kapat |
| `SUPER + V` | Pencereyi yüzer/döşeli yap |
| `SUPER + F` | Tam ekranı aç/kapat |
| `SUPER + N` | Pencereyi gizli `minimized` çalışma alanına taşı |
| `SUPER + Shift + N` | Gizli `minimized` çalışma alanını göster/gizle |
| `SUPER + P` | Pseudo-tile modunu aç/kapat |
| `SUPER + J` | Dwindle bölünme yönünü değiştir |
| `SUPER + Sol/Sağ/Yukarı/Aşağı` | O yöndeki pencereye odaklan |
| `SUPER + Shift + Sol/Sağ` | Pencereyi sol/sağ monitöre taşı ve takip et |
| `SUPER + Sol tık sürükle` | Pencereyi taşı |
| `SUPER + Sağ tık sürükle` | Pencereyi yeniden boyutlandır |
| `Alt + Tab` | Pencereler arasında gez (öne getirir) |
| `Alt + Shift + Tab` | Ters yönde gez |

## Pencere Boyutlandırma

| Kısayol | İşlev |
|---|---|
| `SUPER + Ctrl + Sol/Sağ` | Genişliği 40 px azalt/artır |
| `SUPER + Ctrl + Yukarı/Aşağı` | Yüksekliği 40 px artır/azalt |
| `SUPER + -` / `SUPER + =` | Genişliği 100 px azalt/artır |
| `SUPER + Alt + -` / `=` | 25 px — ince ayar |
| `SUPER + Ctrl + -` / `=` | 300 px — kaba ayar |
| `+ Shift` ekle | Aynı işlem dikey eksende |

## Pencere Grupları (sekmeli pencere)

Birden fazla pencereyi tek pencerede sekmeli tutar.

| Kısayol | İşlev |
|---|---|
| `SUPER + G` | Grubu aç/kapa |
| `SUPER + Alt + G` | Aktif pencereyi gruptan çıkar |
| `SUPER + Alt + Sol/Sağ/Yukarı/Aşağı` | Pencereyi o yöndeki gruba taşı |
| `SUPER + Alt + Tab` | Grupta sonraki sekme |
| `SUPER + Alt + Shift + Tab` | Grupta önceki sekme |
| `SUPER + Alt + Fare tekeri` | Grup sekmeleri arasında gez |
| `SUPER + Alt + 1…5` | Doğrudan o sekmeye atla |

## Çalışma Alanları

| Kısayol | İşlev |
|---|---|
| `SUPER + 1…9` | Çalışma alanı 1–9'a geç |
| `SUPER + 0` | Çalışma alanı 10'a geç |
| `SUPER + Shift + 1…9` | Aktif pencereyi çalışma alanı 1–9'a taşı |
| `SUPER + Shift + 0` | Aktif pencereyi çalışma alanı 10'a taşı |
| `SUPER + Fare tekeri` | Çalışma alanları arasında gezin |
| `SUPER + Tab` | Sonraki çalışma alanı |
| `SUPER + Shift + Tab` | Önceki çalışma alanı |
| `SUPER + Ctrl + Tab` | En son bulunduğun çalışma alanına dön |
| `SUPER + \`` | Scratchpad'i aç/kapa |
| `SUPER + Shift + \`` | Aktif pencereyi scratchpad'e taşı |
| `SUPER + Shift + Alt + Sol/Sağ/Yukarı/Aşağı` | Çalışma alanının tamamını komşu monitöre taşı |
| `Ctrl + Alt + Tab` | Sonraki monitöre odaklan |
| `Ctrl + Alt + Shift + Tab` | Önceki monitöre odaklan |

Çalışma alanları `1–5` ana monitöre (`DP-1`), `6–10` ikinci monitöre (`DP-3`) atanmıştır.

**Scratchpad vs `minimized`:** `minimized` pencereyi gözden kaldırmak için;
scratchpad hep açık duran yardımcı pencere (terminal, not defteri) için.

## Tema

| Kısayol | İşlev |
|---|---|
| `SUPER + Shift + T` | Tema menüsünü aç (hyprlauncher) |
| `SUPER + Ctrl + Shift + T` | Arşivden rastgele duvar kağıdına geç (iki ekran) |
| `SUPER + Shift + W` | Duvar kağıdı GUI'si (waypaper, iki ekran) |

Terminalden: `dot-theme list`, `dot-theme set gruvbox`, `dot-theme next`.
22 tema var; kitty, waybar, rofi, swaync, wlogout, btop, hyprlock,
hyprlauncher ve pencere kenarlıkları birlikte değişir.

Seçici olarak hyprlauncher kullanılıyor (`SUPER + K` kısayol listesi de aynısını
kullanır). Eski davranış için: `DOT_MENU=rofi dot-theme menu`.

## Sistem

| Kısayol | İşlev |
|---|---|
| `SUPER + K` | Bu rehberi aç (aranabilir) |
| `SUPER + L` | Ekranı kilitle |
| `SUPER + Escape` | Çıkış menüsünü aç |
| `SUPER + M` | Hyprland kapatma/çıkış işlemini başlat |
| `SUPER + Shift + B` | Waybar'ı yeniden başlat |
| `Print Screen` | Tüm ekran → dosya + pano + bildirim |
| `Shift + Print Screen` | Bölge seç → satty'de düzenle (Enter kopyala, Ctrl+S kaydet) |
| `Ctrl + Print Screen` | Bölge seç → doğrudan pano + dosya |
| `SUPER + Print Screen` | Renk seçici (hyprpicker) — tekrar basınca kapanır |

Ekran görüntüleri `~/Pictures/Screenshots/` klasörüne zaman damgalı PNG olarak kaydedilir.

## Araçlar (end-4 uyarlamaları, 28.08.2026)

| Kısayol | İşlev |
|---|---|
| `SUPER + SHIFT + X` | OCR: bölge seç → metin panoya (tesseract, tr+eng) |
| `SUPER + SHIFT + R` | Ekran kaydı: bölge seç; tekrar basınca durur (`~/Videos/Recordings`) |
| `CTRL + ALT + R` | Ekran kaydı: aktif monitör |
| `SUPER + SHIFT + ALT + R` | Ekran kaydı: aktif monitör + sistem sesi |
| `SUPER + SHIFT + P` | Pencereyi sabitle (pin) — her workspace'te görünür |
| `SUPER + SHIFT + F` | Maximize (bar görünür kalır; `SUPER+F` tam ekran) |
| `SUPER + ş` / `SUPER + i` | Bölme oranı -/+ (US düzende `;` / `'`) |
| `SUPER + Numpad -` / `Numpad +` | Ekran zoom -/+ (en fazla 3x) |
| `SUPER + Numpad *` | Zoom sıfırla |
| `ALT + F4` | Kapatmaz; hatırlatma bildirimi (VM içinde normal çalışır) |

Otomatik kurallar: dosya aç/kaydet diyalogları yüzer+ortada, "is sharing your screen" çubuğu alt ortada sabit, `steam_app`/`.exe` için tearing, tile pencerelerde gölge yok, odaksız pencere %5 karartma, sürüklerken yapışma (snap). Kaynak: `~/.config/hypr/extras.lua`.

## Medya Tuşları

| Tuş | İşlev |
|---|---|
| Ses artır/azalt | Sesi %5 değiştir |
| Sessiz | Hoparlör sesini aç/kapat |
| Mikrofon sessiz | Mikrofonu aç/kapat |
| Parlaklık artır/azalt | Parlaklığı %5 değiştir |
| Sonraki / Önceki | Sonraki/önceki parçaya geç |
| Oynat / Duraklat | Medyayı oynat/duraklat |

## Diğer Kullanışlı Bilgiler

- `SUPER + Space`, klavye düzenini Türkçe ve İngilizce arasında değiştirir.
- Üç parmakla yatay kaydırma, çalışma alanını değiştirir.
- Ana ekran: `DP-1`, 2560×1440 @ 180 Hz.
- İkinci ekran: `DP-3`, 1920×1080 @ 119.98 Hz, dikey.
- Looking Glass (Windows VM) `DP-1`'de tam ekran açılır.
- Pencereler hafif saydam (`0.985 / 0.96`); video, oyun, VM ve tam ekran hariç.
- Tarayıcı Picture-in-Picture penceresi otomatik olarak sağ üste sabitlenir.
