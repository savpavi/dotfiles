import QtQuick
import QtQuick.Shapes
import qs.Commons

// Dims everything except a circle around the pointer.
//
// The scrim and its hole are a single filled path with the odd-even fill rule,
// so following the cursor is a scene-graph transform rather than a full-screen
// repaint — a Canvas-based hole would stutter at 4K.
Item {
  id: root

  property real centerX: 0
  property real centerY: 0
  property real radius: 180

  // Themes carry a menu scrim already; reusing it keeps the overlay's dimming
  // consistent with every other Omarchy overlay.
  property color scrimColor: Util.alpha(Color.menu.scrim, 0.82)

  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      fillColor: root.scrimColor
      strokeColor: "transparent"
      strokeWidth: 0
      fillRule: ShapePath.OddEvenFill

      // Screen rectangle, clockwise.
      PathMove { x: 0; y: 0 }
      PathLine { x: root.width; y: 0 }
      PathLine { x: root.width; y: root.height }
      PathLine { x: 0; y: root.height }
      PathLine { x: 0; y: 0 }

      // The hole. The odd-even fill rule on the path above is what cuts it
      // out; the winding does not matter.
      //
      // Swept positive on purpose: PathAngleArc contributes nothing at all
      // for a sweepAngle of exactly -360, which left the scrim solid and the
      // spotlight looking like a plain screen dimmer.
      PathAngleArc {
        centerX: root.centerX
        centerY: root.centerY
        radiusX: root.radius
        radiusY: root.radius
        startAngle: 0
        sweepAngle: 360
        moveToStart: true
      }
    }
  }

  Behavior on radius {
    NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
  }
}
