#!/usr/bin/env python3
"""System details for the savpavi-shell settings window, as JSON."""
import json, os, platform, re, shutil, subprocess as sp, time
from pathlib import Path


def run(*a):
    try:
        return sp.run(a, capture_output=True, text=True, timeout=5).stdout.strip()
    except Exception:
        return ""


def os_name():
    try:
        kv = dict(l.split("=", 1) for l in Path("/etc/os-release").read_text().splitlines() if "=" in l)
        return kv.get("PRETTY_NAME", "").strip('"')
    except OSError:
        return ""


def cpu():
    for l in Path("/proc/cpuinfo").read_text().splitlines():
        if l.startswith("model name"):
            return l.split(":", 1)[1].strip() + f" ({os.cpu_count()} iş parçacığı)"
    return ""


def gpus():
    out = []
    for l in run("lspci", "-mm").splitlines():
        if re.search(r'"(VGA compatible controller|3D controller|Display controller)"', l):
            parts = re.findall(r'"([^"]*)"', l)
            if len(parts) >= 3:
                out.append(parts[2].replace("[", "").replace("]", ""))
    return out


def mem():
    kv = {}
    for l in Path("/proc/meminfo").read_text().splitlines():
        k, v = l.split(":", 1)
        kv[k] = int(v.split()[0])
    total, avail = kv["MemTotal"] / 1048576, kv["MemAvailable"] / 1048576
    return {"total_gb": round(total, 1), "used_gb": round(total - avail, 1)}


def disks():
    out = []
    seen = set()
    for mp in ["/", "/home", "/srv/lexar", "/srv/storage"]:
        if not os.path.ismount(mp) and mp != "/":
            continue
        try:
            u = shutil.disk_usage(mp)
        except OSError:
            continue
        key = (u.total, u.used)
        if key in seen:
            continue
        seen.add(key)
        out.append({"mount": mp, "total_gb": round(u.total / 1e9), "used_gb": round(u.used / 1e9)})
    return out


def uptime():
    s = int(float(Path("/proc/uptime").read_text().split()[0]))
    d, h, m = s // 86400, s % 86400 // 3600, s % 3600 // 60
    return (f"{d} gün " if d else "") + f"{h} sa {m} dk"


print(json.dumps({
    "os": os_name(),
    "kernel": platform.release(),
    "host": run("hostnamectl", "hostname") or platform.node(),
    "cpu": cpu(),
    "gpus": gpus(),
    "memory": mem(),
    "disks": disks(),
    "uptime": uptime(),
    "hyprland": run("hyprctl", "version", "-j") and json.loads(run("hyprctl", "version", "-j")).get("tag", ""),
    "quickshell": run("qs", "--version").split("\n")[0],
    "user": os.environ.get("USER", ""),
}, ensure_ascii=False))
