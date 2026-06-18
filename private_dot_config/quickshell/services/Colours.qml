pragma Singleton

// COLOURS SINGLETON  (pattern: caelestia services/Colours.qml)
//
// caelestia scaffold widgets (StyledRect/StyledText/MaterialIcon defaults)
// reference `Colours.palette.m3*` Material-3 token names. To keep that portable
// surface BUT drive every colour from the operator's Dracula palette, each M3
// token maps onto a `Theme.*` colour. Net effect: ONE source of truth
// (services/Theme.qml, mirroring .chezmoidata.yaml), no scattered hex, and the
// generic components render in Dracula colours unchanged.
//
// The Dracula-painted bottom/left bars use `Theme.*` directly; this Colours
// shim only exists so the imported caelestia components stay drop-in.
//
// Auto-registers as `Colours` by basename (pragma Singleton) — no qmldir.
// `import qs.services` exposes both Theme and Colours.

import QtQuick
import Quickshell
import qs.services

Singleton {
    id: root

    readonly property M3Palette palette: current
    readonly property M3Palette current: M3Palette {}
    readonly property bool light: false

    // Tint helper — delegates to Theme so there is one implementation.
    function alpha(c: color, a: real): color {
        return Theme.withAlpha(c, a);
    }

    // M3 token names mapped onto the Dracula palette in Theme.
    component M3Palette: QtObject {
        readonly property color m3background: Theme.bg
        readonly property color m3onBackground: Theme.fg
        readonly property color m3surface: Theme.base
        readonly property color m3surfaceContainerLow: Theme.surface0
        readonly property color m3surfaceContainer: Theme.surface0
        readonly property color m3surfaceContainerHigh: Theme.surface1
        readonly property color m3surfaceContainerHighest: Theme.surface2
        readonly property color m3onSurface: Theme.fg
        readonly property color m3onSurfaceVariant: Theme.subtext0
        readonly property color m3outline: Theme.comment
        readonly property color m3outlineVariant: Theme.surface2
        readonly property color m3shadow: "#000000"
        readonly property color m3scrim: "#000000"

        // Primary follows the live context accent (Ctx.accent); the rest derive.
        readonly property color m3primary: Ctx.accent
        readonly property color m3onPrimary: Theme.base
        readonly property color m3primaryContainer: Theme.surface1
        readonly property color m3onPrimaryContainer: Theme.fg

        readonly property color m3secondary: Theme.cyan
        readonly property color m3onSecondary: Theme.base
        readonly property color m3secondaryContainer: Theme.surface1
        readonly property color m3tertiary: Theme.purple
        readonly property color m3onTertiary: Theme.base
        readonly property color m3error: Theme.red
        readonly property color m3onError: Theme.base
    }
}
