import QtQuick

// Material Symbols Rounded glyph by name, e.g. Icon { name: "wifi" }.
Text {
    property string name
    property real size: Theme.iconSize
    property bool filled: false

    text: name
    color: Theme.fg
    font.family: Theme.icons
    font.pixelSize: size
    font.variableAxes: ({ "FILL": filled ? 1 : 0, "wght": 400, "opsz": 20 })
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
    renderType: Text.NativeRendering

    Behavior on color { ColorAnimation { duration: Theme.animMs } }
}
