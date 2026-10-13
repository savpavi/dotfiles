import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.common
import "Search.js" as S

// Spotlight-style launcher on the focused monitor.
//   text      apps (most used first on ties)
//   /text     files (dsearch index)
//   dig text  file contents (DigUp search server)
//   clipboard history (cliphist), opened with `ipc call launcher clipboard`
// Up/Down or Tab move, Enter opens, Ctrl+Enter opens a file's folder,
// Shift+Delete removes a clipboard entry, Esc closes.
PanelWindow {
    id: root

    property string query: ""
    property var results: []
    property int current: 0
    property var usage: ({})
    property bool busy: false
    property bool clip: false
    property var clipItems: []

    readonly property string mode: clip ? "clip" : query.startsWith("/") ? "files"
        : (query.startsWith("dig ") || query === "dig") ? "dig" : "apps"
    readonly property string term: mode === "files" ? query.slice(1).trim()
        : mode === "dig" ? query.slice(3).trim() : query.trim()
    readonly property string home: Quickshell.env("HOME")
    readonly property string usagePath: home + "/.local/state/savpavi-shell/launcher.json"
    readonly property string thumbDir: home + "/.cache/savpavi-shell/clip"

    function open(text) {
        clip = false;
        show(text);
    }

    function openClipboard() {
        clip = true;
        clipItems = [];
        show("");
        clipProc.running = true;
    }

    function show(text) {
        screen = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0];
        query = text ?? "";
        field.text = query;
        visible = true;
        field.forceActiveFocus();
        update();
    }

    function close() {
        visible = false;
        filesProc.running = false;
        digProc.running = false;
    }

    function toggle() { visible ? close() : open(""); }

    function update() {
        current = 0;
        if (mode === "clip") {
            const q = S.fold(term);
            const hits = q === "" ? clipItems : clipItems.filter(c => S.fold(c.title).includes(q));
            results = hits.length ? hits.slice(0, 60) : [{ icon: "content_paste_off", title: clipItems.length ? "Eşleşme yok" : "Pano boş", hint: true }];
        } else if (mode === "apps") {
            results = searchApps(term);
        } else if (term.length < 2) {
            results = [{ icon: mode === "files" ? "search" : "manage_search", title: mode === "files" ? "Dosya adı yaz" : "Ne arıyorsun?", subtitle: mode === "files" ? "dsearch dizini (~)" : "DigUp: belge, PDF, görsel, video ve ses içeriği", hint: true }];
        } else {
            debounce.restart();
        }
    }

    function searchApps(t) {
        const q = S.fold(t);
        const apps = DesktopEntries.applications.values.filter(a => !a.noDisplay);
        if (q === "") {
            return apps.filter(a => usage[a.id]).sort((a, b) => usage[b.id] - usage[a.id]).slice(0, 8).map(appItem);
        }
        const scored = [];
        for (const a of apps) {
            const s = Math.max(S.score(q, S.fold(a.name)) * 1.0,
                S.score(q, S.fold(a.genericName)) * 0.6,
                S.score(q, S.fold((a.keywords || []).join(" "))) * 0.5,
                S.score(q, S.fold(a.id)) * 0.4);
            if (s > 0) scored.push({ a, s: s + Math.min(usage[a.id] || 0, 50) * 3 });
        }
        return scored.sort((x, y) => y.s - x.s).slice(0, 40).map(x => appItem(x.a));
    }

    function appItem(a) {
        return { kind: "app", entry: a, appIcon: a.icon, title: a.name, subtitle: a.genericName || a.comment || "" };
    }

    function removeClip(item) {
        if (item?.kind !== "clip") return;
        Quickshell.execDetached(["sh", "-c", 'printf "%s\t%s\n" "$1" "$2" | cliphist delete', "_", item.id, item.raw]);
        clipItems = clipItems.filter(c => c.id !== item.id);
        const keep = current;
        update();
        current = Math.min(keep, results.length - 1);
    }

    function activate(item, alt) {
        if (!item || item.hint) return;
        if (item.kind === "clip") {
            Quickshell.execDetached(["sh", "-c", 'cliphist decode "$1" | wl-copy', "_", item.id]);
        } else if (item.kind === "app") {
            usage[item.entry.id] = (usage[item.entry.id] || 0) + 1;
            usageFile.setText(JSON.stringify(usage));
            // uwsm puts the app in its own systemd scope like the other launch paths
            Quickshell.execDetached(["uwsm", "app", "--", item.entry.id + ".desktop"]);
        } else if (item.kind === "file") {
            const target = alt ? item.path.slice(0, item.path.lastIndexOf("/")) : item.path;
            Quickshell.execDetached(["gio", "open", target]);
        } else if (item.kind === "dig") {
            const h = item.hit;
            if (alt)
                Quickshell.execDetached(["gio", "open", h.path.slice(0, h.path.lastIndexOf("/"))]);
            else
                Quickshell.execDetached([home + "/.local/bin/digup-launcher", "open", h.path, h.kind, h.page ? String(h.page) : "", (h.at !== null && h.at !== undefined) ? String(h.at) : ""]);
        }
        close();
    }

    function folderOf(path) {
        return path.slice(0, path.lastIndexOf("/")).replace(home, "~");
    }

    visible: false
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "savpavi-launcher"

    Timer {
        id: debounce
        interval: root.mode === "dig" ? 300 : 120
        onTriggered: {
            root.busy = true;
            if (root.mode === "files") {
                filesProc.running = false;
                filesProc.command = ["dsearch", "search", root.term, "--json", "-n", "30"];
                filesProc.running = true;
            } else {
                digProc.running = false;
                digProc.command = [root.home + "/.local/bin/digup-launcher", "query", root.term];
                digProc.running = true;
            }
        }
    }

    // cliphist list: "<id>\t<preview>", newest first. Images get a cached thumbnail.
    Process {
        id: clipProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const items = [];
                const images = [];
                for (const line of text.split("\n")) {
                    const tab = line.indexOf("\t");
                    if (tab < 0) continue;
                    const id = line.slice(0, tab), raw = line.slice(tab + 1);
                    const img = raw.startsWith("[[ binary data");
                    if (img && images.length < 40) images.push(id);
                    items.push({ kind: "clip", id, raw, icon: img ? "image" : "content_paste",
                        title: img ? "Görsel  " + (raw.match(/(\d+x\d+)/)?.[1] ?? "") : raw.replace(/\s+/g, " ").slice(0, 200),
                        thumb: "" });
                }
                root.clipItems = items;
                if (root.mode === "clip") root.update();
                if (images.length) {
                    thumbProc.ids = images;
                    thumbProc.command = ["sh", "-c", 'mkdir -p "$1"; d="$1"; shift; for id; do [ -s "$d/$id" ] || cliphist decode "$id" > "$d/$id"; done', "_", root.thumbDir, ...images];
                    thumbProc.running = true;
                }
            }
        }
    }

    Process {
        id: thumbProc
        property var ids: []
        // thumbnails exist now; point the rows at them so the images load
        onExited: {
            root.clipItems = root.clipItems.map(c => ids.includes(c.id) ? Object.assign({}, c, { thumb: "file://" + root.thumbDir + "/" + c.id }) : c);
            if (root.mode === "clip") {
                const keep = root.current;
                root.update();
                root.current = keep;
            }
        }
    }

    Process {
        id: filesProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.busy = false;
                if (root.mode !== "files") return;
                try {
                    const hits = JSON.parse(text).hits || [];
                    root.results = hits.length ? hits.map(h => ({ kind: "file", path: h.id, icon: S.fileIcon(h.id), title: h.id.split("/").pop(), subtitle: root.folderOf(h.id) }))
                        : [{ icon: "search_off", title: "Sonuç yok", subtitle: root.term, hint: true }];
                } catch (e) {
                    root.results = [{ icon: "error", title: "dsearch yanıt vermedi", subtitle: "systemctl --user status dsearch", hint: true }];
                }
            }
        }
    }

    Process {
        id: digProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.busy = false;
                if (root.mode !== "dig") return;
                const kinds = { doc: "description", pdf: "picture_as_pdf", image: "image", screenshot: "screenshot_monitor", video: "movie", audio: "music_note" };
                try {
                    const hits = JSON.parse(text);
                    root.results = hits.length ? hits.map(h => {
                        const where = h.page ? "s." + h.page + " · " : (h.at !== null && h.at !== undefined ? S.clock(h.at) + " · " : "");
                        const excerpt = h.excerpt ? " — " + h.excerpt.replace(/\s+/g, " ").slice(0, 110) : "";
                        return { kind: "dig", hit: h, path: h.path, icon: kinds[h.kind] || "draft", title: h.path.split("/").pop(), subtitle: where + root.folderOf(h.path) + excerpt };
                    }) : [{ icon: "search_off", title: "Sonuç yok", subtitle: root.term, hint: true }];
                } catch (e) {
                    root.results = [{ icon: "error", title: "DigUp yanıt vermedi", subtitle: "systemctl --user status digup-search", hint: true }];
                }
            }
        }
    }

    FileView {
        id: usageFile
        path: root.usagePath
        printErrors: false
        watchChanges: true                // reset from the settings window
        onFileChanged: reload()
        atomicWrites: true
        onLoaded: {
            try { root.usage = JSON.parse(text()); } catch (e) {}
        }
    }

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", home + "/.local/state/savpavi-shell"])

    // click outside closes
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        id: panel
        width: 640
        height: column.implicitHeight + 16
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.2
        radius: Theme.radius + 4
        color: Theme.bg
        border.width: 1
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.3)

        // swallow clicks so they don't reach the close area
        MouseArea { anchors.fill: parent }

        Column {
            id: column
            x: 8
            y: 8
            width: parent.width - 16
            spacing: 6

            // search field
            Rectangle {
                width: parent.width
                height: 46
                radius: Theme.radius
                color: Theme.bgAlt

                Icon {
                    id: searchIcon
                    name: root.mode === "clip" ? "content_paste" : root.mode === "files" ? "folder_open" : root.mode === "dig" ? "manage_search" : "search"
                    size: 22
                    color: Theme.primary
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                }

                TextInput {
                    id: field
                    anchors.left: searchIcon.right
                    anchors.leftMargin: 12
                    anchors.right: modeChip.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.fg
                    font.family: Theme.sans
                    font.pixelSize: 17
                    selectionColor: Theme.primaryContainer
                    clip: true

                    onTextChanged: { root.query = text; root.update(); }

                    Label {
                        visible: field.text === ""
                        text: root.clip ? "Panoda ara…   Shift+Del siler" : "Ara…   /dosya   dig içerik"
                        color: Theme.fgDim
                        font.pixelSize: 17
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Keys.onPressed: e => {
                        const n = root.results.length;
                        if (e.key === Qt.Key_Escape) { root.close(); e.accepted = true; }
                        else if (e.key === Qt.Key_Down || (e.key === Qt.Key_Tab && !(e.modifiers & Qt.ShiftModifier))) { root.current = n ? (root.current + 1) % n : 0; e.accepted = true; }
                        else if (e.key === Qt.Key_Up || e.key === Qt.Key_Backtab) { root.current = n ? (root.current - 1 + n) % n : 0; e.accepted = true; }
                        else if (e.key === Qt.Key_Delete && (e.modifiers & Qt.ShiftModifier)) { root.removeClip(root.results[root.current]); e.accepted = true; }
                        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { root.activate(root.results[root.current], e.modifiers & Qt.ControlModifier); e.accepted = true; }
                    }
                }

                Rectangle {
                    id: modeChip
                    visible: root.mode !== "apps"
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: chipText.implicitWidth + 16
                    height: 24
                    radius: 12
                    color: Theme.primaryContainer
                    Label {
                        id: chipText
                        anchors.centerIn: parent
                        text: (root.mode === "clip" ? "Pano" : root.mode === "files" ? "Dosyalar" : "DigUp") + (root.busy ? " …" : "")
                        font.pixelSize: Theme.fontSmall
                    }
                }
            }

            ListView {
                id: list
                width: parent.width
                height: Math.min(contentHeight, 8 * 50)
                visible: count > 0
                clip: true
                model: root.results
                currentIndex: root.current
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: 0

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool selected: index === root.current

                    width: list.width
                    height: 50
                    radius: Theme.radiusSmall
                    color: selected ? Theme.primaryContainer : (mouse.containsMouse ? Theme.bgHighest : "transparent")

                    Item {
                        id: iconBox
                        width: 28
                        height: 28
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter

                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: 28
                            visible: row.modelData.kind === "app"
                            source: row.modelData.kind === "app" ? Quickshell.iconPath(row.modelData.appIcon, "application-x-executable") : ""
                        }

                        Image {
                            id: thumb
                            anchors.fill: parent
                            visible: status === Image.Ready
                            source: row.modelData.thumb ?? ""
                            sourceSize: Qt.size(56, 56)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: false
                        }

                        Icon {
                            anchors.centerIn: parent
                            visible: row.modelData.kind !== "app" && !thumb.visible
                            name: row.modelData.icon ?? ""
                            size: 22
                            color: row.modelData.hint ? Theme.fgDim : Theme.primary
                        }
                    }

                    Column {
                        anchors.left: iconBox.right
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Label {
                            width: parent.width
                            text: row.modelData.title
                            font.weight: row.selected ? Font.DemiBold : Font.Normal
                        }
                        Label {
                            width: parent.width
                            visible: text !== ""
                            text: row.modelData.subtitle ?? ""
                            color: Theme.fgDim
                            font.pixelSize: Theme.fontSmall
                        }
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activate(row.modelData, false)
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.toggle(); }
        function open(text: string): void { root.open(text); }
        function clipboard(): void { root.visible && root.clip ? root.close() : root.openClipboard(); }
    }
}
