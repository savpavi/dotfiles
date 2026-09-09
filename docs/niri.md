# Niri + Noctalia

9 Eylül 2026 tarihinde etkin Fedora 44 / Niri 26.04 oturumundan alınan
`config/niri/config.kdl`, kaynak dosyanın birebir kopyasıdır.

## Yapılandırma

- DP-1: 2560×1440, yaklaşık 180 Hz; çalışma alanları 1–5.
- DP-3: 1920×1080, yaklaşık 120 Hz, yatay; çalışma alanları 6–10.
- Türkçe / İngilizce klavye; `Super+Space` ile geçiş.
- Yeni pencereler tam genişlikte sütunlarda açılır.
- Looking Glass, DP-3 üzerinde tam ekran açılır.

Başka bir makinede ekran adlarını, çözünürlükleri ve kişisel yolları uyarlayın.

## Bağımlılıklar

Niri ve Noctalia yanında Ghostty, Dolphin, `hyprpolkitagent.service`,
`wl-paste` (wl-clipboard), cliphist, Solaar, wpctl ve playerctl çağrılır.
Uygulama kısayolları Brave Origin, Zed ve şu Flatpak kimliklerini kullanır:
`com.spotify.Client`, `org.telegram.desktop`, `com.discordapp.Discord`,
`md.obsidian.Obsidian`.

`Super+W`, `/home/savpavi/.local/bin/start-windows-looking-glass`
başlatıcısını çağırır. Bu kişisel script ve sanal makine bu depoda değildir;
başka bir makinede kısayolu uyarlayın veya kaldırın. Noctalia ayarları da bu
Niri yedeğine dahil değildir.

## Yalnız Niri ayarını geri yükleme

Repo kökünde, önce depodaki dosyayı doğrulayın ve mevcut ayarı yedekleyin:

```bash
niri validate --config config/niri/config.kdl
mkdir -p ~/.config/niri
if [ -e ~/.config/niri/config.kdl ]; then
    cp -a ~/.config/niri/config.kdl ~/.config/niri/config.kdl.bak-$(date +%Y%m%d-%H%M%S)
fi
cp config/niri/config.kdl ~/.config/niri/config.kdl
niri validate --config ~/.config/niri/config.kdl
```

Niri çalışan oturumda yapılandırma değişikliğini otomatik yükler. Genel
`dot-link` komutu ise tüm `config/` klasörlerini bağlar; yalnız Niri için
üstteki dosya kopyalama adımlarını kullanın.

## Temel kısayollar

`Mod`, bu oturumda Super/Windows tuşudur. Tüm bağlar `config.kdl` içindedir.

| Kısayol | İşlem |
|---|---|
| Super+Q / Super+E | Ghostty / Dolphin |
| Alt+Space | Noctalia uygulama başlatıcısı |
| Super+C | Pencereyi kapat |
| Super+F / Super+Shift+F | Tam ekran / sütunu tam genişliğe getir |
| Super+V | Yüzen pencereyi aç/kapat |
| Super+Tab | Genel görünüm |
| Super+1…9, Super+0 | Çalışma alanı 1…10 |
| Super+Shift+1…9, Super+Shift+0 | Sütunu çalışma alanına taşı |
| Super+L | Ekranı kilitle |
| Super+W | Windows / Looking Glass başlatıcısı |
| Print / Shift+Print / Alt+Print | Ekran / seçim / pencere görüntüsü |
| Super+Shift+Slash | Kısayol yardımını göster |

## Yedeği güncelleme

Etkin yapılandırma ayrı `savpavi/niri-dotfiles` deposunda,
`~/.config/niri/` altında da tutulur. Bu depodaki kopya otomatik eşitlenmez.
Güncellemek için bu repo kökünde:

```bash
cp ~/.config/niri/config.kdl config/niri/config.kdl
niri validate --config config/niri/config.kdl
git diff --check
git diff -- config/niri/config.kdl
```
