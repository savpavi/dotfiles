import QtQuick
import qs.common
import qs.services

// Monitors: layout preview, mode / scale / rotation / position per monitor.
// Applying writes settings.json; unless confirmed within 15 s it is rolled back
// (like KDE), so a bad mode can't leave the screen unusable.
Column {
    id: root

    readonly property var live: HyprSettings.data?.live ?? []
    readonly property var saved: HyprSettings.data?.monitors ?? []
    property var edits: ({})          // monitor name -> { mode, scale, transform, x, y }
    property var previous: null       // monitor list before the last apply
    property int countdown: 0

    function cfgFor(m) {
        return saved.find(c => c.output === m.name || (c.output.startsWith("desc:") && m.description.startsWith(c.output.slice(5)))) ?? null;
    }
    function modeOf(m) {
        return m.width + "x" + m.height + "@" + Number(m.refreshRate.toFixed(2));
    }
    function current(m, key) {
        const e = edits[m.name];
        if (e && e[key] !== undefined) return e[key];
        if (key === "mode") return cfgFor(m)?.mode ?? modeOf(m);
        if (key === "x") return m.x;
        if (key === "y") return m.y;
        return m[key];
    }
    function edit(m, key, val) {
        const e = Object.assign({}, edits);
        e[m.name] = Object.assign({}, e[m.name] ?? {}, { [key]: val });
        edits = e;
    }
    function modeOptions(m) {
        const seen = new Set(), out = [];
        for (const s of m.availableModes) {
            const v = s.replace(/Hz$/, "").replace(/@(\d+)\.(\d+)/, (_, a, b) => "@" + Number(a + "." + b));
            if (seen.has(v)) continue;
            seen.add(v);
            const [res, hz] = v.split("@");
            out.push({ value: v, label: res + "  ·  " + Math.round(Number(hz)) + " Hz", detail: "" });
        }
        const cur = current(m, "mode");
        if (!seen.has(cur)) out.unshift({ value: cur, label: cur.replace("@", "  ·  ") + " Hz" });
        return out;
    }
    function applyAll() {
        previous = saved.map(c => Object.assign({}, c));
        const list = live.map(m => {
            const c = cfgFor(m);
            return {
                output: c?.output ?? m.name,
                mode: current(m, "mode"),
                position: current(m, "x") + "x" + current(m, "y"),
                scale: current(m, "scale"),
                transform: current(m, "transform")
            };
        });
        HyprSettings.setMonitors(list);
        edits = {};
        countdown = 15;
        tick.start();
    }
    function keep() { tick.stop(); countdown = 0; previous = null; }
    function revert() {
        tick.stop();
        countdown = 0;
        if (previous) HyprSettings.setMonitors(previous);
        previous = null;
    }

    Timer {
        id: tick
        interval: 1000
        repeat: true
        onTriggered: { root.countdown -= 1; if (root.countdown <= 0) root.revert(); }
    }

    spacing: 14

    // arrangement preview
    Rectangle {
        id: preview
        width: parent.width
        height: 170
        radius: Theme.radius
        color: Theme.bgAlt

        readonly property real minX: Math.min(...root.live.map(m => m.x), 0)
        readonly property real minY: Math.min(...root.live.map(m => m.y), 0)
        readonly property real spanX: Math.max(...root.live.map(m => m.x + m.width / m.scale), 1) - minX
        readonly property real spanY: Math.max(...root.live.map(m => m.y + m.height / m.scale), 1) - minY
        readonly property real k: Math.min((width - 40) / spanX, (height - 40) / spanY)

        Repeater {
            model: root.live
            Rectangle {
                required property var modelData
                x: 20 + (modelData.x - preview.minX) * preview.k
                y: 20 + (modelData.y - preview.minY) * preview.k
                width: modelData.width / modelData.scale * preview.k
                height: modelData.height / modelData.scale * preview.k
                radius: 6
                color: modelData.focused ? Theme.primaryContainer : Theme.bgHighest
                border.width: 2
                border.color: modelData.focused ? Theme.primary : Theme.outline
                Column {
                    anchors.centerIn: parent
                    Label { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.name; font.weight: Font.DemiBold }
                    Label { anchors.horizontalCenter: parent.horizontalCenter; text: (modelData.model || "").slice(0, 22); color: Theme.fgDim; font.pixelSize: Theme.fontSmall }
                }
            }
        }
    }

    // pending confirmation
    Rectangle {
        visible: root.countdown > 0
        width: parent.width
        height: 56
        radius: Theme.radius
        color: Theme.primaryContainer
        Label {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: "Yeni ekran ayarları uygulandı. " + root.countdown + " sn içinde onaylanmazsa geri alınacak."
        }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            BarButton { Label { text: "Geri al"; anchors.verticalCenter: parent.verticalCenter } onClicked: root.revert() }
            BarButton { active: true; Label { text: "Koru"; anchors.verticalCenter: parent.verticalCenter } onClicked: root.keep() }
        }
    }

    Repeater {
        model: root.live

        Rectangle {
            id: card
            required property var modelData
            width: root.width
            height: col.implicitHeight + 24
            radius: Theme.radius
            color: Theme.bgAlt

            Column {
                id: col
                x: 16
                y: 12
                width: parent.width - 32

                Row {
                    spacing: 10
                    bottomPadding: 6
                    Icon { name: "monitor"; size: 22; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
                    Column {
                        Label { text: card.modelData.name + "  ·  " + card.modelData.make + " " + card.modelData.model; font.weight: Font.DemiBold }
                        Label {
                            text: card.modelData.physicalWidth > 0
                                ? Math.round(Math.hypot(card.modelData.physicalWidth, card.modelData.physicalHeight) / 25.4) + "″  ·  "
                                  + card.modelData.physicalWidth + "×" + card.modelData.physicalHeight + " mm  ·  şu an "
                                  + card.modelData.width + "×" + card.modelData.height + " @ " + card.modelData.refreshRate.toFixed(2) + " Hz"
                                : ""
                            color: Theme.fgDim
                            font.pixelSize: Theme.fontSmall
                        }
                    }
                }

                SettingRow {
                    title: "Çözünürlük ve yenileme hızı"
                    Select {
                        boxWidth: 260
                        options: root.modeOptions(card.modelData)
                        value: root.current(card.modelData, "mode")
                        onPicked: v => root.edit(card.modelData, "mode", v)
                    }
                }
                SettingRow {
                    title: "Ölçek"
                    Select {
                        boxWidth: 140
                        options: [1, 1.25, 1.5, 1.75, 2].map(v => ({ value: v, label: Math.round(v * 100) + "%" }))
                        value: root.current(card.modelData, "scale")
                        onPicked: v => root.edit(card.modelData, "scale", v)
                    }
                }
                SettingRow {
                    title: "Döndürme"
                    Select {
                        boxWidth: 160
                        options: [{ value: 0, label: "Yok" }, { value: 1, label: "90°" }, { value: 2, label: "180°" }, { value: 3, label: "270°" }]
                        value: root.current(card.modelData, "transform")
                        onPicked: v => root.edit(card.modelData, "transform", v)
                    }
                }
                SettingRow {
                    title: "Konum (x, y)"
                    hint: "Mantıksal piksel; ekranlar birbirine değmeli"
                    Row {
                        spacing: 10
                        Stepper { value: root.current(card.modelData, "x"); from: -10000; to: 10000; step: 10; onEdited: v => root.edit(card.modelData, "x", v) }
                        Stepper { value: root.current(card.modelData, "y"); from: -10000; to: 10000; step: 10; onEdited: v => root.edit(card.modelData, "y", v) }
                    }
                }
            }
        }
    }

    Row {
        spacing: 8
        BarButton {
            active: Object.keys(root.edits).length > 0
            Icon { name: "check"; anchors.verticalCenter: parent.verticalCenter }
            Label { text: "Uygula"; anchors.verticalCenter: parent.verticalCenter }
            onClicked: if (Object.keys(root.edits).length) root.applyAll()
        }
        BarButton {
            visible: Object.keys(root.edits).length > 0
            Label { text: "Vazgeç"; anchors.verticalCenter: parent.verticalCenter }
            onClicked: root.edits = {}
        }
    }
}
