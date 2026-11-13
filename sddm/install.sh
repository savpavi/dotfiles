#!/bin/sh
# dwl giriş ekranı temasını SDDM'e kurar. root ile çalıştır:  sudo sddm/install.sh
# Geri almak için:  sudo sddm/install.sh remove
set -eu

src=$(dirname "$(readlink -f "$0")")/dwl
dst=/usr/share/sddm/themes/dwl
conf=/etc/sddm.conf.d/10-dwl-theme.conf
owner=${SUDO_USER:-savpavi}

if [ "$(id -u)" -ne 0 ]; then
	echo "root gerekli: sudo $0" >&2
	exit 1
fi

if [ "${1:-}" = remove ]; then
	rm -f "$conf"
	rm -rf "$dst"
	echo "Kaldırıldı; SDDM bir sonraki açılışta varsayılan temasına döner."
	exit 0
fi

install -d "$dst"
install -m 644 "$src/Main.qml" "$src/metadata.desktop" "$src/theme.conf" "$dst/"

# dwl-theme her tema değişiminde bu dosyayı yazar; o yüzden kullanıcıya ait.
[ -e "$dst/theme.conf.user" ] || cp "$src/theme.conf" "$dst/theme.conf.user"
chown "$owner" "$dst/theme.conf.user"
chmod 644 "$dst/theme.conf.user"

install -d /etc/sddm.conf.d
printf '[Theme]\nCurrent=dwl\n' > "$conf"

echo "Kuruldu: $dst"
echo "Ayar:    $conf"
echo "Bir sonraki çıkışta giriş ekranı yeni temayla gelir."
