# omarchy quattro modülleri — değerlendirme ve puanlama

`windows.lua` uygulandı (bkz. `~/.config/hypr/windows.lua`). Bu dosya geri kalan
modülleri, **mevcut `hyprland.lua`'nla karşılaştırarak** puanlıyor.

Puanlama: **Zorluk** 1 (kopyala-yapıştır) → 5 (yeniden yazmak gerekir).
**Kazanç** 0 (sende zaten var) → 5 (ciddi eksik kapanır).

| Modül | Zorluk | Kazanç | Karar |
|---|:---:|:---:|---|
| `bindings/tiling.lua` (çakışmayan kısım) | 3 | **4** | **Al** |
| `autostart.lua` (ilk 2 satır) | **1** | 3 | **Al** |
| `looknfeel.lua` (sadece misc bloğu) | 2 | 2 | Al, isteğe bağlı |
| `bindings/utilities.lua` (sadece hyprpicker) | 1 | 1 | Al, tek satır |
| `bindings/clipboard.lua` | 4 | 2 | Bekle |
| `input.lua` | 2 | 1 | **Alma — riskli** |
| `envs.lua` | 3 | 1 | **Alma — riskli** |
| `bindings/applications.lua` | 4 | 1 | Alma |
| `bindings/media.lua` | 3 | **0** | Alma — sende zaten var |

---

## `bindings/tiling.lua` — Zorluk 3 / Kazanç 4

Tek kelimeyle en değerlisi. Sende **olmayan** gerçek özellikler:

- **Pencere grupları (sekmeli pencere).** `SUPER+G` grup aç/kapa,
  `SUPER+ALT+ok` pencereyi gruba taşı, `SUPER+ALT+TAB` grup içinde gez,
  `SUPER+ALT+1..5` doğrudan sekmeye atla, `SUPER+ALT+tekerlek` sekme değiştir.
  Hyprland'ın en çok kaçırılan özelliği; iki terminali tek pencerede sekmeli
  tutmak gibi.
- **Scratchpad.** `SUPER+grave` ile açılıp kapanan özel çalışma alanı.
  Sende `special:minimized` var ama o "pencereyi kaldır" için; scratchpad
  "hep açık duran yardımcı pencere" kullanımı.
- **ALT+TAB pencere döngüsü** + `bring_to_top`. Sende hiç yok.
- **Klavyeyle boyutlandırma, 3 kademe** — 25 / 100 / 300 piksel.
  Sende tek kademe var (`SUPER+CTRL+ok`, 40 px).
- **Çalışma alanını komşu monitöre taşı** (`SUPER+SHIFT+ALT+ok`).
  Çift monitörde işe yarar, sende yok.
- **Monitör odağı** `CTRL+ALT+TAB`.

### Çakışma haritası

Senin bind'lerin korunur; çakışanlar **alınmaz**:

| omarchy | omarchy işlevi | sende ne var | sonuç |
|---|---|---|---|
| `SUPER+W` | pencere kapat | Windows VM / Looking Glass | çakışır |
| `SUPER+T` | float aç/kapa | Telegram | çakışır |
| `SUPER+S` | scratchpad | Spotify | çakışır → `SUPER+grave` kullan |
| `SUPER+L` | layout aç/kapa | hyprlock | çakışır |
| `SUPER+O` | pencereyi dışarı al | Obsidian | çakışır |
| `SUPER+F` | tam ekran | tam ekran | aynı, zaten var |
| `SUPER+J` | split aç/kapa | split aç/kapa | aynı, zaten var |
| `SUPER+P` | pseudo | pseudo | aynı, zaten var |
| `SUPER+G`, `SUPER+ALT+*`, `ALT+TAB`, `SUPER+grave`, `CTRL+ALT+TAB`, `SUPER+SHIFT+ALT+ok` | gruplar, scratchpad, döngü | — | **boş, alınabilir** |

8 satır `omarchy-hyprland-*` script'i çağırıyor (tiled fullscreen, window pop,
pencere genişliği kaydet/geri yükle, monitör ölçekleme, tümünü kapat) —
bunlar atlanır.

---

## `autostart.lua` — Zorluk 1 / Kazanç 3

14 satırın 10'u omarchy servisi başlatıyor, işe yaramaz. Ama ilk iki satır
sende olmayan gerçek bir boşluğu kapatıyor:

```lua
hl.exec_cmd("systemctl --user import-environment $(env | cut -d'=' -f 1)")
hl.exec_cmd("dbus-update-activation-environment --systemd --all")
```

Oturum ortam değişkenlerini systemd user session ve dbus tarafına aktarır.
Belirtisi: portal / dosya seçici / flatpak uygulamalarının yavaş açılması ya da
yanlış ortamla açılması. Solaar'ın Hyprland'da xdg autostart ile başlamaması
notundaki sorunun kuzeni. En ucuz kazanç.

---

## `looknfeel.lua` — Zorluk 2 / Kazanç 2

**Animasyonlar sende zaten var** — eğri isimleri (`easeOutQuint`,
`almostLinear`, `quick`) ve leaf hızları neredeyse birebir aynı; üstelik
`windows` / `windowsIn` leaf'lerini spring'e çevirmişsin, omarchy'ninkinden
daha iyi. Buradan alınacak bir şey yok.

**Görünüm ayarları geriye götürür:** omarchy `rounding = 0`, blur kapalı,
shadow kapalı, `gaps 5/10`. Sende `rounding = 9`, gaps 6/12. Zevk tercihi,
iyileştirme değil.

**Alınmaya değer tek parça, `misc`/`cursor`/`binds` bloğu (~10 satır):**

```lua
misc = {
    disable_splash_rendering    = true,
    disable_scale_notification  = true,
    focus_on_activate           = true,   -- uygulama kendini öne çağırınca odaklan
    anr_missed_pings            = 3,      -- donmuş uygulama uyarısı
    on_focus_under_fullscreen   = 1,
    initial_workspace_tracking  = 0,
},
cursor = {
    hide_on_key_press        = true,      -- yazarken imleç kaybolur
    warp_on_change_workspace = 1,
},
binds = { hide_special_on_workspace_change = true },
```

Çakışma yok, hepsi güvenli. `groupbar` stili de var ama gruplamayı
kullanmıyorsan boş — `tiling.lua`'dan grupları alırsan birlikte gelsin.

---

## `bindings/utilities.lua` — Zorluk 5 / Kazanç 1

126 satırın 53'ü `omarchy-menu` / `omarchy-shell` çağırıyor; hepsi Quickshell
tabanlı shell'e bağlı, taşınamaz.

Kendi kendine çalışan **tek satır**:

```lua
hl.bind("SUPER + PRINT", hl.dsp.exec_cmd("pkill hyprpicker || hyprpicker -a"))
```

Renk seçici. `hyprpicker` sistemde kurulu, `SUPER+PRINT` boş.

İlginç ama taşınamaz olan: slurp bölge seçicisi ekrandayken geçici bind kurma
(`layer.opened` / `layer.closed` olayları) — Enter ile vurgulanan pencereyi
yakala, Tab ile pencereler arasında gez. Fikir güzel, ama `omarchy-capture-region`
script'ini de yazman gerekir.

---

## `bindings/clipboard.lua` — Zorluk 4 / Kazanç 2

`SUPER+C` / `SUPER+V` / `SUPER+X` her yerde kopyala-yapıştır-kes; odaktaki
pencere terminal ise otomatik `Ctrl+Insert` / `Shift+Insert`'e çeviriyor.
Terminal ile GUI arasındaki kopyala-yapıştır farkını ortadan kaldırıyor.

Neden şimdi değil:

- `SUPER+C` senin "pencere kapat", `SUPER+V` senin "float aç/kapa" bind'in.
  İkisini de başka tuşa taşımak gerekir.
- `hl.dsp.send_key_state`, `hl.timer`, `hl.get_active_window()` API'lerine
  ve pencerelerde `terminal` etiketine dayanıyor. Etiket omarchy'nin
  `apps/terminals.lua` dosyasından geliyor, onu da yazmak lazım.
- Hyprland'ın `send_shortcut` davranışındaki bilinen takılma sorununa karşı
  down/up ayrımı + 50 ms timer ile çalışıyor; kırılgan.

---

## `input.lua` — Zorluk 2 / Kazanç 1 — **RİSKLİ**

`/etc/vconsole.conf`'tan `XKBLAYOUT` okuyup Latin olmayan bir layout ilk sıradaysa
başına `us` ekliyor (Hyprland kısayolları ilk layout'a göre çözdüğü için).

**Sende bunu bozar:** `kb_layout = "tr,us"` ve `kb_options = "grp:win_space_toggle"`
kullanıyorsun. omarchy `kb_options`'ı `compose:caps,shift:both_capslock_cancel`
yapıp üzerine yazar → Türkçe/İngilizce layout geçişin gider.

Geri kalanı touchpad ayarları (`clickfinger_behavior`, `scroll_factor`) ve
terminal başına `scroll_touchpad` — masaüstünde tamamen ölü.

Çalınmaya değer tek fikir: CapsLock'u compose tuşu yapmak. İstersen `kb_options`
satırına `compose:caps` eklemen yeterli, modüle gerek yok.

---

## `envs.lua` — Zorluk 3 / Kazanç 1 — **RİSKLİ**

Wayland ortam değişkenleri (`GDK_BACKEND`, `MOZ_ENABLE_WAYLAND`,
`ELECTRON_OZONE_PLATFORM_HINT`, `OZONE_PLATFORM`...). Çoğu uwsm/oturum
tarafından zaten set ediliyor.

**Çakışma:** `QT_QPA_PLATFORMTHEME = gtk3` — senin Plasma + klassy Qt temanı
ezer, Qt uygulamalarının görünümü değişir.

Geri kalanı omarchy'ye özel: `PATH`'e `$OMARCHY_PATH/bin` enjeksiyonu,
`OMARCHY_PATH` env'i, `require("default.hypr.nvidia")`.

`xwayland.force_zero_scaling` işe yarardı ama iki monitörün de `scale = 1`,
gerek yok.

---

## `bindings/media.lua` — Zorluk 3 / Kazanç 0

34 satırın 26'sı `omarchy-audio-*` / `omarchy-brightness-*` / `omarchy-shell media`
çağırıyor. Sende `hyprland.lua` satır 363-374'te aynı işi `wpctl`, `playerctl`
ve `brightnessctl` ile yapan bind'ler **zaten var**.

Geri kalanı laptop'a özel: klavye arka aydınlatma, touchpad aç/kapa, lid switch.
Masaüstünde karşılığı yok.

---

## `bindings/applications.lua` — Zorluk 4 / Kazanç 1

Her satır `omarchy-launch-*` sarmalayıcısı çağırıyor; sende zaten doğrudan
flatpak/binary çalıştıran karşılıkları var.

Çalınmaya değer iki **fikir** (kod değil):

- **launch-or-focus** — uygulama zaten açıksa yeni pencere açmak yerine ona odaklan.
- **webapp** — bir siteyi ayrı pencere uygulaması gibi aç (Chromium `--app=`).

İkisi de yeni script yazmak demek; kopyalanabilir bir şey yok.
