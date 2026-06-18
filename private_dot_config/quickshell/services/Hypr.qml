pragma Singleton

// HYPRLAND SINGLETON  (pattern: caelestia services/Hypr.qml)
//
// Thin wrapper over Quickshell.Hyprland that exposes reactive lists/objects.
// KEY APIs (all from `import Quickshell.Hyprland`):
//   Hyprland.workspaces        -> ObjectModel; iterate `.values`
//   Hyprland.toplevels         -> ObjectModel of windows; `.values`
//   Hyprland.monitors          -> `.values`
//   Hyprland.focusedWorkspace  -> HyprlandWorkspace (has .id, .name)
//   Hyprland.activeToplevel    -> HyprlandToplevel (active window; has .title, .lastIpcObject)
//   Hyprland.focusedMonitor    -> HyprlandMonitor
//   Hyprland.monitorFor(screen)-> HyprlandMonitor for a ShellScreen
//   Hyprland.dispatch("...")   -> run a hyprctl dispatcher
//   Hyprland.refreshWorkspaces()/refreshToplevels()/refreshMonitors()
//   Each object's `.lastIpcObject` is the raw JSON (e.g. .windows count, .fullscreen)
//
// Workspaces/toplevels are NOT auto-updated for every event — caelestia listens
// to Hyprland.rawEvent and calls refresh* explicitly (replicated below).

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    readonly property var workspaces: Hyprland.workspaces
    readonly property var toplevels: Hyprland.toplevels
    readonly property var monitors: Hyprland.monitors

    readonly property HyprlandWorkspace focusedWorkspace: Hyprland.focusedWorkspace
    readonly property HyprlandMonitor focusedMonitor: Hyprland.focusedMonitor
    readonly property HyprlandToplevel activeToplevel: Hyprland.activeToplevel
    readonly property int activeWsId: focusedWorkspace?.id ?? 1

    function dispatch(request: string): void {
        Hyprland.dispatch(request);
    }

    function monitorFor(screen: ShellScreen): HyprlandMonitor {
        return Hyprland.monitorFor(screen);
    }

    // Caelestia refreshes models in response to raw IPC events. Without this,
    // window counts / workspace occupancy can go stale.
    Connections {
        target: Hyprland

        function onRawEvent(event: HyprlandEvent): void {
            const n = event.name;
            if (n.endsWith("v2"))
                return;

            if (["workspace", "moveworkspace", "activespecial", "focusedmon"].includes(n)) {
                Hyprland.refreshWorkspaces();
                Hyprland.refreshMonitors();
            } else if (["openwindow", "closewindow", "movewindow"].includes(n)) {
                Hyprland.refreshToplevels();
                Hyprland.refreshWorkspaces();
            } else if (n.includes("mon")) {
                Hyprland.refreshMonitors();
            } else if (n.includes("workspace")) {
                Hyprland.refreshWorkspaces();
            } else if (n.includes("window") || ["pin", "fullscreen", "changefloatingmode"].includes(n)) {
                Hyprland.refreshToplevels();
            }
        }
    }
}
