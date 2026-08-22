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

## Kaynak

Tema sistemi [basecamp/omarchy](https://github.com/basecamp/omarchy)
(MIT) projesinden uyarlandı. Bkz. `themes/UPSTREAM.md`.
