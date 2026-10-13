pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Audio visualiser levels from cava. Runs only while `active` (music playing).
Singleton {
    id: root

    property bool active: false
    property var levels: Array(12).fill(0)    // 0..1 each

    Process {
        running: root.active
        command: ["cava", "-p", Qt.resolvedUrl("../scripts/cava.conf").toString().replace("file://", "")]
        stdout: SplitParser {
            onRead: line => {
                const v = line.split(";").filter(s => s !== "").map(n => Number(n) / 7);
                if (v.length) root.levels = v;
            }
        }
        onRunningChanged: if (!running) root.levels = Array(12).fill(0)
    }
}
