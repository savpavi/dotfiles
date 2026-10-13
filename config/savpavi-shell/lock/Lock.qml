import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import qs.common

// Session lock (ext-session-lock): blurred wallpaper, clock, password field.
// Password check is PAM with the shell's own minimal config (assets/pam/login).
// Lock: qs -p <dir> ipc call lock lock
Scope {
    id: root

    property bool locked: false
    property string buffer: ""
    property string message: ""
    property bool checking: false

    function lock() {
        buffer = "";
        message = "";
        locked = true;
    }

    function submit() {
        if (checking || buffer === "") return;
        checking = true;
        message = "";
        pam.start();
    }

    PamContext {
        id: pam
        configDirectory: Quickshell.shellDir + "/assets/pam"
        config: "login"

        onResponseRequiredChanged: if (responseRequired) respond(root.buffer)

        onCompleted: result => {
            root.checking = false;
            if (result === PamResult.Success) {
                root.locked = false;
                root.buffer = "";
            } else {
                root.buffer = "";
                root.message = result === PamResult.MaxTries ? "Çok fazla deneme" : "Şifre yanlış";
            }
        }
        onError: () => {
            root.checking = false;
            root.message = "Kimlik doğrulama hatası";
        }
    }

    WlSessionLock {
        locked: root.locked

        WlSessionLockSurface {
            id: surface
            color: Theme.bg

            Image {
                id: wall
                anchors.fill: parent
                source: Theme.wallpaper ? "file://" + Theme.wallpaper : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: false
            }

            MultiEffect {
                anchors.fill: parent
                source: wall
                blurEnabled: true
                blur: 1
                blurMax: 64
                brightness: -0.25
                visible: wall.status === Image.Ready
            }

            SystemClock { id: clock; precision: SystemClock.Seconds }

            Column {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -60
                spacing: 6

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatTime(clock.date, "HH:mm")
                    font.pixelSize: 96
                    font.weight: Font.Light
                    color: "white"
                }
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.locale("tr_TR").toString(clock.date, "d MMMM dddd")
                    font.pixelSize: 20
                    color: Qt.rgba(1, 1, 1, 0.8)
                }
            }

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.verticalCenter
                anchors.topMargin: 60
                spacing: 10

                Rectangle {
                    id: box
                    width: 320
                    height: 48
                    radius: 24
                    color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.75)
                    border.width: 2
                    border.color: root.message ? Theme.error : (field.activeFocus ? Theme.primary : "transparent")
                    transform: Translate { id: shakeT }

                    Icon {
                        id: lockIcon
                        name: root.checking ? "hourglass_top" : "lock"
                        color: Theme.primary
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    TextInput {
                        id: field
                        anchors.left: lockIcon.right
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        echoMode: TextInput.Password
                        passwordCharacter: "•"
                        color: Theme.fg
                        font.family: Theme.sans
                        font.pixelSize: 16
                        focus: true
                        enabled: !root.checking
                        text: root.buffer
                        onTextChanged: { root.buffer = text; if (text !== "") root.message = ""; }
                        Keys.onReturnPressed: root.submit()
                        Keys.onEnterPressed: root.submit()
                        Keys.onEscapePressed: root.buffer = ""

                        Label {
                            visible: field.text === ""
                            text: Quickshell.env("USER") + " için şifre"
                            color: Theme.fgDim
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // shake on failure
                    SequentialAnimation {
                        id: shake
                        NumberAnimation { target: shakeT; property: "x"; to: -10; duration: 50 }
                        NumberAnimation { target: shakeT; property: "x"; to: 10; duration: 50 }
                        NumberAnimation { target: shakeT; property: "x"; to: -6; duration: 50 }
                        NumberAnimation { target: shakeT; property: "x"; to: 0; duration: 50 }
                    }
                    Connections {
                        target: root
                        function onMessageChanged() { if (root.message) shake.start(); }
                    }
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.message
                    color: Theme.error
                    visible: text !== ""
                }
            }

            Component.onCompleted: field.forceActiveFocus()
        }
    }

    IpcHandler {
        target: "lock"
        function lock(): void { root.lock(); }
        function isLocked(): bool { return root.locked; }
    }
}
