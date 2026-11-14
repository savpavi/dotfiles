import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Statik duvar kağıdı, ekran başına bir tane, arka plan katmanında. Yol
// dwl-theme'in wall.json'undan gelir (sh.wallImage); hareketli duvar açıkken
// boştur ve pencere gizlenir. Değişimi WallFx çizer: bin/dot-wallfx
// yeni görselin hangi geçişi alacağını ve haritasını söyler (çizim ya da
// yayılma); betik yoksa düz geçiş olur.
PanelWindow {
    id: root

    required property var modelData
    required property var sh
    screen: modelData

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "dwl-wallpaper"
    color: sh.wm.root ?? "black"
    visible: target !== ""

    readonly property string tool: Quickshell.shellDir + "/../bin/dot-wallfx"
    readonly property string target: sh.wallImage

    onTargetChanged: retarget()
    function retarget() {
        // öncesi yoksa ya da görünmüyorsa geçiş oynatma
        if (!fx.hasImage || !visible || !target) fx.set(target);
        else pick();
    }
    Component.onCompleted: fx.set(target)

    function pick() {
        if (picker.running) return;      // hedef bu arada değiştiyse onExited yeniden sorar
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

    // Betik yoksa ya da takılırsa da duvar değişmeli.
    Timer {
        id: fallback
        interval: 1500
        onTriggered: root.answer(picker.path, "fade", "")
    }

    WallFx {
        id: fx
        anchors.fill: parent
        ink: root.sh.b.fg
        edge: root.sh.b.accent
    }
}
