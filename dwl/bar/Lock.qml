// Oturum kilidi (ext-session-lock). Renkler etkin temadan gelir.
// Parola PAM ile doğrulanır (pam/login: yalnız pam_unix, hatada 2 sn bekleme).
// Kilitle: quickshell ipc -p <bar> call lock lock
import QtQuick
import Quickshell
import Quickshell.Services.Pam
import Quickshell.Wayland

Scope {
    id: root
    required property var sh

    property bool locked: false
    property string buffer: ""
    property string message: ""
    property bool checking: false

    readonly property var m: sh.m
    readonly property string mono: "JetBrainsMono Nerd Font"

    function lock() {
        if (locked)
            return;
        buffer = "";
        message = "";
        locked = true;
    }
    function submit() {
        if (checking || buffer === "")
            return;
        checking = true;
        message = "";
        pam.start();
    }

    PamContext {
        id: pam
        configDirectory: Quickshell.shellDir + "/pam"
        config: "login"

        onResponseRequiredChanged: if (responseRequired) respond(root.buffer)
        onCompleted: result => {
            root.checking = false;
            root.buffer = "";
            if (result === PamResult.Success)
                root.locked = false;
            else
                root.message = result === PamResult.MaxTries ? "Çok fazla deneme" : "Parola yanlış";
        }
        onError: () => {
            root.checking = false;
            root.buffer = "";
            root.message = "Kimlik doğrulama hatası";
        }
    }

    WlSessionLock {
        locked: root.locked

        WlSessionLockSurface {
            color: root.sh.wm.root

            SystemClock { id: clock; precision: SystemClock.Minutes }

            Column {
                anchors.centerIn: parent
                spacing: 18

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatTime(clock.date, "HH:mm")
                    font.family: root.mono
                    font.pixelSize: 120
                    font.bold: true
                    color: root.m.text
                }
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 360
                    height: Math.max(2, root.m.borderpx)
                    color: root.m.match
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.locale("tr_TR").toString(clock.date, "d MMMM dddd")
                    font.family: root.mono
                    font.pixelSize: 18
                    color: root.m.text
                }
                Item { width: 1; height: 22 }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 360
                    height: 46
                    radius: root.m.radius
                    color: root.m.bg
                    border.width: Math.max(2, root.m.borderpx)
                    border.color: root.message !== "" ? root.m.match : root.m.border

                    Text {
                        id: prompt
                        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                        text: root.checking ? "…" : ">"
                        font.family: root.mono
                        font.pixelSize: 16
                        color: root.m.match
                    }
                    TextInput {
                        id: field
                        anchors { left: prompt.right; leftMargin: 10; right: parent.right; rightMargin: 14
                                  verticalCenter: parent.verticalCenter }
                        echoMode: TextInput.Password
                        passwordCharacter: "•"
                        color: root.m.text
                        font.family: root.mono
                        font.pixelSize: 16
                        clip: true
                        focus: true
                        enabled: !root.checking
                        text: root.buffer
                        onTextChanged: {
                            root.buffer = text;
                            if (text !== "")
                                root.message = "";
                        }
                        Keys.onReturnPressed: root.submit()
                        Keys.onEnterPressed: root.submit()
                        Keys.onEscapePressed: root.buffer = ""
                        Component.onCompleted: forceActiveFocus()
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 20
                    text: root.message !== "" ? root.message : (field.text === "" ? "parolanı yaz, Enter" : "")
                    font.family: root.mono
                    font.pixelSize: 13
                    color: root.message !== "" ? root.m.match : root.m.text
                    opacity: root.message !== "" ? 1 : 0.55
                }
            }
        }
    }
}
