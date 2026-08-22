# dotfiles

Fedora 44 + Hyprland masaüstü yapılandırması.

## Yapı

```
config/     -> ~/.config/<isim> olarak symlink edilir
bin/        -> yardımcı script'ler (PATH'e eklenir)
themes/     -> renk temaları (omarchy'den uyarlandı)
templates/  -> tema şablonları (*.tpl)
```

## Kurulum

```bash
git clone <repo> ~/dotfiles
~/dotfiles/bin/dot-link
```

`dot-link`, `~/.config` altındaki mevcut dosyaları
`~/.local/share/dotfiles-backup/<tarih>/` içine taşır, yerlerine symlink koyar.
Geri almak için: `dot-link --unlink` sonra yedekten kopyala.

## Tema değiştirme

```bash
dot-theme list          # temalar (aktif olan * ile)
dot-theme set gruvbox   # temayı uygula
dot-theme next          # sıradaki temaya geç
dot-theme bg            # aktif temanın sıradaki duvar kağıdı
dot-theme menu          # rofi ile seç
dot-theme reapply       # aktif temayı yeniden uygula
dot-theme set X --no-bg # duvar kağıdına dokunma
```

Kısayollar: `SUPER+SHIFT+T` tema menüsü, `SUPER+CTRL+SHIFT+T` duvar kağıdı.

### Neyi boyuyor

| Uygulama | Üretilen dosya | Bağlantı |
|---|---|---|
| kitty | `kitty/active-theme.conf` | `include active-theme.conf` (mevcuttu) |
| ghostty | `ghostty/theme.conf` | `config-file = theme.conf` (config sonunda) |
| alacritty | `alacritty/active-theme.toml` | `import` (mevcuttu) |
| btop | `btop/themes/dot-theme.theme` | `color_theme = "dot-theme"` |
| rofi | `rofi/colors.rasi` | `@theme` (mevcuttu) |
| swaync | `swaync/colors.css` | `@import` (mevcuttu) |
| wlogout | `wlogout/colors.css` | `@import` (mevcuttu) |
| hyprlock | `hypr/hypr-theme.conf` | `source =` |
| hyprland | `hypr/hyprland-theme.lua` | `require("hyprland-theme")` |
| **waybar** | `waybar/colors.css` | **henüz bağlı değil** |
| hyprpaper | `hyprpaper.conf` DP-1 path | doğrudan yazılır |

Waybar'ı bağlamak için `waybar/style.css` başındaki `@define-color` bloğunu
silip yerine tek satır koy:

```css
@import "colors.css";
```

Duvar kağıdı yalnızca `DOT_THEME_MONITORS` (varsayılan `DP-1`) monitörlerine
uygulanır — DP-3 dikey olduğu için manzara görselleri oraya oturmuyor.

## Kaynak

Tema sistemi [basecamp/omarchy](https://github.com/basecamp/omarchy)
(MIT) projesinden uyarlandı. Bkz. `themes/UPSTREAM.md`.
