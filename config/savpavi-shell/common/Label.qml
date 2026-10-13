import QtQuick

Text {
    color: Theme.fg
    font.family: Theme.sans
    font.pixelSize: Theme.fontSize
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
    renderType: Text.NativeRendering

    Behavior on color { ColorAnimation { duration: Theme.animMs } }
}
