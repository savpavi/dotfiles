# dot-theme tarafından üretildi — elle düzenleme.
# Hyprtoolkit tabanlı uygulamaların (hyprlauncher) görünümü.
# Konum: ~/.config/hypr/hyprtoolkit.conf

# --- renkler ---
# background saydam bırakıldı; bulanıklık hyprland.lua'daki
# "hyprlauncher-blur" layer_rule'undan geliyor.
background            = rgba({{ background_strip }}f2)
alternate_base        = rgba({{ lighter_background_strip }}ff)
bright_text           = rgba({{ bright_foreground_strip }}ff)
link_text             = rgba({{ accent_strip }}ff)
accent                = rgba({{ accent_strip }}ff)
accent_secondary      = rgba({{ magenta_strip }}ff)

# --- biçim ---
rounding_large        = 14
rounding_small        = 8

# Arayüz fontu sans (Inter); kod/karakter gösterimi mono kalır.
font_family           = Inter
font_family_monospace = JetBrainsMono Nerd Font
h1_size               = 18
h2_size               = 15
h3_size               = 13
small_font_size       = 11

# İkon teması tema paketinden bağımsız; GTK ayarıyla aynı tutuluyor.
icon_theme            = Papirus-Catppuccin-Mocha
