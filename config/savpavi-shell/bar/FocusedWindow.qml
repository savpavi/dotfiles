import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.common
import qs.services

// App icon + title of the focused window, shown only on the focused monitor.
Row {
    id: root

    required property ShellScreen screen
    readonly property var win: ToplevelManager.activeToplevel
    readonly property bool shown: win !== null && win.activated && win.screens.some(s => s.name === screen.name)
    readonly property string appId: win?.appId ?? ""

    spacing: 7
    visible: ShellState.settings.showFocusedWindow && shown && title.text !== ""

    IconImage {
        anchors.verticalCenter: parent.verticalCenter
        implicitSize: 16
        source: {
            const e = DesktopEntries.heuristicLookup(root.appId);
            return Quickshell.iconPath(e?.icon ?? root.appId, true);
        }
        visible: source.toString() !== ""
    }

    Label {
        id: title
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, 300)
        text: root.win?.title ?? ""
        color: Theme.fgDim
    }
}
