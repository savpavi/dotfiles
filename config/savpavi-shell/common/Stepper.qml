import QtQuick

// −  value  +   (emits changed(v) within [from, to])
Row {
    id: root

    property real value: 0
    property real from: 0
    property real to: 100
    property real step: 1
    property int decimals: 0
    property string suffix: ""
    signal edited(real v)

    function set(v) {
        const c = Math.max(from, Math.min(to, Math.round(v / step) * step));
        if (c !== value) edited(Number(c.toFixed(decimals)));
    }

    spacing: 4

    BarButton {
        Icon { name: "remove"; anchors.verticalCenter: parent.verticalCenter }
        onClicked: root.set(root.value - root.step)
    }
    Rectangle {
        width: 64
        height: 28
        radius: Theme.radiusSmall
        color: Theme.bgHigh
        anchors.verticalCenter: parent.verticalCenter
        Label {
            anchors.centerIn: parent
            text: root.value.toFixed(root.decimals) + root.suffix
            font.family: Theme.mono
        }
        MouseArea {
            anchors.fill: parent
            onWheel: e => root.set(root.value + (e.angleDelta.y > 0 ? root.step : -root.step))
        }
    }
    BarButton {
        Icon { name: "add"; anchors.verticalCenter: parent.verticalCenter }
        onClicked: root.set(root.value + root.step)
    }
}
