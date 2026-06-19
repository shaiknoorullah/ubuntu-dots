pragma Singleton

// CAFFEINE SINGLETON — Wayland idle inhibitor for the right panel.

import Quickshell
import Quickshell.Wayland

Singleton {
    id: root

    property alias enabled: inhibitor.enabled

    function toggle(): void {
        root.enabled = !root.enabled;
    }

    IdleInhibitor {
        id: inhibitor

        enabled: false
        window: PanelWindow {
            implicitWidth: 0
            implicitHeight: 0
            color: "transparent"
            anchors.right: true
            anchors.bottom: true
            mask: Region {
                item: null
            }
        }
    }
}
