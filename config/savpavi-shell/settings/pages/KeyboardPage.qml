import QtQuick
import qs.common
import qs.services
import "../../common/KeyNames.js" as K

Column {
    id: root

    readonly property var inp: HyprSettings.data?.input ?? null
    property var events: []

    spacing: 0

    Label { text: "Klavye"; color: Theme.fgDim; font.pixelSize: Theme.fontSmall; bottomPadding: 4 }
    SettingRow {
        title: "Düzen"
        hint: "Türkçe Q. Değiştirmek için hyprland.lua (kb_layout)"
        Label { text: "tr"; font.family: Theme.mono }
    }
    SettingRow {
        title: "Tekrar hızı"
        hint: "Basılı tutunca saniyedeki tekrar"
        Stepper { value: root.inp?.repeat_rate ?? 0; from: 10; to: 80; suffix: "/sn"; onEdited: v => HyprSettings.setInput("repeat_rate", v) }
    }
    SettingRow {
        title: "Tekrar gecikmesi"
        hint: "Tekrar başlamadan önceki bekleme"
        Stepper { value: root.inp?.repeat_delay ?? 0; from: 150; to: 800; step: 25; suffix: " ms"; onEdited: v => HyprSettings.setInput("repeat_delay", v) }
    }

    Item { width: 1; height: 18 }
    Label { text: "Fare"; color: Theme.fgDim; font.pixelSize: Theme.fontSmall; bottomPadding: 4 }
    SettingRow {
        title: "İmleç hassasiyeti"
        hint: "-1 (yavaş) … 1 (hızlı); DPI ayarı solaar'da"
        Stepper { value: root.inp?.sensitivity ?? 0; from: -1; to: 1; step: 0.1; decimals: 1; onEdited: v => HyprSettings.setInput("sensitivity", v) }
    }
    Toggle {
        title: "Doğal kaydırma"
        hint: "Tekerlek/dokunmatik yüzey yönünü ters çevirir"
        checked: root.inp?.natural_scroll ?? false
        onToggled: v => HyprSettings.setInput("natural_scroll", v)
    }

    Item { width: 1; height: 18 }
    Label { text: "Tuş testi"; color: Theme.fgDim; font.pixelSize: Theme.fontSmall; bottomPadding: 4 }
    Label {
        width: parent.width
        wrapMode: Text.WordWrap
        elide: Text.ElideNone
        color: Theme.fgDim
        font.pixelSize: Theme.fontSmall
        bottomPadding: 8
        text: "Kutuya tıkla ve tuşlara bas: her tuşun Hyprland'deki adı ve kodu görünür. Sorunlu tuşları bulmak ve kısayol atarken hangi adı kullanacağını görmek için. Hyprland'e bağlı kısayollar (ör. Super+K) buraya ulaşmaz, onlar zaten çalışıyor demektir."
    }
    Rectangle {
        width: parent.width
        height: 200
        radius: Theme.radius
        color: tester.activeFocus ? Theme.bgHigh : Theme.bgAlt
        border.width: tester.activeFocus ? 2 : 0
        border.color: Theme.primary

        Item {
            id: tester
            anchors.fill: parent
            focus: false
            Keys.onPressed: e => {
                const row = { combo: K.combo(e) || K.mods(e.modifiers).join(" + "), text: e.text, code: e.nativeScanCode, qt: "0x" + e.key.toString(16) };
                root.events = [row, ...root.events].slice(0, 7);
                e.accepted = true;
            }
            MouseArea { anchors.fill: parent; onClicked: tester.forceActiveFocus() }
        }

        Label {
            anchors.centerIn: parent
            visible: root.events.length === 0
            text: tester.activeFocus ? "Bir tuşa bas…" : "Teste başlamak için tıkla"
            color: Theme.fgDim
        }

        Column {
            x: 14
            y: 12
            width: parent.width - 28
            spacing: 4
            Repeater {
                model: root.events
                Row {
                    required property var modelData
                    required property int index
                    spacing: 16
                    opacity: 1 - index * 0.12
                    Label { width: 260; text: modelData.combo; font.family: Theme.mono; font.weight: index === 0 ? Font.Bold : Font.Normal }
                    Label { width: 60; text: modelData.text.trim() ? "“" + modelData.text + "”" : ""; color: Theme.fgDim }
                    Label { text: "code:" + modelData.code + "   Qt " + modelData.qt; color: Theme.fgDim; font.family: Theme.mono; font.pixelSize: Theme.fontSmall }
                }
            }
        }
    }
}
