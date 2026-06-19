// VISUALIZER — data-driven spectrum bars (replaces Eq.qml).
// Bars grow UP AND DOWN from the vertical centre (the old Eq pinned the bottom,
// so it only grew up) AND distribute evenly across the FULL width of the item,
// so it reads as a real spectrum band rather than a stubby left-aligned dotted
// line. Bars are squared-off (small fixed radius), not pill-capped dots.
// Pure presentation: feed it `values` (array of magnitudes 0..1) and a size.

import QtQuick
import qs.services

Item {
    id: root

    property var values: []
    property int gap: 3
    property int maxH: 24
    property int minH: 3
    property real radius: 2
    property color color: Theme.green

    readonly property int count: root.values.length
    // Each bar gets an equal share of the width (min 2px so it never vanishes).
    readonly property real barW: root.count > 0
        ? Math.max(2, (root.width - (root.count - 1) * root.gap) / root.count)
        : 0

    implicitHeight: maxH

    Repeater {
        model: root.count

        Rectangle {
            id: bar
            required property int index

            width: root.barW
            x: index * (root.barW + root.gap)
            anchors.verticalCenter: parent.verticalCenter
            radius: root.radius
            color: root.color
            height: Math.max(root.minH, (root.values[bar.index] ?? 0) * root.maxH)

            Behavior on height {
                NumberAnimation { duration: 90; easing.type: Easing.OutSine }
            }
        }
    }
}
