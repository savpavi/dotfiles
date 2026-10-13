import QtQuick
import qs.common
import qs.services

// Window layout values (Hyprland general/decoration) via settings.json.
Column {
    readonly property var lay: HyprSettings.data?.layout ?? null
    spacing: 0
    visible: lay !== null

    SettingRow {
        title: "Pencereler arası boşluk"
        hint: "Döşeli pencerelerin birbirine uzaklığı"
        Stepper { value: lay?.gaps_in ?? 0; from: 0; to: 40; suffix: " px"; onEdited: v => HyprSettings.setLayout("gaps_in", v) }
    }
    SettingRow {
        title: "Ekran kenarı boşluğu"
        Stepper { value: lay?.gaps_out ?? 0; from: 0; to: 60; suffix: " px"; onEdited: v => HyprSettings.setLayout("gaps_out", v) }
    }
    SettingRow {
        title: "Kenarlık kalınlığı"
        hint: "Renk aktif temadan gelir"
        Stepper { value: lay?.border_size ?? 0; from: 0; to: 8; suffix: " px"; onEdited: v => HyprSettings.setLayout("border_size", v) }
    }
    SettingRow {
        title: "Köşe yuvarlaklığı"
        Stepper { value: lay?.rounding ?? 0; from: 0; to: 30; suffix: " px"; onEdited: v => HyprSettings.setLayout("rounding", v) }
    }

    Label {
        topPadding: 14
        width: parent.width
        wrapMode: Text.WordWrap
        elide: Text.ElideNone
        color: Theme.fgDim
        font.pixelSize: Theme.fontSmall
        text: "Değerler ~/dotfiles/config/hypr/settings.json dosyasına yazılır; her değişiklikten önce Hyprland config'i doğrulanır, hata olursa geri alınır."
    }
}
