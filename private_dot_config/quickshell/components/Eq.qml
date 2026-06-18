// LIVE EQUALISER — bouncing audio bars  (mockup .eq / @keyframes eq)
// ============================================================================
// A row of thin bars that bounce between a low and high height while audio is
// playing (mockup: 5px..12px, staggered delays). When `playing` is false the
// bars settle to their resting height — calm, not frozen mid-bounce.
//
// Each bar runs its own SequentialAnimation on `height` with a per-bar delay so
// the row ripples rather than pulsing in unison (mockup nth-child delays). Bars
// are green by default (mockup --green) but `color` is overridable.
//
// Pure presentation — no data binding beyond `playing`. Used by the Dynamic
// Island mini layer and the now-playing strips.

import QtQuick
import qs.services

Row {
    id: root

    property int bars: 5
    property bool playing: true
    property color color: Theme.green
    property int minH: 5
    property int maxH: 12
    property int barWidth: 2

    spacing: 2
    // Bars are bottom-aligned so they grow upward (mockup align-items:flex-end).
    height: maxH

    Repeater {
        model: root.bars

        Rectangle {
            id: bar

            required property int index

            width: root.barWidth
            radius: 1
            color: root.color
            anchors.bottom: parent.bottom
            height: root.playing ? root.maxH : root.minH

            // Bounce while playing; staggered start per bar so the row ripples.
            SequentialAnimation on height {
                running: root.playing
                loops: Animation.Infinite
                // Per-bar phase offset (mockup animation-delay).
                PauseAnimation { duration: bar.index * 90 }
                NumberAnimation {
                    to: root.minH
                    duration: 500
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: root.maxH
                    duration: 500
                    easing.type: Easing.InOutSine
                }
            }

            // Settle calmly to rest height when playback stops.
            Behavior on height {
                enabled: !root.playing
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
