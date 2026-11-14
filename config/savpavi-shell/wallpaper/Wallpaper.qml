import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.common

// Static wallpaper on the background layer, one per screen. The path comes from
// dot-shell-theme's state file (Theme.wallpaper). A change is drawn by WallFx:
// bin/dot-wallfx says which transition the new wallpaper gets and hands over
// its map. Hidden while a live wallpaper (waywallen) is active, so it never
// covers it.
PanelWindow {
    id: root

    required property ShellScreen modelData
    screen: modelData

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "savpavi-wallpaper"
    color: Theme.bg
    visible: !Theme.live

    readonly property string tool: Quickshell.env("HOME") + "/dotfiles/bin/dot-wallfx"
    readonly property string target: Theme.wallpaper

    onTargetChanged: retarget()
    function retarget() {
        // nothing to change from, or nobody watching: no transition
        if (!fx.hasImage || !visible || !target) fx.set(target);
        else pick();
    }
    Component.onCompleted: fx.set(target)

    function pick() {
        if (picker.running) return;      // onExited picks again if the target moved on
        picker.path = target;
        picker.answered = false;
        picker.command = [tool, "pick", target];
        picker.running = true;
        fallback.restart();
    }

    function answer(path, kind, map) {
        if (picker.answered) return;
        picker.answered = true;
        fallback.stop();
        if (path === target) fx.show(path, kind, map);
    }

    Process {
        id: picker
        property string path
        property bool answered: true
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split("\t");
                root.answer(picker.path, p[0], p[1] || "");
            }
        }
        onExited: Qt.callLater(() => {
            root.answer(picker.path, "fade", "");
            if (picker.path !== root.target) root.retarget();
        })
    }

    // The wallpaper has to change even if the script is missing or stuck.
    Timer {
        id: fallback
        interval: 1500
        onTriggered: root.answer(picker.path, "fade", "")
    }

    WallFx {
        id: fx
        anchors.fill: parent
        ink: Theme.fg
        edge: Theme.primary
    }
}
