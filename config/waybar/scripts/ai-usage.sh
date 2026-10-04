#!/bin/bash
# Waybar modülü: CodexBar üzerinden Claude kullanım yüzdeleri.
# Çıktı: {"text","tooltip","class"} — yüzdeler "kullanılan" orandır.
set -o pipefail

OUT=$(timeout 50 "$HOME/.local/bin/codexbar" usage --provider claude --json 2>/dev/null)
if [ -z "$OUT" ]; then
  echo '{"text":"󰧑 —","tooltip":"codexbar yanıt vermedi","class":"err"}'
  exit 0
fi

CODEXBAR_JSON="$OUT" python3 - <<'PY' || echo '{"text":"󰧑 —","tooltip":"codexbar çıktısı çözümlenemedi","class":"err"}'
import json, os, sys

def pct(block):
    if not block:
        return None
    value = block.get("usedPercent")
    return None if value is None else round(value)

def fmt(value):
    return "—" if value is None else f"{value}%"

claude_session = claude_week = None
tooltip = []
for entry in json.loads(os.environ["CODEXBAR_JSON"]):
    usage = entry.get("usage") or {}
    provider = entry.get("provider")
    if provider == "claude":
        claude_session = pct(usage.get("primary"))
        claude_week = pct(usage.get("secondary"))
        for label, block in (("session", usage.get("primary")), ("hafta", usage.get("secondary"))):
            if block:
                reset = block.get("resetDescription", "")
                tooltip.append(f"Claude {label}: %{pct(block)} kullanıldı · {reset}")

worst = max((v for v in (claude_session, claude_week) if v is not None), default=0)
css = "crit" if worst >= 95 else "warn" if worst >= 80 else "ok"

text = f"󰧑 {fmt(claude_session)}·{fmt(claude_week)}"
tooltip.append("󰧑 Claude session·hafta — tıkla: yenile")
print(json.dumps({"text": text, "tooltip": "\n".join(tooltip), "class": css}))
PY
