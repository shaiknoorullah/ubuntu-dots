pragma ComponentBehavior: Bound

// BAR WINDOW  (pattern: caelestia StyledWindow + Exclusions)
//
// The actual layer-shell surface for ONE monitor. Anchoring top+left+right pins
// it as a top edge that stretches full-width. `exclusiveZone` reserves the bar's
// height so tiled windows sit below it. In caelestia the exclusion is a separate
// zero-size window (Exclusions.qml) because the bar can morph/hide; for a static
// always-on bar, setting exclusiveZone directly on the PanelWindow is simplest.

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.services

StyledWindow {
    id: root

    required property ShellScreen modelData

    screen: modelData
    name: "bar"

    // Layer-shell anchoring: pin to the top edge, stretch horizontally.
    anchors.top: true
    anchors.left: true
    anchors.right: true

    implicitHeight: bar.implicitHeight
    // Reserve space so windows don't render under the bar.
    exclusiveZone: bar.implicitHeight

    // Optional translucent background bar surface.
    StyledRect {
        anchors.fill: parent
        color: Colours.alpha(Colours.palette.m3surface, 0.85)
    }

    Bar {
        id: bar

        anchors.fill: parent
        screen: root.modelData
    }
}
