#!/bin/sh
# Her temayı başsız bir dwl oturumunda sırayla uygular; dwl ya da bar çökerse, bir tema
# yarım yazılırsa ya da bar günlüğünde QML hatası çıkarsa başarısız olur.
#
#   tests/themes.sh            bütün temalar
#   tests/themes.sh kor nord   yalnız verilenler
#   DWL_BIN=/usr/local/bin/dwl tests/themes.sh   kurulu ikiliyi dene (varsayılan: depodaki dwl/dwl, yoksa kurulu olan)
#   KEEP=1 tests/themes.sh     günlükleri silme (yolu sonda yazar)
#
# Gerçek oturuma dokunmaz: ekran yok (WLR_BACKENDS=headless), durum dosyaları geçici dizinde
# (XDG_STATE_HOME), DWL_NESTED=1 (oturum servisleri, uygulama renkleri, giriş ekranı atlanır),
# DWL_THEME_NO_WALL=1 (hareketli duvara dokunulmaz). Statik duvar geçişi (WallFx) de çalışır:
# hareketli duvar geçici durumda kapatılır ve her temada "wall next" çağrılır.
#
# Göremediği: ekrandaki görüntü. "Çökmedi ve hata yazmadı" der, "doğru göründü" demez.
set -u

here=$(dirname "$(readlink -f "$0")")
root=$(dirname "$here")
theme="$root/bin/dwl-theme"

if [ -n "${DWL_BIN:-}" ]; then
	dwl=$DWL_BIN
elif [ -x "$root/dwl/dwl" ]; then
	dwl="$root/dwl/dwl"
else
	dwl=/usr/local/bin/dwl
fi
[ -x "$dwl" ] || { echo "dwl bulunamadı: $dwl (önce make)" >&2; exit 2; }
command -v quickshell >/dev/null || { echo "quickshell yok" >&2; exit 2; }

if [ $# -gt 0 ]; then
	ids=$*
else
	ids=$("$theme" list | awk '{print $1 == "*" ? $2 : $1}' | tr '\n' ' ')
fi

echo "== dwl-theme check"
# shellcheck disable=SC2086
"$theme" check $ids || { echo "tema dosyaları hatalı; oturum denemesi yapılmadı" >&2; exit 1; }

tmp=$(mktemp -d "${TMPDIR:-/tmp}/dwl-themes.XXXXXX")
dwlpid=""
cleanup() {
	[ -n "$dwlpid" ] && kill "$dwlpid" 2>/dev/null
	if [ -n "${KEEP:-}" ]; then
		echo "günlükler: $tmp"
	else
		rm -rf "$tmp"
	fi
}
trap cleanup EXIT
trap 'exit 130' INT TERM

# Gerçek oturumun durumu: test bittiğinde aynı kalmalı.
dwl_before=$(pgrep -x dwl | wc -l)
agent_before=$(pgrep -f polkit-kde-authentication-agent-1 | wc -l)

# dwl'nin içinde çalışan kısım. Sonucu satır satır $tmp/result'a yazar.
cat >"$tmp/inner.sh" <<EOF
#!/bin/sh
tmp='$tmp'; theme='$theme'
fail() { echo "FAIL \$*" >>"\$tmp/result"; }
dwlpid=\$(cat "\$tmp/dwl.pid")
# Bar'ı dwl'nin kendi autostart'ı açar (gerçek oturumdaki yol); çıktısı dwl.log'a düşer.
qs=""
for _ in 1 2 3 4 5 6 7 8 9 10; do
	for a in \$(pgrep -P "\$dwlpid"); do
		qs=\$(pgrep -P "\$a" -x quickshell) && break
	done
	[ -n "\$qs" ] && break
	sleep 0.5
done
[ -n "\$qs" ] || { fail "bar açılmadı"; echo done >"\$tmp/done"; exit 1; }
sleep 2
for t in $ids; do
	if ! "\$theme" apply "\$t" 2>>"\$tmp/theme.err"; then
		fail "\$t: apply başarısız"
		continue
	fi
	"\$theme" wall next 2>>"\$tmp/theme.err" || fail "\$t: wall next"
	sleep 1.5
	[ "\$(cat "\$tmp/state/dwl-theme/current")" = "\$t" ] || fail "\$t: current yazılmadı"
	grep -q '^focus=#' "\$tmp/state/dwl-theme/dwl.conf" || fail "\$t: dwl.conf eksik"
	grep -q "\"id\": \"\$t\"" "\$tmp/state/dwl-theme/theme.json" || fail "\$t: theme.json eksik"
	kill -0 "\$qs" 2>/dev/null || { fail "\$t: bar çöktü"; break; }
	kill -0 "\$(cat "\$tmp/dwl.pid")" 2>/dev/null || { fail "\$t: dwl çöktü"; break; }
	echo "ok \$t" >>"\$tmp/result"
done
echo done >"\$tmp/done"
EOF

# dwl-session'ın yaptığı gibi: bar açılmadan önce durum dosyaları yerinde olsun.
# Hareketli duvar geçici durumda kapalı, böylece bar statik duvarı (WallFx) çizer.
export XDG_STATE_HOME="$tmp/state" DWL_NESTED=1 DWL_THEME_NO_WALL=1 DWL_HOME="$root"
"$theme" init 2>>"$tmp/theme.err"
"$theme" wall off 2>>"$tmp/theme.err"

echo "== başsız oturum ($dwl)"
WLR_BACKENDS=headless WLR_LIBINPUT_NO_DEVICES=1 \
	"$dwl" -s "sh '$tmp/inner.sh'" >"$tmp/dwl.log" 2>&1 &
dwlpid=$!
echo "$dwlpid" >"$tmp/dwl.pid"

# Tema başına ~2 sn; bolca pay bırak, sonra vazgeç.
n=$(echo "$ids" | wc -w)
limit=$((n * 6 + 20))
i=0
while [ ! -e "$tmp/done" ] && [ "$i" -lt "$limit" ] && kill -0 "$dwlpid" 2>/dev/null; do
	sleep 1
	i=$((i + 1))
done

bad=0
if [ ! -e "$tmp/done" ]; then
	if kill -0 "$dwlpid" 2>/dev/null; then
		echo "FAIL zaman aşımı ($limit sn)"
	else
		echo "FAIL dwl erken kapandı"
		tail -5 "$tmp/dwl.log" | sed 's/^/     /'
	fi
	bad=1
fi
kill "$dwlpid" 2>/dev/null
wait "$dwlpid" 2>/dev/null
dwlpid=""

for t in $ids; do
	if grep -qx "ok $t" "$tmp/result" 2>/dev/null; then
		echo "  ok    $t"
	else
		echo "  FAIL  $t"
		bad=1
	fi
done
if grep '^FAIL' "$tmp/result" 2>/dev/null | sed 's/^FAIL/     neden:/'; then :; fi
grep -q '^FAIL' "$tmp/result" 2>/dev/null && bad=1

# Bar günlüğü: ERROR satırları ve QML'in uyarı olarak yazdığı gerçek hatalar.
# "path symlink" satırı sayılmaz: gerçek oturumun barı aynı dizinden çalışırken hep çıkar.
pat=' ERROR|TypeError|ReferenceError|SyntaxError|is not defined|is not a type|Unable to assign|Cannot assign|Cannot read property|Failed to load|failed to load|okunamadı|Segmentation|core dumped'
if grep -hE "$pat" "$tmp/dwl.log" 2>/dev/null | grep -v 'Could not create path symlink' | sed 's/\x1b\[[0-9;]*m//g' | sort | uniq -c | sed 's/^/     /' | grep .; then
	echo "FAIL günlükte hata var (yukarıda)"
	bad=1
fi
if [ -s "$tmp/theme.err" ]; then
	echo "     dwl-theme stderr:"
	sed 's/^/     /' "$tmp/theme.err" | head -20
	bad=1
fi

# Gerçek oturum yerinde mi? (İç içe denemeler geçmişte polkit ajanını düşürdü.)
dwl_after=$(pgrep -x dwl | wc -l)
agent_after=$(pgrep -f polkit-kde-authentication-agent-1 | wc -l)
if [ "$dwl_after" != "$dwl_before" ]; then
	echo "UYARI: dwl süreç sayısı değişti ($dwl_before -> $dwl_after); sahipsiz deneme oturumu kalmış olabilir"
	bad=1
fi
if [ "$agent_after" -lt "$agent_before" ]; then
	echo "UYARI: polkit ajanı düştü; geri getir: setsid -f /usr/lib/polkit-kde-authentication-agent-1"
	bad=1
fi

echo
if [ "$bad" = 0 ]; then
	echo "$n tema: hepsi geçti"
else
	echo "BAŞARISIZ"
	[ -n "${KEEP:-}" ] || echo "(günlükleri saklamak için KEEP=1 ile yeniden çalıştır)"
fi
exit "$bad"
