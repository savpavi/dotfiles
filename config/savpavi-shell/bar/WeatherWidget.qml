import QtQuick
import qs.common
import qs.services

BarButton {
    id: root
    visible: ShellState.settings.showWeather && Weather.ready

    Icon { name: Weather.icon; anchors.verticalCenter: parent.verticalCenter }
    Label { text: Math.round(Weather.temp) + "°"; anchors.verticalCenter: parent.verticalCenter }

    onClicked: dd.toggle()

    Dropdown {
        id: dd
        anchorItem: root
        contentWidth: 220

        Column {
            width: parent.width
            spacing: 6

            Row {
                spacing: 10
                Icon { name: Weather.icon; size: 34; color: Theme.primary }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Label { text: Math.round(Weather.temp) + "°  " + Weather.description; font.weight: Font.DemiBold }
                    Label { text: Weather.city; color: Theme.fgDim; font.pixelSize: Theme.fontSmall }
                }
            }
            Label { text: "En yüksek " + Math.round(Weather.tempMax) + "°  ·  en düşük " + Math.round(Weather.tempMin) + "°"; color: Theme.fgDim }
            Label { text: "Rüzgâr " + Math.round(Weather.windKmh) + " km/s  ·  nem %" + Weather.humidity; color: Theme.fgDim }
        }
    }
}
