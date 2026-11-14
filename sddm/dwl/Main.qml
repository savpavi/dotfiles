// dwl SDDM giriş ekranı. Renkler theme.conf(.user) içinden gelir; dwl-theme her tema
// değişiminde theme.conf.user'ı yeniden yazar, böylece giriş ekranı etkin temayı izler.
import QtQuick
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: config.bg

    readonly property string mono: "JetBrainsMono Nerd Font"
    readonly property int line: Math.max(2, parseInt(config.borderpx))
    property int sessionIndex: sessionModel.lastIndex
    property string message: ""
    property date now: new Date()

    function login() {
        root.message = "";
        sddm.login(userField.input.text, passField.input.text, root.sessionIndex);
    }

    Timer { interval: 5000; running: true; repeat: true; onTriggered: root.now = new Date() }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.message = "Parola yanlış";
            passField.input.text = "";
            passField.input.forceActiveFocus();
        }
    }

    component Field: Rectangle {
        property alias input: input
        property string prompt: ">"
        width: 380
        height: 46
        radius: parseInt(config.radius)
        color: config.panel
        border.width: root.line
        border.color: input.activeFocus ? config.accent : config.border

        Text {
            id: lead
            anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
            text: parent.prompt
            font.family: root.mono
            font.pixelSize: 16
            color: config.accent
        }
        TextInput {
            id: input
            anchors { left: lead.right; leftMargin: 10; right: parent.right; rightMargin: 14
                      verticalCenter: parent.verticalCenter }
            color: config.fg
            font.family: root.mono
            font.pixelSize: 16
            clip: true
            selectByMouse: true
        }
    }
    component Link: Text {
        signal activated()
        font.family: root.mono
        font.pixelSize: 14
        color: hover.hovered ? config.accent : config.fg
        opacity: hover.hovered ? 1 : 0.7
        HoverHandler { id: hover }
        TapHandler { onTapped: parent.activated() }
    }

    Column {
        anchors.centerIn: parent
        spacing: 16

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(root.now, "HH:mm")
            font.family: root.mono
            font.pixelSize: 128
            font.bold: true
            color: config.fg
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 380
            height: root.line
            color: config.accent
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.locale("tr_TR").toString(root.now, "d MMMM dddd")
            font.family: root.mono
            font.pixelSize: 18
            color: config.fg
        }
        Item { width: 1; height: 24 }

        Field {
            id: userField
            anchors.horizontalCenter: parent.horizontalCenter
            prompt: "kim"
            input.text: userModel.lastUser
            input.onAccepted: passField.input.forceActiveFocus()
            input.KeyNavigation.tab: passField.input
        }
        Field {
            id: passField
            anchors.horizontalCenter: parent.horizontalCenter
            prompt: ">"
            input.echoMode: TextInput.Password
            input.passwordCharacter: "•"
            input.onAccepted: root.login()
            input.KeyNavigation.backtab: userField.input
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            height: 20
            text: root.message !== "" ? root.message : "parolanı yaz, Enter"
            font.family: root.mono
            font.pixelSize: 13
            color: root.message !== "" ? config.accent : config.fg
            opacity: root.message !== "" ? 1 : 0.55
        }
    }

    // Alt şerit: oturum seçimi solda, güç sağda
    Row {
        anchors { left: parent.left; bottom: parent.bottom; margins: 28 }
        spacing: 10

        Text {
            text: "oturum"
            font.family: root.mono
            font.pixelSize: 14
            color: config.fg
            opacity: 0.55
        }
        Item {
            width: 260
            height: 20
            Repeater {
                model: sessionModel
                Link {
                    visible: index === root.sessionIndex
                    text: model.name + "  ›"
                    font.bold: true
                    opacity: 1
                    onActivated: root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount()
                }
            }
        }
    }
    Row {
        anchors { right: parent.right; bottom: parent.bottom; margins: 28 }
        spacing: 28
        Link { visible: sddm.canReboot; text: "yeniden başlat"; onActivated: sddm.reboot() }
        Link { visible: sddm.canPowerOff; text: "kapat"; onActivated: sddm.powerOff() }
    }

    Component.onCompleted: passField.input.forceActiveFocus()
}
