//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1

import QtQuick
import Quickshell
import Quickshell.Io
import qs.bar
import qs.keybinds
import qs.launcher
import qs.lock
import qs.notifications
import qs.osd
import qs.services
import qs.session
import qs.settings
import qs.wallpaper

// savpavi-shell: Ege's own Quickshell desktop shell.
// Run: qs -p ~/dotfiles/config/savpavi-shell
ShellRoot {
    id: root

    property bool barVisible: true

    Variants {
        model: Quickshell.screens
        Wallpaper {}
    }

    Variants {
        model: !root.barVisible ? [] : ShellState.settings.barOnAllScreens ? Quickshell.screens
            : Quickshell.screens.filter(s => s.name === "DP-1")
        Bar {}
    }

    Launcher {}
    Lock {}
    Popups {}
    Osd {}
    Session {}
    Keybinds {}
    Settings {}
    Picker {}

    // qs -p <dir> ipc call bar toggle
    IpcHandler {
        target: "bar"
        function toggle(): void { root.barVisible = !root.barVisible; }
    }
}
