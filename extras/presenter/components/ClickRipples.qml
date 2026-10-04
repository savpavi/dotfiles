import QtQuick
import qs.Commons

// Expanding ring at every mouse press, so a screencast audience can see where
// the presenter actually clicked.
//
// Rings are created on demand and free themselves when the animation ends;
// there is never more than a handful alive at once.
Item {
  id: root

  property color rippleColor: Color.accent
  property real startRadius: 8
  property real endRadius: 46
  property int duration: 420

  function spawn(x, y) {
    ring.createObject(root, { originX: x, originY: y })
  }

  Component {
    id: ring

    Rectangle {
      id: ripple

      property real originX: 0
      property real originY: 0
      property real currentRadius: root.startRadius

      x: originX - currentRadius
      y: originY - currentRadius
      width: currentRadius * 2
      height: currentRadius * 2
      radius: currentRadius
      color: "transparent"
      border.width: Math.max(2, root.startRadius / 3)
      border.color: root.rippleColor

      ParallelAnimation {
        running: true

        NumberAnimation {
          target: ripple
          property: "currentRadius"
          from: root.startRadius
          to: root.endRadius
          duration: root.duration
          easing.type: Easing.OutCubic
        }

        NumberAnimation {
          target: ripple
          property: "opacity"
          from: 0.9
          to: 0
          duration: root.duration
          easing.type: Easing.InQuad
        }

        onFinished: ripple.destroy()
      }
    }
  }
}
