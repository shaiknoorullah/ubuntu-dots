pragma ComponentBehavior: Bound

// WORKSPACES (top bar)  (mockup .ws — active = "N · name" accent pill, others
//                        = numbered chips: occupied brighter, empty dim)
// ============================================================================
// Reads native Hyprland (Quickshell.Hyprland via the Hypr singleton). Mirrors
// the mockup's left-pill workspace strip:
//
//   active     → an accent-tinted pill: a dot + "N · <window class>"
//   occupied   → a brighter numbered chip (mockup .ws b.has)
//   empty      → a dim numbered chip      (mockup .ws b)
//
// Clicking any chip dispatches `workspace <id>` (hyprctl). The active pill
// widens to fit the label and animates the morph (calm). Colours from Theme;
// the active accent follows the live context (Theme.ctxAccent).
//
// Occupancy: each workspace's raw IPC object carries `.windows` (count) — see
// caelestia services/Hypr.qml `lastIpcObject`.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.components
import qs.services

RowLayout {
    id: root

    required property ShellScreen screen

    readonly property int shown: 6

    // Map of workspace id -> window count (rebuilt reactively on Hypr refresh).
    readonly property var counts: {
        const m = {};
        for (const ws of Hypr.workspaces.values)
            m[ws.id] = ws.lastIpcObject?.windows ?? 0;
        return m;
    }

    spacing: 5

    Repeater {
        model: root.shown

        StyledRect {
            id: chip

            required property int index
            readonly property int ws: index + 1
            readonly property bool active: Hypr.activeWsId === ws
            readonly property int winCount: root.counts[ws] ?? 0
            readonly property bool occupied: winCount > 0

            // Active chip widens to show "N · <class>"; others are square-ish.
            implicitWidth: active
                ? activeRow.implicitWidth + 24
                : 22
            implicitHeight: 22
            radius: Theme.pill

            // StyledRect already cross-fades `color` (Behavior on color { CAnim }).
            color: active ? Theme.a18
                : occupied ? Theme.s2
                : Theme.s1
            border.width: active || occupied ? 1 : 0
            border.color: active ? Theme.withAlpha(Theme.ctxAccent, 0.46) : Theme.bd
            clip: true

            // Calm width morph as focus moves between workspaces.
            Behavior on implicitWidth {
                NumberAnimation {
                    duration: Theme.durBase
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.calmBezier.concat([1, 1])
                }
            }

            // Plain number for non-active chips (mockup .ws b text).
            StyledText {
                anchors.centerIn: parent
                visible: !chip.active
                text: `${chip.ws}`
                color: chip.occupied ? Theme.fg : Theme.comment
                font.family: Theme.fontMono
                font.pixelSize: 11
            }

            // Active pill content: dot + "N · <focused window class>".
            RowLayout {
                id: activeRow

                anchors.centerIn: parent
                visible: chip.active
                spacing: 7

                Rectangle {
                    Layout.preferredWidth: 7
                    Layout.preferredHeight: 7
                    radius: width / 2
                    color: Theme.ctxAccent
                }

                StyledText {
                    text: {
                        const cls = Hypr.activeToplevel?.lastIpcObject?.class ?? "";
                        return cls ? `${chip.ws} · ${cls}` : `${chip.ws}`;
                    }
                    color: Theme.fg
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    font.bold: true
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hypr.dispatch(`workspace ${chip.ws}`)
            }
        }
    }
}
