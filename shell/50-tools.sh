# Fedora Geçiş — CLI araç entegrasyonu (starship, zoxide, fzf, eza, bat)
# Bu dosyayı silmek tüm entegrasyonu geri alır. Yalnızca interaktif kabuğu etkiler.

# starship — prompt
command -v starship >/dev/null && eval "$(starship init bash)"

# zoxide — akıllı dizin atlama ('z <parça>' ile git, 'zi' ile interaktif seçim)
command -v zoxide >/dev/null && eval "$(zoxide init bash)"

# fzf — anahtar kısayolları + tamamlama (Ctrl-R geçmiş, Ctrl-T dosya, Alt-C dizin)
command -v fzf >/dev/null && eval "$(fzf --bash)"

# eza — modern ls
if command -v eza >/dev/null; then
  alias ls='eza --group-directories-first --icons=auto'
  alias ll='eza -lah --group-directories-first --icons=auto --git'
  alias la='eza -a --group-directories-first --icons=auto'
  alias lt='eza --tree --level=2 --icons=auto'
fi

# bat — renkli cat ve man sayfaları
# (bat çıktı bir terminale gitmediğinde otomatik olarak düz cat gibi davranır, pipe güvenli)
if command -v bat >/dev/null; then
  alias cat='bat --paging=never --style=plain'
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi
