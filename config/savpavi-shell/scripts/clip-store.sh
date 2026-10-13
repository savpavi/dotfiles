#!/bin/sh
# Called by `wl-paste --watch` for every clipboard change; content arrives on stdin.
# Secrets marked by password managers (KDE hint, used by 1Password/KeePassXC) are not kept.
if wl-paste --list-types 2>/dev/null | grep -q 'x-kde-passwordManagerHint'; then
  cat >/dev/null
  exit 0
fi
exec cliphist store
