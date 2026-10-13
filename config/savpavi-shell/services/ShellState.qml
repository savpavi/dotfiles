pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Shell-wide state. `settings` persists to ~/.config/savpavi-shell/settings.json
// (written whenever a value changes, re-read if the file is edited by hand).
Singleton {
    id: root

    readonly property alias settings: adapter
    // kept as a plain property for older call sites
    property alias idleInhibit: adapter.idleInhibit

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/savpavi-shell/settings.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        // first run: create the file with the defaults below
        onLoadFailed: error => { if (error === FileViewError.FileNotFound) writeAdapter(); }

        JsonAdapter {
            id: adapter

            // bar widgets
            property bool showMedia: true
            property bool showCava: true
            property bool showWeather: true
            property bool showStats: true
            property bool showClaude: true
            property bool showTailscale: true
            property bool showSend: true
            property bool showFocusedWindow: true
            property bool clockSeconds: false
            property bool barOnAllScreens: true

            // notifications
            property bool dnd: false
            property int popupSeconds: 6

            // system
            property bool idleInhibit: false
        }
    }
}
