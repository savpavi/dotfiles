pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// CPU and memory usage from /proc, sampled every 2 s.
Singleton {
    id: root

    property real cpu: 0      // 0..1
    property real mem: 0      // 0..1
    property real memUsedGb: 0
    property real memTotalGb: 0

    property var _prev: null

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { stat.reload(); meminfo.reload(); }
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const f = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = f[3] + f[4];
            const total = f.reduce((a, b) => a + b, 0);
            if (root._prev) {
                const dt = total - root._prev.total;
                root.cpu = dt > 0 ? 1 - (idle - root._prev.idle) / dt : 0;
            }
            root._prev = { idle, total };
        }
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const kv = {};
            for (const l of text().split("\n")) {
                const m = l.match(/^(\w+):\s+(\d+)/);
                if (m) kv[m[1]] = Number(m[2]);
            }
            const total = kv.MemTotal || 1;
            const used = total - (kv.MemAvailable || 0);
            root.mem = used / total;
            root.memUsedGb = used / 1048576;
            root.memTotalGb = total / 1048576;
        }
    }
}
