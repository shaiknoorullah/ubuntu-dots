pragma Singleton

// NOTIFICATIONS SINGLETON — live unread count for the top-bar bell badge
// (pattern: caelestia services/Notifs.qml — wraps a NotificationServer)
//
// `import Quickshell.Services.Notifications` provides a `NotificationServer`
// that registers on the session bus as the org.freedesktop.Notifications daemon
// and exposes `trackedNotifications` (an ObjectModel of live notifications).
// We surface just `.values.length` as `count`, which backs the red badge on the
// bell glyph in the right glass pill (mockup .badge "2").
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

    // Number of currently-tracked notifications (drives the badge).
    readonly property int count: server.trackedNotifications.values.length

    NotificationServer {
        id: server

        keepOnReload: false
        // Advertise the capabilities we can render; body/actions kept off since
        // the bar only shows a count. Expand when a popout panel is added.
        actionsSupported: false
        bodySupported: true
        imageSupported: true
    }
}
