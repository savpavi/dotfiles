import QtQuick
import qs.Commons

// Annotation surface.
//
// Committed strokes live in a plain JS array — that array is the single source
// of truth, which makes undo, redo and a full repaint after a resize trivial.
// The stroke currently under the mouse is painted on its own canvas so a long
// freehand line never forces a replay of the whole drawing on every mouse move.
Item {
  id: root

  property string tool: "pen" // "pen" | "arrow" | "rect"
  property color penColor: Color.foreground
  property int penWidth: 4

  // [{ tool, color, width, points: [{x, y}, ...] }]
  property var strokes: []
  property var redoStack: []
  property var activeStroke: null

  readonly property bool drawing: activeStroke !== null
  readonly property bool canUndo: strokes.length > 0
  readonly property bool canRedo: redoStack.length > 0
  readonly property bool empty: strokes.length === 0 && activeStroke === null

  // Freehand samples closer than this add points without adding detail.
  readonly property real minSampleDistance: 1.5
  // A press that never really moved is a misclick, not a stroke.
  readonly property real minStrokeExtent: 3

  function begin(x, y) {
    root.activeStroke = {
      tool: root.tool,
      color: String(root.penColor),
      width: root.penWidth,
      points: [{ x: x, y: y }, { x: x, y: y }]
    }
    live.requestPaint()
  }

  function extend(x, y) {
    if (!root.activeStroke) return
    var points = root.activeStroke.points
    if (root.activeStroke.tool === "pen") {
      var last = points[points.length - 1]
      if (Math.abs(last.x - x) + Math.abs(last.y - y) < root.minSampleDistance) return
      points.push({ x: x, y: y })
    } else {
      // Arrow and rectangle are two-point shapes: drag moves the end point.
      points[1] = { x: x, y: y }
    }
    live.requestPaint()
  }

  function commit() {
    if (!root.activeStroke) return
    var stroke = root.activeStroke
    root.activeStroke = null
    live.requestPaint()
    if (root.isDegenerate(stroke)) return

    root.strokes = root.strokes.concat([stroke])
    root.redoStack = []
    committed.requestPaint()
  }

  // Drop the in-progress stroke without committing it (overlay hidden, pointer
  // grab lost).
  function cancel() {
    if (!root.activeStroke) return
    root.activeStroke = null
    live.requestPaint()
  }

  function undo() {
    if (root.strokes.length === 0) return
    var remaining = root.strokes.slice(0, root.strokes.length - 1)
    var undone = root.strokes[root.strokes.length - 1]
    root.strokes = remaining
    root.redoStack = root.redoStack.concat([undone])
    committed.requestPaint()
  }

  function redo() {
    if (root.redoStack.length === 0) return
    var restored = root.redoStack[root.redoStack.length - 1]
    root.redoStack = root.redoStack.slice(0, root.redoStack.length - 1)
    root.strokes = root.strokes.concat([restored])
    committed.requestPaint()
  }

  function clear() {
    if (root.empty && root.redoStack.length === 0) return
    root.strokes = []
    root.redoStack = []
    root.activeStroke = null
    committed.requestPaint()
    live.requestPaint()
  }

  function isDegenerate(stroke) {
    var points = stroke.points
    if (!points || points.length < 2) return true
    if (stroke.tool === "pen") {
      var travelled = 0
      for (var i = 1; i < points.length; i++)
        travelled += Math.abs(points[i].x - points[i - 1].x) + Math.abs(points[i].y - points[i - 1].y)
      return travelled < root.minStrokeExtent
    }
    var first = points[0]
    var last = points[points.length - 1]
    return Math.abs(last.x - first.x) + Math.abs(last.y - first.y) < root.minStrokeExtent
  }

  function paintStroke(ctx, stroke) {
    var points = stroke.points
    if (!points || points.length < 2) return

    ctx.strokeStyle = stroke.color
    ctx.fillStyle = stroke.color
    ctx.lineWidth = stroke.width
    ctx.lineCap = "round"
    ctx.lineJoin = "round"

    if (stroke.tool === "rect") root.paintRect(ctx, points[0], points[points.length - 1])
    else if (stroke.tool === "arrow") root.paintArrow(ctx, stroke, points[0], points[points.length - 1])
    else root.paintPolyline(ctx, points)
  }

  function paintPolyline(ctx, points) {
    ctx.beginPath()
    ctx.moveTo(points[0].x, points[0].y)
    for (var i = 1; i < points.length; i++) ctx.lineTo(points[i].x, points[i].y)
    ctx.stroke()
  }

  function paintRect(ctx, from, to) {
    ctx.beginPath()
    ctx.rect(Math.min(from.x, to.x), Math.min(from.y, to.y),
             Math.abs(to.x - from.x), Math.abs(to.y - from.y))
    ctx.stroke()
  }

  function paintArrow(ctx, stroke, from, to) {
    var angle = Math.atan2(to.y - from.y, to.x - from.x)
    var head = Math.max(stroke.width * 3.5, 14)
    var spread = 0.42

    // Stop the shaft short of the tip so the round cap does not poke out
    // through the arrowhead.
    ctx.beginPath()
    ctx.moveTo(from.x, from.y)
    ctx.lineTo(to.x - Math.cos(angle) * head * 0.7, to.y - Math.sin(angle) * head * 0.7)
    ctx.stroke()

    ctx.beginPath()
    ctx.moveTo(to.x, to.y)
    ctx.lineTo(to.x - Math.cos(angle - spread) * head, to.y - Math.sin(angle - spread) * head)
    ctx.lineTo(to.x - Math.cos(angle + spread) * head, to.y - Math.sin(angle + spread) * head)
    ctx.closePath()
    ctx.fill()
  }

  Canvas {
    id: committed
    anchors.fill: parent

    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)
      for (var i = 0; i < root.strokes.length; i++) root.paintStroke(ctx, root.strokes[i])
    }

    // A resize hands back a blank buffer, so the drawing has to be replayed.
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
  }

  Canvas {
    id: live
    anchors.fill: parent

    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)
      if (root.activeStroke) root.paintStroke(ctx, root.activeStroke)
    }

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
  }
}
