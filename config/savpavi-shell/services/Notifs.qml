pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Notification daemon (org.freedesktop.Notifications). Keeps history in the
// server's tracked list; `popups` is what is currently shown on screen.
// Only one daemon can own the bus name: while DMS runs, DMS keeps it.
Singleton {
    id: root

    readonly property bool dnd: ShellState.settings.dnd
    property var popups: []
    readonly property var history: server.trackedNotifications.values
    readonly property int count: history.length

    function dismissPopup(n) {
        popups = popups.filter(p => p !== n);
    }

    function clearAll() {
        for (const n of history.slice()) n.dismiss();
        popups = [];
    }

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true;
            if (!root.dnd || n.urgency === NotificationUrgency.Critical)
                root.popups = [n, ...root.popups].slice(0, 5);
            n.closed.connect(() => root.dismissPopup(n));
        }
    }
}
