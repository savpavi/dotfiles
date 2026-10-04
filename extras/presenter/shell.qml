import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "components"
ShellRoot {
    id: root
    property string tool: "pen"
    property color ink: "#8fbcbb"
    property int penWidth: 4
    property bool spotlightOn: Quickshell.env("PRESENTER_MODE") === "spotlight"
    property bool ripplesOn: true
    property bool toolbarOn: true
    property real cursorX: 500
    property real cursorY: 400
    property real radius: 180
    PanelWindow {
        id: panel
        screen: Quickshell.screens.find(s => s.name === Quickshell.env("PRESENTER_OUTPUT")) || Quickshell.screens[0]
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "niri-presenter"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        SpotlightLayer { anchors.fill: parent; visible: root.spotlightOn; centerX: root.cursorX; centerY: root.cursorY; radius: root.radius }
        DrawLayer { id: drawing; anchors.fill: parent; tool: root.tool; penColor: root.ink; penWidth: root.penWidth }
        ClickRipples { id: ripples; anchors.fill: parent; rippleColor: root.ink }
        MouseArea {
            anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.CrossCursor
            onPositionChanged: mouse => { root.cursorX=mouse.x; root.cursorY=mouse.y; drawing.extend(mouse.x,mouse.y); }
            onPressed: mouse => {
                root.cursorX=mouse.x;root.cursorY=mouse.y;
                if(root.ripplesOn)ripples.spawn(mouse.x,mouse.y);
                if(mouse.button===Qt.LeftButton)drawing.begin(mouse.x,mouse.y);else drawing.undo();
            }
            onReleased: mouse => { if(mouse.button===Qt.LeftButton)drawing.commit(); }
            onCanceled: drawing.cancel()
            onWheel: wheel => {
                const direction=wheel.angleDelta.y>0?1:-1;
                if(root.spotlightOn && !(wheel.modifiers & Qt.ShiftModifier))root.radius=Math.max(60,Math.min(800,root.radius+direction*20));
                else root.penWidth=Math.max(2,Math.min(40,root.penWidth+direction*2));
            }
        }
        Rectangle {
            visible: root.toolbarOn
            anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 28
            width: controls.width+24; height: 90; radius: 12; color: "#ee2e3440"; border.color: root.ink
            Column {
                anchors.centerIn: parent; spacing: 10
                Row {
                    id: controls; spacing: 7
                    Repeater {
                        model: ["Kalem D","Ok A","Dikdörtgen R","Spot S","Halka P","Geri U","İleri Y","Temizle C","Çık Esc"]
                        Rectangle {
                            required property string modelData
                            required property int index
                            width: label.implicitWidth+18; height: 30; radius: 5; color: mouse.containsMouse?"#667080":"#434c5e"
                            Text { id: label; anchors.centerIn: parent; text: modelData; color: "#eceff4";font.pixelSize:13 }
                            MouseArea { id:mouse; anchors.fill:parent;hoverEnabled:true;onClicked:root.act(index) }
                        }
                    }
                }
                Text { text: "1–4 renk · T menüyü gizle · Tekerlek: kalınlık/spot · Çıkınca alttaki uygulamayı kullan";color:"#d8dee9";font.pixelSize:12 }
            }
        }
        Item {
            anchors.fill: parent; focus:true
            Component.onCompleted: forceActiveFocus()
            Keys.onPressed: event => {
                event.accepted=true;
                switch(event.key) {
                case Qt.Key_Escape:Qt.quit();break;
                case Qt.Key_D:root.tool="pen";break;
                case Qt.Key_A:root.tool="arrow";break;
                case Qt.Key_R:root.tool="rect";break;
                case Qt.Key_S:root.spotlightOn=!root.spotlightOn;break;
                case Qt.Key_P:root.ripplesOn=!root.ripplesOn;break;
                case Qt.Key_T:root.toolbarOn=!root.toolbarOn;break;
                case Qt.Key_U:case Qt.Key_Z:drawing.undo();break;
                case Qt.Key_Y:drawing.redo();break;
                case Qt.Key_C:drawing.clear();break;
                case Qt.Key_1:root.ink="#8fbcbb";break;
                case Qt.Key_2:root.ink="#bf616a";break;
                case Qt.Key_3:root.ink="#ebcb8b";break;
                case Qt.Key_4:root.ink="#eceff4";break;
                default:event.accepted=false;
                }
            }
        }
    }
    function act(index) {
        if(index<3)root.tool=["pen","arrow","rect"][index];
        else if(index===3)root.spotlightOn=!root.spotlightOn;
        else if(index===4)root.ripplesOn=!root.ripplesOn;
        else if(index===5)drawing.undo();else if(index===6)drawing.redo();
        else if(index===7)drawing.clear();else Qt.quit();
    }
    IpcHandler {
        target: "presenter"
        function close(): void { Qt.quit(); }
        function status(): string { return panel.screen.name+" "+root.tool; }
        function stroke(tool: string,x1: int,y1: int,x2: int,y2: int): void {
            if(!["pen","arrow","rect"].includes(tool))return;
            root.tool=tool; drawing.begin(x1,y1);drawing.extend(x2,y2);drawing.commit();
        }
        function spotlight(on: bool): void { root.spotlightOn=on; }
    }
}
