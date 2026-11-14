#!/bin/sh
# dwl oturumunu ayağa kaldırır (Arch): derler, sisteme kurar, giriş ekranını ve kullanıcı
# tarafını bağlar. Tekrar çalıştırmak zararsızdır. Sistem geneli için: install/arch/install.sh
#
#   install/dwl.sh            her adımı sırayla yap (sudo gereken yerde parola sorar)
#   install/dwl.sh --dry-run  ne yapacağını yalnız yazdır
#   install/dwl.sh ADIM...    yalnız verilen adımlar: paketler derle kur giris kullanici denetle guvenlik
#
# Depo nerede durursa dursun çalışır: ikiliye yol gömülmez, /usr/local/bin/dwl-session
# bu depodaki bin/dwl-session'a bağlantıdır ve DWL_HOME'u oradan çözer.
set -eu

root=$(dirname "$(dirname "$(readlink -f "$0")")")
dry=0
[ "${1:-}" = "--dry-run" ] && { dry=1; shift; }
steps=${*:-paketler derle kur giris kullanici denetle guvenlik}

run() {
	if [ "$dry" = 1 ]; then
		echo "  + $*"
	else
		"$@"
	fi
}
say() { printf '\n== %s\n' "$*"; }

# Resmî depodaki paketler. brave-origin-bin AUR'da; burada kurulmaz.
PKGS="wlroots0.20 scenefx wayland-protocols xorg-xwayland xorg-xrandr
quickshell alacritty fuzzel dunst libnotify
grim slurp satty wl-clipboard cliphist wtype wlopm
xdg-desktop-portal-wlr xdg-desktop-portal-gtk polkit-kde-agent
qt6ct playerctl jq networkmanager
solaar kdeconnect dolphin
ttf-jetbrains-mono-nerd inter-font"

for step in $steps; do
	case "$step" in
	paketler)
		say "Paketler"
		# shellcheck disable=SC2086
		run sudo pacman -S --needed $PKGS
		;;
	derle)
		say "Derleme (dwl + bar IPC istemcisi)"
		run make -C "$root/dwl"
		run make -C "$root/bar/ipc"
		;;
	kur)
		say "dwl'yi sisteme kur (/usr/local/bin/dwl, dwl-session bağlantısı, oturum dosyası)"
		run sudo make -C "$root/dwl" install
		run sudo ln -sfn "$root/bin/dwl-session" /usr/local/bin/dwl-session
		;;
	giris)
		say "SDDM giriş ekranı teması ve yenileme hızı"
		run sudo "$root/sddm/install.sh"
		;;
	kullanici)
		say "Kullanıcı tarafı: komut bağlantıları, portal ayarı, ilk tema"
		run mkdir -p "$HOME/.local/bin" "$HOME/.config/xdg-desktop-portal" "$HOME/.config/xdg-desktop-portal-wlr"
		for b in dwl-theme dwl-keys dwl-shot dwl-clip dwl-grab; do
			run ln -sfn "$root/bin/$b" "$HOME/.local/bin/$b"
		done
		run cp "$root/portal/dwl-portals.conf" "$HOME/.config/xdg-desktop-portal/dwl-portals.conf"
		if [ -e "$HOME/.config/xdg-desktop-portal-wlr/config" ]; then
			echo "  xdg-desktop-portal-wlr/config zaten var, dokunulmadı"
		else
			run cp "$root/portal/xdg-desktop-portal-wlr.config" "$HOME/.config/xdg-desktop-portal-wlr/config"
		fi
		run "$root/bin/dwl-theme" init
		;;
	denetle)
		say "Denetim: tema dosyaları ve barın çağırdığı araçlar"
		run "$root/bin/dwl-theme" check
		missing=0
		for c in quickshell fuzzel dunst grim slurp satty cliphist wtype wl-paste alacritty; do
			command -v "$c" >/dev/null 2>&1 || { echo "  EKSİK komut: $c"; missing=$((missing + 1)); }
		done
		# Elle kurulanlar: yoksa ilgili özellik sessizce çalışmaz.
		command -v yt-dlp >/dev/null 2>&1 || echo "  yok: yt-dlp (Super+Shift+D indirme; uv tool install 'yt-dlp[default]')"
		command -v rclone >/dev/null 2>&1 || echo "  yok: rclone (bar: Drive düğmesi)"
		[ -x "$HOME/.local/bin/waywallen-layer-shell" ] || echo "  yok: waywallen-layer-shell (hareketli duvar)"
		[ "$missing" = 0 ] || echo "  $missing komut eksik: install/dwl.sh paketler"
		;;
	guvenlik)
		say "Güvenlik duvarı: KDE Connect ve LocalSend (yalnız yerel ağ)"
		if systemctl is-active --quiet firewalld 2>/dev/null; then
			run sudo firewall-cmd --permanent --add-service=kdeconnect
			run sudo firewall-cmd --permanent --add-port=53317/tcp --add-port=53317/udp
			run sudo firewall-cmd --reload
		else
			echo "  firewalld çalışmıyor, atlandı"
		fi
		;;
	*)
		echo "Bilinmeyen adım: $step" >&2
		exit 2
		;;
	esac
done

say "Bitti"
echo "Çıkış yapıp SDDM'de oturum olarak \"dwl\" seç."
echo "Elle kurulanlar: brave-origin-bin (AUR), waywallen (Flatpak, hareketli duvar)."
echo "Her temayı denemek için: tests/themes.sh"
