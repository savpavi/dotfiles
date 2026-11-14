import QtQuick

// Shows one wallpaper and plays the change to the next one through
// shaders/wallfx.frag. Plain QtQuick on purpose, so it can be run outside the
// bar. Wallpaper.qml asks bin/dot-wallfx which transition and map to use.
Item {
    id: root

    property color ink: "white"      // the pen
    property color edge: "white"     // the bleeding front
    property real lineWidth: 1.6
    property int msSketch: 2600
    property int msSpread: 1500
    property int msFade: 450

    // Two images: the new one loads behind, the shader takes over for the
    // length of the change, then the roles swap.
    property bool frontIsA: true
    readonly property Image front: frontIsA ? a : b
    readonly property Image back: frontIsA ? b : a
    readonly property bool hasImage: front.source.toString() !== ""
    readonly property bool running: anim.running
    property real t: 0
    property int kind: 0             // 0 fade, 1 spread, 2 sketch
    property bool waiting: false

    function url(path) {
        return path ? "file://" + path.split("/").map(encodeURIComponent).join("/") : "";
    }

    // Without a transition: the first wallpaper, or while nobody can see it.
    function set(path) {
        stop();
        front.source = url(path);
    }

    function show(path, kindName, mapPath) {
        const u = url(path);
        stop();
        if (!hasImage || front.status !== Image.Ready) { front.source = u; return; }
        if (front.source.toString() === u) return;
        kind = mapPath && kindName === "sketch" ? 2 : mapPath && kindName === "spread" ? 1 : 0;
        map.source = kind ? url(mapPath) : "";
        back.source = u;
        waiting = true;
        check();
    }

    // Ends whatever is going on, on the image it was heading for.
    function stop() {
        if (anim.running) { anim.stop(); swap(); }
        waiting = false;
    }

    function swap() {
        frontIsA = !frontIsA;
        t = 0;
        back.source = "";
        map.source = "";
    }

    function check() {
        if (!waiting) return;
        if (back.status === Image.Error) { waiting = false; return; }
        if (kind && map.status === Image.Error) kind = 0;
        if (back.status !== Image.Ready || (kind && map.status !== Image.Ready)) return;
        waiting = false;
        anim.duration = kind === 2 ? msSketch : kind === 1 ? msSpread : msFade;
        anim.restart();
    }

    // `t` is time; the shader eases each of its phases itself.
    NumberAnimation {
        id: anim
        target: root; property: "t"; from: 0; to: 1
        easing.type: Easing.Linear
        onFinished: root.swap()
    }

    // The uv window of an image that covers this item, as PreserveAspectCrop shows it.
    function crop(img) {
        const iw = Math.max(img.implicitWidth, 1), ih = Math.max(img.implicitHeight, 1);
        const s = Math.max(width / iw, height / ih);
        const w = width / (iw * s), h = height / (ih * s);
        return Qt.vector4d((1 - w) / 2, (1 - h) / 2, w, h);
    }

    Image {
        id: a
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        sourceSize: Qt.size(root.width, root.height)
        visible: root.frontIsA && !anim.running
        onStatusChanged: root.check()
    }

    Image {
        id: b
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        sourceSize: Qt.size(root.width, root.height)
        visible: !root.frontIsA && !anim.running
        onStatusChanged: root.check()
    }

    // Numbers, not a picture: see bin/dot-wallfx for the channels.
    Image {
        id: map
        visible: false
        asynchronous: true
        cache: false
        smooth: true
        onStatusChanged: root.check()
    }

    ShaderEffect {
        anchors.fill: parent
        visible: anim.running
        property var oldTex: root.front
        property var newTex: root.back
        property var mapTex: map
        property real t: root.t
        property real mode: root.kind
        property size size: Qt.size(root.width, root.height)
        property vector4d cropOld: root.crop(root.front)
        property vector4d cropNew: root.crop(root.back)
        property real pxPerTexel: root.width / cropNew.z / Math.max(map.implicitWidth, 1)
        property real lineWidth: root.lineWidth
        property color ink: root.ink
        property color edge: root.edge
        fragmentShader: Qt.resolvedUrl("shaders/wallfx.frag.qsb")
    }
}
