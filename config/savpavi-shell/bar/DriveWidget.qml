import QtQuick
import Quickshell
import qs.common
import qs.services

// Google Drive: icon shows mount / upload / error state; dropdown shows the
// upload queue, folder syncs (dot-drive sync) and cache, opens the folder or
// the web UI, reconnects.
BarButton {
    id: root
    visible: ShellState.settings.showDrive && GDrive.ready
    padding: 6

    readonly property bool ok: GDrive.active && GDrive.mounted
    readonly property bool bad: !ok || GDrive.errored > 0 || GDrive.outOfSpace || GDrive.syncFailed

    function gb(b) { return (b / 1073741824).toFixed(b >= 10737418240 ? 0 : 1) + " GB"; }
    function progress(p) {
        if (!p || !p.totalBytes) return "hazırlanıyor…";
        const pct = Math.floor(100 * p.bytes / p.totalBytes);
        const eta = p.eta ? (p.eta >= 3600 ? Math.round(p.eta / 3600) + " sa" : Math.max(1, Math.round(p.eta / 60)) + " dk") : "";
        return "%" + pct + " · " + gb(p.bytes) + " / " + gb(p.totalBytes) + (eta ? " · ~" + eta : "");
    }
    function ago(t) {
        if (!t) return "henüz yok";
        const m = Math.round((Date.now() / 1000 - t) / 60);
        return m < 1 ? "az önce" : m < 60 ? m + " dk önce" : Math.round(m / 60) + " sa önce";
    }

    Row {
        spacing: 4
        anchors.verticalCenter: parent.verticalCenter

        Icon {
            name: !root.ok ? "cloud_off" : root.bad ? "sync_problem" : GDrive.busy ? "cloud_upload" : GDrive.syncing ? "cloud_sync" : "cloud_done"
            filled: root.ok && !root.bad
            color: root.bad ? Theme.error : GDrive.busy || GDrive.syncing ? Theme.primary : Theme.fgDim
            anchors.verticalCenter: parent.verticalCenter
        }
        Label {
            visible: GDrive.busy
            text: GDrive.pending
            font.pixelSize: Theme.fontSmall
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    onClicked: dd.toggle()

    Dropdown {
        id: dd
        anchorItem: root
        contentWidth: 300
        onVisibleChanged: if (visible) GDrive.refresh()

        Column {
            width: parent.width
            spacing: 4

            MenuItem {
                icon: root.ok ? "cloud_done" : "cloud_off"
                iconColor: root.ok ? Theme.primary : Theme.error
                text: root.ok ? "Google Drive bağlı" : "Google Drive bağlı değil"
                detail: root.ok ? "~/GoogleDrive" : "Yeniden bağlan"
                onClicked: { if (!root.ok) GDrive.run(["restart"]); else GDrive.run(["open"]); dd.close(); }
            }

            MenuItem {
                visible: root.ok
                icon: GDrive.busy ? "cloud_upload" : "task_alt"
                iconColor: GDrive.busy ? Theme.primary : Theme.fgDim
                text: GDrive.busy ? GDrive.uploading + " yükleniyor, " + GDrive.queued + " sırada" : "Yükleme kuyruğu boş"
                detail: GDrive.transferring.length ? GDrive.transferring[0] : ""
            }

            MenuItem {
                visible: GDrive.errored > 0 || GDrive.outOfSpace
                icon: "error"
                iconColor: Theme.error
                text: GDrive.outOfSpace ? "Önbellek için yer yok" : GDrive.errored + " dosya yüklenemedi"
                detail: "Log"
                onClicked: { Quickshell.execDetached(["xdg-open", Quickshell.env("HOME") + "/.cache/rclone/gdrive-mount.log"]); dd.close(); }
            }

            Repeater {
                model: GDrive.syncs
                // second line while running: file count
                delegate: Column {
                    required property var modelData
                    width: parent.width
                    spacing: 0
                    readonly property bool running: modelData.state === "running"
                    readonly property bool failed: modelData.state === "error"

                    MenuItem {
                        icon: parent.running ? "sync" : parent.failed ? "sync_problem" : "folder_supervised"
                        iconColor: parent.failed ? Theme.error : parent.running ? Theme.primary : Theme.fgDim
                        text: "Senkron: " + modelData.name + (parent.running ? (modelData.resync ? " (ilk eşitleme)" : " eşitleniyor") : "")
                        detail: parent.failed ? "Hata · tıkla: tekrar dene" : parent.running ? root.progress(modelData.progress) : root.ago(modelData.lastOk)
                        // click: sync now (after an error this retries)
                        onClicked: { GDrive.run(["sync-now"]); dd.close(); }
                    }
                    Label {
                        visible: parent.running && !!modelData.progress && modelData.progress.totalTransfers > 0
                        text: modelData.progress ? modelData.progress.transfers + " / " + modelData.progress.totalTransfers + " dosya" + (modelData.progress.errors ? " · " + modelData.progress.errors + " hata" : "") : ""
                        color: Theme.fgDim
                        font.pixelSize: Theme.fontSmall
                        leftPadding: 44
                        bottomPadding: 4
                    }
                    Label {
                        visible: parent.failed && modelData.error !== ""
                        width: parent.width
                        text: modelData.error
                        color: Theme.error
                        font.pixelSize: Theme.fontSmall
                        elide: Text.ElideMiddle
                        leftPadding: 44
                        rightPadding: 10
                        bottomPadding: 4
                    }
                }
            }

            MenuItem {
                visible: root.ok
                icon: "storage"
                iconColor: Theme.fgDim
                text: "Önbellek"
                detail: root.gb(GDrive.cacheBytes) + " / " + root.gb(GDrive.cacheMax)
            }

            MenuItem {
                icon: "folder_open"
                text: "Klasörü aç"
                onClicked: { GDrive.run(["open"]); dd.close(); }
            }

            MenuItem {
                icon: "open_in_browser"
                text: "Tarayıcıda aç"
                onClicked: { GDrive.run(["web"]); dd.close(); }
            }

            MenuItem {
                icon: "restart_alt"
                text: "Yeniden bağlan"
                onClicked: { GDrive.run(["restart"]); dd.close(); }
            }
        }
    }
}
