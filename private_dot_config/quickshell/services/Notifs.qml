pragma Singleton

// NOTIFICATIONS SINGLETON — live unread count for the top-bar bell badge
// (pattern: caelestia services/Notifs.qml — wraps a NotificationServer)
//
// `import Quickshell.Services.Notifications` provides a `NotificationServer`
// that registers on the session bus as the org.freedesktop.Notifications daemon
// and exposes `trackedNotifications` (an ObjectModel of live notifications).
// We surface just `.values.length` as `count`, which backs the red badge on the
// Material Symbols notification icon in the right glass pill.
//
// IMPORTANT: only ONE process may own the org.freedesktop.Notifications name. If
// a separate daemon (dunst/mako/swaync) is already running, this server will not
// receive notifications and `count` will stay 0 — that is the calm fallback and
// not an error. If quickshell IS your notification daemon, this populates live.
//
// `keepOnReload: false` lets notifications clear across a hot reload rather than
// stacking duplicates (caelestia sets this on its server).

import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property bool silent: false
    property var items: []

    // Number of remembered notifications (drives the badge when Quickshell owns
    // org.freedesktop.Notifications). If dunst owns the bus, SystemNotifs uses
    // dunstctl instead and this calmly stays empty.
    readonly property int count: root.items.length

    function _timeText(ms: real): string {
        const elapsed = Math.max(0, Date.now() - ms) / 1000;
        if (elapsed < 60)
            return "now";
        if (elapsed < 3600)
            return `${Math.floor(elapsed / 60)}m`;
        if (elapsed < 86400)
            return `${Math.floor(elapsed / 3600)}h`;
        return `${Math.floor(elapsed / 86400)}d`;
    }

    function dismiss(id: int): void {
        root.items = root.items.filter(n => n.id !== id);
        for (const notif of server.trackedNotifications.values) {
            if (notif.id === id) {
                notif.dismiss();
                break;
            }
        }
    }

    function clear(): void {
        for (const notif of server.trackedNotifications.values)
            notif.dismiss();
        root.items = [];
    }

    function toggleSilent(): void {
        root.silent = !root.silent;
    }

    NotificationServer {
        id: server

        keepOnReload: false
        // Advertise the capabilities the right panel can render.
        actionsSupported: false
        bodySupported: true
        imageSupported: true

        onNotification: notification => {
            notification.tracked = true;

            const now = Date.now();
            const item = {
                id: notification.id,
                app: notification.appName || notification.appIcon || "Notification",
                summary: notification.summary || "",
                body: (notification.body || "").replace(/\n/g, " ").slice(0, 180),
                time: root._timeText(now),
                timestamp: now
            };

            root.items = [item].concat(root.items).slice(0, 30);
        }
    }
}
