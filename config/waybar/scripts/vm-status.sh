#!/usr/bin/env bash
# Waybar custom/vm — EGE-Windows11 VM durumu.
state="$(virsh --readonly --connect qemu:///system domstate EGE-Windows11 2>/dev/null || echo unknown)"
case "$state" in
  running)    printf '{"text":"󰖳","class":"vm-running","tooltip":"Windows VM: çalışıyor — tıkla, Looking Glass açılsın"}\n' ;;
  paused)     printf '{"text":"󰖳","class":"vm-paused","tooltip":"Windows VM: duraklatıldı"}\n' ;;
  "shut off") printf '{"text":"󰖳","class":"vm-off","tooltip":"Windows VM: kapalı — tıkla, başlat"}\n' ;;
  *)          printf '{"text":"󰖳","class":"vm-unknown","tooltip":"Windows VM: durum okunamadı"}\n' ;;
esac
