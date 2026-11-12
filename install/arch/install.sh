#!/usr/bin/env bash
# Post-install bootstrap for a fresh Arch Linux (after archinstall, logged in as the normal user).
# Every stage is idempotent, so the script can be re-run after a failure.
#
#   install.sh                 run the default stages in order
#   install.sh pkgs aur        run only the named stages
#   install.sh --dry-run ...   print what would run, change nothing
#   install.sh --list          list stages
#
# Default stages: preflight pkgs aur flatpak link migrate shell services tools check
# Opt-in stages:  disks (fstab entries for /srv), home (restore ~ from the Lexar backup)
#
# Not covered here: VFIO passthrough, Looking Glass, DankMaterialShell + dsearch, Hopper, the Craft apps.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOT="$(cd "$HERE/../.." && pwd)"
BACKUP="${BACKUP:-/srv/lexar/Fedora-to-arch-backup}"
LOG="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-install-$(date +%Y%m%d-%H%M%S).log"
DEFAULT_STAGES=(preflight pkgs aur flatpak link migrate shell services tools check)
ALL_STAGES=(preflight disks home pkgs aur flatpak link migrate shell services tools check)
DRY=0
FAILED=()

say()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m !! %s\033[0m\n' "$*"; }
run()  { if (( DRY )); then printf '  [dry] %s\n' "$*"; else "$@"; fi; }
have() { command -v "$1" >/dev/null 2>&1; }
# Read a package list: strip comments, split on whitespace.
list() { sed 's/#.*//' "$1" | tr -s ' \t' '\n' | grep -v '^$'; }

stage_preflight() {
  [[ $EUID -ne 0 ]] || { warn "run as the normal user, not root"; return 1; }
  [[ -r /etc/arch-release ]] || { warn "this is not Arch Linux"; return 1; }
  have sudo || { warn "sudo is missing"; return 1; }
  run sudo -v || return 1
  # multilib is needed for lib32-mesa / lib32-vulkan-radeon / wine
  if ! grep -qE '^\[multilib\]' /etc/pacman.conf; then
    say "enabling multilib"
    run sudo cp /etc/pacman.conf "/etc/pacman.conf.bak-$(date +%Y%m%d)"
    if grep -qE '^#\[multilib\]' /etc/pacman.conf; then
      run sudo sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
    elif (( ! DRY )); then
      printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' | sudo tee -a /etc/pacman.conf >/dev/null
    fi
  fi
  run sudo sed -i 's/^#Color/Color/; s/^#ParallelDownloads.*/ParallelDownloads = 8/' /etc/pacman.conf
  run sudo pacman -Syu --noconfirm
}

stage_disks() {
  # Append the /srv entries from the saved fstab (UUID based, all nofail). mergerfs comes from the AUR stage.
  local src="$BACKUP/sysinfo/fstab"
  if [[ ! -r $src ]]; then
    # Lexar itself is not mounted yet: mount it by label so the backup becomes readable.
    run sudo mkdir -p /srv/lexar
    run sudo mount -o noatime LABEL=lexar /srv/lexar || { warn "cannot mount LABEL=lexar"; return 1; }
  fi
  [[ -r $src ]] || { (( DRY )) && return 0; warn "$src not found"; return 1; }
  run sudo cp /etc/fstab "/etc/fstab.bak-$(date +%Y%m%d-%H%M%S)"
  local line mp
  while IFS= read -r line; do
    mp=$(awk '{print $2}' <<<"$line")
    if grep -qE "[[:space:]]${mp}[[:space:]]" /etc/fstab; then echo "= $mp already in fstab"; continue; fi
    echo "+ $mp"
    run sudo mkdir -p "$mp"
    (( DRY )) || printf '%s\n' "$line" | sudo tee -a /etc/fstab >/dev/null
  done < <(grep -E '^[^#].*[[:space:]]/srv/' "$src")
  run sudo systemctl daemon-reload
  # ext4 disks now; the mergerfs pool mounts after the aur stage (or at next boot)
  run sudo mount -a -t ext4 || warn "some /srv mounts failed (see above)"
}

stage_home() {
  # Restore ~ from the backup. Never deletes; existing files are overwritten only if the backup copy is newer.
  local src="$BACKUP/home/"
  [[ -d $src ]] || { warn "$src not found (run the disks stage first)"; return 1; }
  [[ $(id -u) -eq 1000 ]] || warn "uid is $(id -u), the backup was made as uid 1000; ownership will differ"
  say "restoring home from $src (about 270 GB)"
  run rsync -aHAX --update --info=progress2,stats1 "$src" "$HOME/"
}

stage_pkgs() {
  mapfile -t pkgs < <(list "$HERE/pacman.txt")
  say "pacman: ${#pkgs[@]} packages"
  if ! run sudo pacman -S --needed --noconfirm "${pkgs[@]}"; then
    # One bad name aborts the whole transaction; retry one by one to isolate it.
    warn "batch install failed, retrying package by package"
    local p bad=()
    for p in "${pkgs[@]}"; do sudo pacman -S --needed --noconfirm "$p" >/dev/null 2>&1 || bad+=("$p"); done
    (( ${#bad[@]} )) && { warn "could not install: ${bad[*]}"; return 1; }
  fi
}

stage_aur() {
  if ! have paru; then
    say "building paru"
    local tmp; tmp=$(mktemp -d)
    run git clone --depth 1 https://aur.archlinux.org/paru-bin.git "$tmp/paru-bin" || return 1
    (( DRY )) || ( cd "$tmp/paru-bin" && makepkg -si --noconfirm ) || return 1
  fi
  mapfile -t pkgs < <(list "$HERE/aur.txt")
  say "AUR: ${#pkgs[@]} packages"
  local p bad=()
  # One at a time: a single broken PKGBUILD must not block the rest.
  for p in "${pkgs[@]}"; do
    if pacman -Qq "$p" >/dev/null 2>&1; then echo "= $p"; continue; fi
    run paru -S --needed --noconfirm --skipreview "$p" || bad+=("$p")
  done
  (( ${#bad[@]} )) && { warn "AUR failures: ${bad[*]}"; return 1; }
  return 0
}

stage_flatpak() {
  have flatpak || { warn "flatpak is missing (pkgs stage)"; return 1; }
  run flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  mapfile -t apps < <(list "$HERE/flatpak.txt")
  say "Flatpak: ${#apps[@]} apps"
  local a bad=()
  for a in "${apps[@]}"; do
    run flatpak install --user --noninteractive --or-update flathub "$a" || bad+=("$a")
  done
  (( ${#bad[@]} )) && { warn "Flatpak failures: ${bad[*]}"; return 1; }
  return 0
}

stage_link() {
  run "$DOT/bin/dot-link"
  # User units kept in the repo; copied only when missing so a restored home wins.
  local u dst="$HOME/.config/systemd/user"
  run mkdir -p "$dst"
  for u in "$DOT"/extras/systemd/*; do
    [[ -e "$dst/$(basename "$u")" ]] || run cp "$u" "$dst/"
  done
  [[ -e $HOME/.config/mimeapps.list ]] || run cp "$DOT/extras/mimeapps/desktop-apps.list" "$HOME/.config/mimeapps.list"
  run systemctl --user daemon-reload
}

stage_migrate() {
  # Apps that were Flatpaks on Fedora and are native here: carry their data over and fix what points at the Flatpak.
  local var="$HOME/.var/app" src dst pair
  for pair in \
    "org.telegram.desktop/data/TelegramDesktop|$HOME/.local/share/TelegramDesktop" \
    "com.obsproject.Studio/config/obs-studio|$HOME/.config/obs-studio" \
    "md.obsidian.Obsidian/config/obsidian|$HOME/.config/obsidian"; do
    src="$var/${pair%%|*}"; dst="${pair##*|}"
    [[ -d $src ]] || { echo "- no Flatpak data at $src"; continue; }
    if [[ -e $dst.from-flatpak ]]; then echo "= $dst already migrated"; continue; fi
    # Anything already at the native path predates the Flatpak era; keep it aside rather than merge.
    [[ -e $dst ]] && run mv "$dst" "$dst.bak-pre-arch"
    run mkdir -p "$(dirname "$dst")"
    run cp -a "$src" "$dst" && run touch "$dst.from-flatpak"
    echo "+ $dst"
  done

  # Launcher keybinds in the Hyprland config (this edits the repo file; commit it afterwards).
  local hypr="$DOT/config/hypr/hyprland.lua" id bin
  for pair in "com.spotify.Client|spotify-launcher" "org.telegram.desktop|Telegram" \
              "com.discordapp.Discord|discord" "md.obsidian.Obsidian|obsidian"; do
    id="${pair%%|*}"; bin="${pair##*|}"
    grep -q "flatpak run $id" "$hypr" 2>/dev/null || continue
    if have "$bin" || (( DRY )); then
      run sed -i "s|flatpak run $id|$bin|" "$hypr"; echo "+ keybind: $id -> $bin"
    else
      warn "$bin not installed; keybind for $id left on the Flatpak"
    fi
  done

  # Default-app entries that name a Flatpak desktop file with a different native id.
  local mime="$HOME/.config/mimeapps.list"
  if [[ -f $mime ]]; then
    run sed -i 's|com\.discordapp\.Discord\.desktop|discord.desktop|g; s|org\.audacityteam\.Audacity\.desktop|audacity.desktop|g' "$mime"
  fi
  echo "Steam: sign in, then add the library folder /srv/lexar/SteamLibrary (Settings > Storage)."
  echo "Discord and Spotify: sign in again."
}

stage_shell() {
  local zsh; zsh=$(command -v zsh) || { warn "zsh is missing"; return 1; }
  [[ $(getent passwd "$USER" | cut -d: -f7) == "$zsh" ]] || run sudo chsh -s "$zsh" "$USER"
  # Fedora and Arch ship the zsh plugins under different paths.
  if [[ -f $HOME/.zshrc ]] && grep -q '/usr/share/zsh-\(autosuggestions\|syntax-highlighting\)/' "$HOME/.zshrc"; then
    run cp "$HOME/.zshrc" "$HOME/.zshrc.bak-fedora"
    run sed -i 's|/usr/share/zsh-autosuggestions/|/usr/share/zsh/plugins/zsh-autosuggestions/|g; s|/usr/share/zsh-syntax-highlighting/|/usr/share/zsh/plugins/zsh-syntax-highlighting/|g' "$HOME/.zshrc"
  fi
  # gnome-ssh-askpass lives elsewhere on Arch; ksshaskpass is installed instead.
  local env="$DOT/config/environment.d/70-askpass.conf"
  if grep -q '/usr/libexec/openssh/gnome-ssh-askpass' "$env" 2>/dev/null; then
    warn "$env points at the Fedora askpass path; change SSH_ASKPASS to /usr/bin/ksshaskpass"
  fi
}

stage_services() {
  local u
  for u in NetworkManager bluetooth sddm tailscaled firewalld sshd power-profiles-daemon smartd \
           cups.socket libvirtd.socket fstrim.timer plocate-updatedb.timer \
           snapper-timeline.timer snapper-cleanup.timer; do
    run sudo systemctl enable "$u" || warn "could not enable $u"
  done
  # libvirt/kvm for the VM, input for ydotool
  local g
  for g in libvirt kvm input; do
    getent group "$g" >/dev/null && run sudo usermod -aG "$g" "$USER"
  done
  for u in pipewire.socket pipewire-pulse.socket wireplumber.service \
           gnome-keyring-daemon.socket savpavi-shell.service savpavi-clipboard.service \
           syncthing.service espanso.service localsend.service ydotool.service \
           rclone-gdrive.service dot-drive-watch.service dot-drive-sync.timer; do
    if systemctl --user cat "$u" >/dev/null 2>&1; then
      run systemctl --user enable "$u" || warn "could not enable user unit $u"
    else
      echo "- user unit $u not present, skipped"
    fi
  done
}

stage_tools() {
  have uv || { warn "uv is missing"; return 1; }
  # A restored home already carries these; install only what is absent.
  have yt-dlp     || run uv tool install 'yt-dlp[default]'
  have gallery-dl || run uv tool install gallery-dl
  run xdg-user-dirs-update
}

stage_check() {
  say "summary"
  local missing=() p
  while read -r p; do pacman -Qq "$p" >/dev/null 2>&1 || missing+=("$p"); done \
    < <(list "$HERE/pacman.txt"; list "$HERE/aur.txt")
  (( ${#missing[@]} )) && warn "packages not installed: ${missing[*]}" || echo "all listed packages installed"
  for p in qs hyprctl uwsm fuzzel cliphist matugen dot-shell dot-shell-theme; do
    have "$p" || PATH="$DOT/bin:$PATH" have "$p" || warn "command missing: $p"
  done
  mountpoint -q /srv/lexar   || warn "/srv/lexar not mounted (disks stage)"
  mountpoint -q /srv/storage || warn "/srv/storage (mergerfs pool) not mounted"
  echo "manual follow-ups: VFIO + Looking Glass, tailscale up, 1Password sign-in, DMS/dsearch, Hopper, Craft apps"
  (( ${#missing[@]} == 0 ))
}

main() {
  local stages=() a
  for a in "$@"; do
    case "$a" in
      --dry-run|-n) DRY=1 ;;
      --list) printf '%s\n' "${ALL_STAGES[@]}"; exit 0 ;;
      -h|--help) sed -n '2,13p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
      *) if declare -F "stage_$a" >/dev/null; then stages+=("$a"); else echo "unknown stage: $a" >&2; exit 1; fi ;;
    esac
  done
  (( ${#stages[@]} )) || stages=("${DEFAULT_STAGES[@]}")
  mkdir -p "$(dirname "$LOG")"
  exec > >(tee -a "$LOG") 2>&1
  echo "log: $LOG"
  local s
  for s in "${stages[@]}"; do
    say "stage: $s"
    "stage_$s" || { FAILED+=("$s"); warn "stage $s reported problems"; [[ $s == preflight ]] && break; }
  done
  if (( ${#FAILED[@]} )); then warn "stages with problems: ${FAILED[*]} (re-run them after fixing)"; exit 1; fi
  say "done. Log out and pick the Hyprland (uwsm) session in SDDM."
}

main "$@"
