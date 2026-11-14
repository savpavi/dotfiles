#!/bin/sh
# Bu dwl kurulumunu sıfırdan ayağa kaldırır (Arch). Tekrar çalıştırmak zararsızdır.
#
#   ./install.sh            her adımı sırayla yap (sudo gereken yerde parola sorar)
#   ./install.sh --dry-run  ne yapacağını yalnız yazdır
#   ./install.sh ADIM...    yalnız verilen adımlar: paketler derle kur giris kullanici dotfiles guvenlik
#
# Depo /home/savpavi/Projects/dwl altında durmalı: config.h ve dwl.desktop bu yolu kullanır.
set -eu

here=$(dirname "$(readlink -f "$0")")
want=/home/savpavi/Projects/dwl
dry=0
[ "${1:-}" = "--dry-run" ] && { dry=1; shift; }
steps=${*:-paketler derle kur giris kullanici dotfiles guvenlik}

run() {
	if [ "$dry" = 1 ]; then
		echo "  + $*"
	else
		"$@"
	fi
}
say() { printf '\n== %s\n' "$*"; }

if [ "$here" != "$want" ]; then
	echo "Uyarı: depo $here altında; config.h ve dwl.desktop $want yolunu bekliyor." >&2
	echo "Ya depoyu oraya taşı ya da bu iki dosyadaki yolları değiştir." >&2
	[ "$dry" = 1 ] || exit 1
fi

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
		run make -C "$here"
		run make -C "$here/bar/ipc"
		;;
	kur)
		say "dwl'yi sisteme kur (/usr/local/bin/dwl, oturum dosyası)"
		run sudo make -C "$here" install
		;;
	giris)
		say "SDDM giriş ekranı teması ve yenileme hızı"
		run sudo "$here/sddm/install.sh"
		;;
	kullanici)
		say "Kullanıcı tarafı: komut bağlantıları, portal ayarı, ilk tema"
		run mkdir -p "$HOME/.local/bin" "$HOME/.config/xdg-desktop-portal" "$HOME/.config/xdg-desktop-portal-wlr"
		for b in dwl-theme dwl-keys dwl-shot dwl-clip dwl-grab; do
			run ln -sfn "$here/bin/$b" "$HOME/.local/bin/$b"
		done
		run cp "$here/portal/dwl-portals.conf" "$HOME/.config/xdg-desktop-portal/dwl-portals.conf"
		if [ -e "$HOME/.config/xdg-desktop-portal-wlr/config" ]; then
			echo "  xdg-desktop-portal-wlr/config zaten var, dokunulmadı"
		else
			run cp "$here/portal/xdg-desktop-portal-wlr.config" "$HOME/.config/xdg-desktop-portal-wlr/config"
		fi
		run "$here/bin/dwl-theme" init
		;;
	dotfiles)
		say "dotfiles bağımlılıkları (~/dotfiles; yalnız denetler, bir şey kurmaz)"
		# Bar ve kısayollar bu dosyaları doğrudan çağırır; duvar geçişinin QML'i ve shader'ı
		# depoda ~/dotfiles'a bağlantıdır (bar/WallFx.qml, bar/shaders). Eksik olan özellik
		# sessizce çalışmaz, o yüzden burada adını söyle.
		dot="$HOME/dotfiles"
		missing=0
		need() {
			if [ -e "$1" ]; then
				echo "  var    $1"
			else
				echo "  EKSİK  $1  ($2)"
				missing=$((missing + 1))
			fi
		}
		need "$dot/bin/dot-grab" "Super+Shift+D indirme"
		need "$dot/bin/dot-wallfx" "statik duvar geçişi"
		need "$dot/bin/dot-drive" "bar: Drive düğmesi"
		need "$dot/bin/dot-send" "bar: telefon düğmesi"
		need "$dot/config/savpavi-shell/scripts/claude-usage.sh" "bar: Claude limiti"
		need "$dot/templates/apps/vesktop.css" "Vesktop teması"
		need "$here/bar/WallFx.qml" "bağlantı kopuk: statik duvar çizilmez"
		need "$here/bar/shaders/wallfx.frag.qsb" "bağlantı kopuk: statik duvar çizilmez"
		if [ "$missing" -gt 0 ]; then
			echo "  $missing eksik. Depoyu kur: git clone https://github.com/savpavi/dotfiles ~/dotfiles"
		fi
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
echo "Elle kurulanlar: brave-origin-bin (AUR), waywallen (Flatpak, hareketli duvar),"
echo "~/dotfiles deposu (eksikleri görmek için: ./install.sh dotfiles)."
