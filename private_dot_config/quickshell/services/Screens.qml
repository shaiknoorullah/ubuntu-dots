pragma Singleton

// SCREENS SINGLETON  (pattern: caelestia services/Screens.qml)
//
// `Quickshell.screens` is the list of all ShellScreen objects. Wrap it so the
// bar's Variants model can be filtered (e.g. exclude a monitor by name) in one
// place. The bar binds `model: Screens.screens` to spawn one panel per output.

import Quickshell

Singleton {
    id: root

    // Filter here if you want to exclude monitors, e.g.
    //   .filter(s => s.name !== "HDMI-A-1")
    readonly property list<ShellScreen> screens: Quickshell.screens
}
