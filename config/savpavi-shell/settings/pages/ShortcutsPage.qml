import QtQuick
import Quickshell
import Quickshell.Io
import qs.common
import qs.services
import "../../launcher/Search.js" as S
import "../../common/KeyNames.js" as K

// Shortcuts: search, change the key of any bind (rewrites that hl.bind line),
// add / remove custom shortcuts (user-binds.json; to change one, delete and add
// it again). Changes are verified and
// reloaded by hypr-settings.py.
Column {
    id: root

    property var binds: []
    property string filter: ""
    property var editing: null           // bind being rebound, or { add: true }
    property string captured: ""
    property string newName: ""
    property string newCmd: ""

    readonly property var conflict: {
        if (!captured) return null;
        const n = K.normalize(captured);
        return binds.find(b => b !== editing && K.normalize(b.raw) === n) ?? null;
    }
    readonly property var cats: {
        const q = S.fold(filter), groups = [];
        for (const b of binds) {
            if (q && !S.fold(b.desc + " " + b.keys.join(" ")).includes(q)) continue;
            let g = groups.find(x => x.name === b.cat);
            if (!g) groups.push(g = { name: b.cat, items: [] });
            g.items.push(b);
        }
        return groups;
    }

    function startEdit(b) { editing = b; captured = ""; capture.forceActiveFocus(); }
    function startAdd() { editing = { add: true }; captured = ""; newName = ""; newCmd = ""; }
    function cancel() { editing = null; captured = ""; }
    function save() {
        if (!captured || conflict) return;
        if (editing.add) {
            if (!newName || !newCmd) return;
            HyprSettings.bindAdd(captured, newName, newCmd);
        } else {
            HyprSettings.bindSet(editing.file, editing.line, captured);
        }
        editing = null;
    }

    Process {
        id: list
        running: true
        command: ["python3", Qt.resolvedUrl("../../scripts/keybinds.py").toString().replace("file://", "")]
        stdout: StdioCollector { onStreamFinished: { try { root.binds = JSON.parse(text); } catch (e) {} } }
    }
    Connections {
        target: HyprSettings
        function onApplied() { list.running = true; }
    }

    spacing: 10

    Row {
        width: parent.width
        spacing: 8

        Rectangle {
            width: parent.width - addBtn.width - 8
            height: 36
            radius: 18
            color: Theme.bgAlt
            Icon { id: si; name: "search"; color: Theme.fgDim; x: 12; anchors.verticalCenter: parent.verticalCenter }
            TextInput {
                anchors.left: si.right
                anchors.leftMargin: 8
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.fg
                font.family: Theme.sans
                font.pixelSize: Theme.fontSize
                clip: true
                onTextChanged: root.filter = text
                Label { visible: parent.text === ""; text: "Kısayol ya da tuş ara…"; color: Theme.fgDim; anchors.verticalCenter: parent.verticalCenter }
            }
        }
        BarButton {
            id: addBtn
            anchors.verticalCenter: parent.verticalCenter
            Icon { name: "add"; anchors.verticalCenter: parent.verticalCenter }
            Label { text: "Yeni kısayol"; anchors.verticalCenter: parent.verticalCenter }
            onClicked: root.startAdd()
        }
    }

    // capture / add panel
    Rectangle {
        visible: root.editing !== null
        width: parent.width
        height: editCol.implicitHeight + 24
        radius: Theme.radius
        color: Theme.bgAlt
        border.width: 2
        border.color: Theme.primary

        Column {
            id: editCol
            x: 14
            y: 12
            width: parent.width - 28
            spacing: 8

            Label {
                text: root.editing?.add ? "Yeni kısayol" : "“" + (root.editing?.desc ?? "") + "” için yeni tuş"
                font.weight: Font.DemiBold
            }

            Row {
                visible: root.editing?.add ?? false
                spacing: 8
                width: parent.width
                Rectangle {
                    width: 260; height: 34; radius: Theme.radiusSmall; color: Theme.bgHigh
                    TextInput {
                        anchors.fill: parent; anchors.margins: 9; color: Theme.fg; font.family: Theme.sans; font.pixelSize: Theme.fontSize; clip: true
                        text: root.newName; onTextChanged: root.newName = text
                        Label { visible: parent.text === ""; text: "Ad (ör. Hesap makinesi)"; color: Theme.fgDim }
                    }
                }
                Rectangle {
                    width: parent.width - 268; height: 34; radius: Theme.radiusSmall; color: Theme.bgHigh
                    TextInput {
                        anchors.fill: parent; anchors.margins: 9; color: Theme.fg; font.family: Theme.mono; font.pixelSize: Theme.fontSize; clip: true
                        text: root.newCmd; onTextChanged: root.newCmd = text
                        Label { visible: parent.text === ""; text: "Komut ya da aşağıdan uygulama seç"; color: Theme.fgDim; font.family: Theme.sans }
                    }
                }
            }
            Select {
                visible: root.editing?.add ?? false
                boxWidth: 320
                options: DesktopEntries.applications.values.filter(a => !a.noDisplay)
                    .sort((a, b) => a.name.localeCompare(b.name)).map(a => ({ value: a.id, label: a.name }))
                value: ""
                onPicked: v => {
                    const a = DesktopEntries.applications.values.find(x => x.id === v);
                    root.newCmd = "uwsm app -- " + v + ".desktop";
                    if (!root.newName && a) root.newName = a.name;
                }
            }

            Rectangle {
                width: parent.width
                height: 46
                radius: Theme.radiusSmall
                color: capture.activeFocus ? Theme.bgHighest : Theme.bgHigh
                Item {
                    id: capture
                    anchors.fill: parent
                    Keys.onPressed: e => {
                        if (e.key === Qt.Key_Escape && !e.modifiers) { root.cancel(); e.accepted = true; return; }
                        const c = K.combo(e);
                        if (c) root.captured = c;
                        e.accepted = true;
                    }
                    MouseArea { anchors.fill: parent; onClicked: capture.forceActiveFocus() }
                }
                Label {
                    anchors.centerIn: parent
                    text: root.captured || (capture.activeFocus ? "Tuş birleşimine bas… (Esc: vazgeç)" : "Tuş yakalamak için tıkla")
                    font.family: root.captured ? Theme.mono : Theme.sans
                    font.pixelSize: root.captured ? 16 : Theme.fontSize
                    color: root.captured ? Theme.fg : Theme.fgDim
                }
            }
            Label {
                width: parent.width
                wrapMode: Text.WordWrap
                elide: Text.ElideNone
                font.pixelSize: Theme.fontSmall
                color: root.conflict ? Theme.error : Theme.fgDim
                text: root.conflict ? "Bu tuş zaten kullanılıyor: " + root.conflict.desc
                    : "Hyprland'e bağlı bir birleşime basarsan o kısayol çalışır ve buraya ulaşmaz; o tuş zaten dolu demektir."
            }
            Row {
                spacing: 6
                BarButton {
                    active: root.captured !== "" && !root.conflict && (!(root.editing?.add) || (root.newName !== "" && root.newCmd !== ""))
                    Icon { name: "check"; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: "Kaydet"; anchors.verticalCenter: parent.verticalCenter }
                    onClicked: root.save()
                }
                BarButton {
                    Label { text: "Vazgeç"; anchors.verticalCenter: parent.verticalCenter }
                    onClicked: root.cancel()
                }
            }
        }
    }

    Repeater {
        model: root.cats

        Column {
            id: group
            required property var modelData
            width: root.width
            spacing: 0

            Label { text: group.modelData.name; color: Theme.primary; font.weight: Font.DemiBold; topPadding: 10; bottomPadding: 4 }

            Repeater {
                model: group.modelData.items
                Rectangle {
                    id: line
                    required property var modelData
                    width: group.width
                    height: 40
                    radius: Theme.radiusSmall
                    color: lm.containsMouse ? Theme.bgAlt : "transparent"

                    Label {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.right: keyRow.left
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: line.modelData.desc
                    }
                    Row {
                        id: keyRow
                        anchors.right: actions.left
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3
                        Repeater {
                            model: line.modelData.keys
                            Rectangle {
                                required property string modelData
                                width: Math.max(24, kl.implicitWidth + 12)
                                height: 24
                                radius: 5
                                color: Theme.bgHighest
                                Label { id: kl; anchors.centerIn: parent; text: parent.modelData; font.family: Theme.mono; font.pixelSize: Theme.fontSmall }
                            }
                        }
                    }
                    Row {
                        id: actions
                        anchors.right: parent.right
                        anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        width: 64
                        layoutDirection: Qt.RightToLeft
                        BarButton {
                            visible: line.modelData.custom
                            padding: 5
                            Icon { name: "delete"; color: Theme.error; anchors.verticalCenter: parent.verticalCenter }
                            onClicked: HyprSettings.bindRemove(root.binds.filter(b => b.custom).indexOf(line.modelData))
                        }
                        BarButton {
                            visible: line.modelData.editable && !line.modelData.custom
                            padding: 5
                            Icon { name: "edit"; anchors.verticalCenter: parent.verticalCenter }
                            onClicked: root.startEdit(line.modelData)
                        }
                    }
                    MouseArea { id: lm; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
                }
            }
        }
    }
}
