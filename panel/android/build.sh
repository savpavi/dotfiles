#!/bin/sh
# Build the panel APK without Gradle: aapt2 + javac + d8 + apksigner.
#
#   panel/android/build.sh            -> panel/android/build/dot-panel.apk
#
# Needs a JDK (javac, keytool) and from the Android SDK only build-tools and one
# platform's android.jar:
#   ANDROID_HOME   default ~/Android/Sdk
#   BUILD_TOOLS    default: newest under $ANDROID_HOME/build-tools
#   PLATFORM       default: newest android.jar under $ANDROID_HOME/platforms
# The signing key is made on first run and kept outside the repo:
#   DOT_PANEL_KEYSTORE  default ~/.local/share/dot-panel/panel.keystore
#   DOT_PANEL_KS_PASS   its password (default "dotpanel": the key only signs a sideloaded app)
set -eu

here=$(cd "$(dirname "$0")" && pwd)
sdk=${ANDROID_HOME:-$HOME/Android/Sdk}
bt=${BUILD_TOOLS:-$(ls -d "$sdk"/build-tools/* 2>/dev/null | sort -V | tail -n 1)}
jar=${PLATFORM:-$(ls "$sdk"/platforms/*/android.jar 2>/dev/null | sort -V | tail -n 1)}
ks=${DOT_PANEL_KEYSTORE:-${XDG_DATA_HOME:-$HOME/.local/share}/dot-panel/panel.keystore}
pass=${DOT_PANEL_KS_PASS:-dotpanel}
out=$here/build

[ -x "$bt/aapt2" ] || { echo "build-tools not found under $sdk/build-tools" >&2; exit 1; }
[ -f "$jar" ] || { echo "android.jar not found under $sdk/platforms" >&2; exit 1; }
command -v javac >/dev/null || { echo "javac not found" >&2; exit 1; }

rm -rf "$out"
mkdir -p "$out/res" "$out/classes" "$out/dex" "$out/gen"

echo "aapt2 ($(basename "$bt"), $(basename "$(dirname "$jar")"))"
"$bt/aapt2" compile --dir "$here/res" -o "$out/res/res.zip"
"$bt/aapt2" link -o "$out/unsigned.apk" -I "$jar" --manifest "$here/AndroidManifest.xml" \
    --java "$out/gen" "$out/res/res.zip"

echo "javac"
find "$here/src" "$out/gen" -name '*.java' > "$out/sources.txt"
javac --release 17 -Xlint:-options -classpath "$jar" -d "$out/classes" @"$out/sources.txt"

echo "d8"
find "$out/classes" -name '*.class' > "$out/classes.txt"
"$bt/d8" --release --min-api 26 --lib "$jar" --output "$out/dex" @"$out/classes.txt"

(cd "$out/dex" && zip -q -j "$out/unsigned.apk" classes.dex)
"$bt/zipalign" -f -p 4 "$out/unsigned.apk" "$out/aligned.apk"

if [ ! -f "$ks" ]; then
    echo "keytool: new signing key at $ks"
    mkdir -p "$(dirname "$ks")"
    keytool -genkeypair -keystore "$ks" -storepass "$pass" -keypass "$pass" -alias panel \
        -keyalg RSA -keysize 3072 -validity 10000 -dname "CN=dot-panel" >/dev/null 2>&1
    chmod 600 "$ks"
fi
"$bt/apksigner" sign --ks "$ks" --ks-pass "pass:$pass" --key-pass "pass:$pass" \
    --out "$out/dot-panel.apk" "$out/aligned.apk"
"$bt/apksigner" verify "$out/dot-panel.apk"
echo "$out/dot-panel.apk ($(du -h "$out/dot-panel.apk" | cut -f1))"
