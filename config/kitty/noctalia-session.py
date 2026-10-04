#!/usr/bin/env python3
import os
from pathlib import Path
if "Hyprland" in os.environ.get("XDG_CURRENT_DESKTOP", "").split(":"):
    p = Path(__file__).parent / "themes/noctalia.conf"
    if p.exists():
        print(p.read_text())
