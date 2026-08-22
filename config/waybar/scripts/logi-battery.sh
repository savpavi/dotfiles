#!/bin/bash
# Logitech (HID++) cihaz bataryalari — waybar custom/logi modulu.
# UPower'daki hidpp_battery_* cihazlarini okur; cihaz kapaliyken modul gizlenir.

text=() tooltip=() min=100

for dev in $(upower --enumerate 2>/dev/null | grep -i hidpp); do
    info=$(upower -i "$dev")
    model=$(sed -n 's/^[[:space:]]*model:[[:space:]]*//p' <<<"$info")
    pct=$(sed -n 's/^[[:space:]]*percentage:[[:space:]]*\([0-9]*\)%.*/\1/p' <<<"$info")
    state=$(sed -n 's/^[[:space:]]*state:[[:space:]]*//p' <<<"$info")
    [[ -z "$pct" ]] && continue

    icon="󰍽" # varsayilan: mouse
    case "${model,,}" in
        *keyboard*) icon="󰌌" ;;
        *headset* | *"pro x"*) icon="󰋋" ;;
    esac
    [[ "$state" == "charging" ]] && icon="󰚥"

    text+=("$icon ${pct}%")
    tooltip+=("$model: ${pct}% ($state)")
    ((pct < min)) && min=$pct
done

# G733 gibi kendi dongle'iyla baglanan kulakliklar UPower'a dusmez —
# headsetcontrol kuruluysa oradan oku (kulaklik kapaliyken sessizce atlanir).
if command -v headsetcontrol >/dev/null; then
    hs=$(timeout 5 headsetcontrol -o json 2>/dev/null |
        jq -r '.devices[]? | select(.battery.status != "BATTERY_UNAVAILABLE") |
               "\(.vendor // "") \(.product // .device)\t\(.battery.level)\t\(.battery.status)"')
    while IFS=$'\t' read -r model pct state; do
        [[ -z "$pct" || "$pct" == "null" ]] && continue
        icon="󰋋"
        case "$state" in
            BATTERY_CHARGING) icon="󰚥" state="charging" ;;
            BATTERY_AVAILABLE) state="discharging" ;;
        esac
        text+=("$icon ${pct}%")
        tooltip+=("$model: ${pct}% ($state)")
        ((pct < min)) && min=$pct
    done <<<"$hs"
fi

if [[ ${#text[@]} -eq 0 ]]; then
    echo '{"text": ""}'
    exit 0
fi

class=""
((min < 30)) && class="warn"
((min < 15)) && class="crit"

tip="${tooltip[0]}"
for ((i = 1; i < ${#tooltip[@]}; i++)); do tip+="\\n${tooltip[$i]}"; done

printf '{"text": "%s", "tooltip": "%s", "class": "%s"}\n' \
    "${text[*]}" "$tip" "$class"
