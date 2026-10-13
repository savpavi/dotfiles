import QtQuick
import Quickshell
import Quickshell.Io
import qs.common
import qs.services
import "pages"

// System settings (Super+Alt+S): a normal window with KDE-style grouped pages.
FloatingWindow {
    id: root

    property string page: "appearance"
    readonly property var groups: [
        { name: "Kişiselleştirme", pages: [
            { id: "appearance", icon: "palette", name: "Tema ve duvar kağıdı" },
            { id: "windows", icon: "dashboard", name: "Pencereler" },
            { id: "bar", icon: "view_agenda", name: "Bar" },
            { id: "notifications", icon: "notifications", name: "Bildirimler" } ] },
        { name: "Donanım", pages: [
            { id: "displays", icon: "monitor", name: "Ekranlar" },
            { id: "sound", icon: "volume_up", name: "Ses" },
            { id: "keyboard", icon: "keyboard", name: "Klavye ve fare" } ] },
        { name: "Uygulamalar", pages: [
            { id: "defaults", icon: "apps", name: "Varsayılan uygulamalar" },
            { id: "shortcuts", icon: "keyboard_command_key", name: "Kısayollar" } ] },
        { name: "Sistem", pages: [
            { id: "power", icon: "power_settings_new", name: "Güç ve oturum" },
            { id: "about", icon: "info", name: "Sistem bilgisi" },
            { id: "shell", icon: "terminal", name: "Shell" } ] }
    ]
    readonly property var pageInfo: groups.reduce((all, g) => all.concat(g.pages), []).find(p => p.id === page)

    function open(p) {
        if (p) page = p;
        HyprSettings.refresh();
        visible = true;
    }

    title: "Ayarlar"
    implicitWidth: 1040
    implicitHeight: 700
    color: Theme.bg
    visible: false

    // sidebar
    Rectangle {
        id: side
        width: 250
        height: parent.height
        color: Theme.bgAlt

        Flickable {
            anchors.fill: parent
            anchors.margins: 12
            contentHeight: nav.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: nav
                width: parent.width
                spacing: 2

                Label { text: "Ayarlar"; font.pixelSize: 20; font.weight: Font.DemiBold; leftPadding: 8; topPadding: 4; bottomPadding: 8 }

                Repeater {
                    model: root.groups
                    Column {
                        required property var modelData
                        width: nav.width
                        spacing: 2
                        Label { text: modelData.name; color: Theme.fgDim; font.pixelSize: Theme.fontSmall; leftPadding: 10; topPadding: 12; bottomPadding: 2 }
                        Repeater {
                            model: modelData.pages
                            MenuItem {
                                required property var modelData
                                width: nav.width
                                icon: modelData.icon
                                text: modelData.name
                                checked: root.page === modelData.id
                                onClicked: root.page = modelData.id
                            }
                        }
                    }
                }
            }
        }
    }

    // page
    Flickable {
        id: content
        anchors.left: side.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 28
        contentHeight: pageCol.implicitHeight + 20
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: pageCol
            width: content.width
            spacing: 14

            Row {
                spacing: 10
                Icon { name: root.pageInfo?.icon ?? ""; size: 26; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
                Label { text: root.pageInfo?.name ?? ""; font.pixelSize: 22; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
            }

            Rectangle {
                visible: HyprSettings.lastError !== ""
                width: parent.width
                height: errText.implicitHeight + 20
                radius: Theme.radiusSmall
                color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.18)
                Label {
                    id: errText
                    x: 12
                    y: 10
                    width: parent.width - 24
                    text: "Uygulanamadı, geri alındı: " + HyprSettings.lastError
                    wrapMode: Text.WordWrap
                    elide: Text.ElideNone
                }
            }

            Loader {
                width: parent.width
                active: root.visible
                source: {
                    const map = { appearance: "AppearancePage", windows: "WindowsPage", bar: "BarPage", notifications: "NotificationsPage",
                        displays: "DisplaysPage", sound: "SoundPage", keyboard: "KeyboardPage", defaults: "DefaultsPage",
                        shortcuts: "ShortcutsPage", power: "PowerPage", about: "AboutPage", shell: "ShellPage" };
                    return "pages/" + map[root.page] + ".qml";
                }
                onLoaded: content.contentY = 0
            }
        }
    }

    IpcHandler {
        target: "settings"
        function toggle(): void { root.visible ? root.visible = false : root.open(""); }
        function open(page: string): void { root.open(page); }
    }
}
