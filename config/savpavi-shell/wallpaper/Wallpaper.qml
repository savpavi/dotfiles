import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common

// Static wallpaper on the background layer, one per screen. The path comes from
// dot-shell-theme's state file (Theme.wallpaper); changes crossfade. Hidden while a
// live wallpaper (waywallen) is active, so it never covers it.
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

    // Two images: the new one loads underneath, then fades in over the old one.
    property bool frontIsA: true
    readonly property string target: Theme.wallpaper ? "file://" + Theme.wallpaper : ""

    onTargetChanged: {
        const back = frontIsA ? b : a;
        // the back image may already hold this file (switching back): just bring it forward
        if (back.source.toString() === target && back.status === Image.Ready) frontIsA = !frontIsA;
        else back.source = target;
    }

    Image {
        id: a
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize: Qt.size(root.width, root.height)
        opacity: root.frontIsA ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }
        onStatusChanged: if (status === Image.Ready && source.toString() === root.target && !root.frontIsA) root.frontIsA = true
    }

    Image {
        id: b
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize: Qt.size(root.width, root.height)
        opacity: root.frontIsA ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }
        onStatusChanged: if (status === Image.Ready && source.toString() === root.target && root.frontIsA) root.frontIsA = false
    }

    Component.onCompleted: {
        a.source = target;
    }
}
