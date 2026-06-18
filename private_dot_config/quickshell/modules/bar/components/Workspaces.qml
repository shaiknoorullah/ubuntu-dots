pragma ComponentBehavior: Bound

// WORKSPACES WIDGET  (pattern: caelestia modules/bar/components/workspaces/*)
//
// Reads Hypr.workspaces / Hypr.activeWsId. Occupancy comes from each workspace's
// raw IPC object: `ws.lastIpcObject.windows > 0`. Clicking dispatches
// `workspace <id>`. Caelestia draws a fixed number of slots (config.shown) and
// computes which group is visible; here we show a fixed 5 for clarity.

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

StyledRect {
    id: root

    required property ShellScreen screen

    readonly property int shown: 5
    // Map of workspace id -> occupied(bool), rebuilt reactively.
    readonly property var occupied: {
        const occ = {};
        for (const ws of Hypr.workspaces.values)
            occ[ws.id] = ws.lastIpcObject.windows > 0;
        return occ;
    }

    implicitWidth: layout.implicitWidth + 12
    implicitHeight: layout.implicitHeight + 6
    radius: height / 2
    color: Colours.palette.m3surfaceContainer

    RowLayout {
        id: layout

        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: root.shown

            StyledRect {
                id: dot

                required property int index
                readonly property int ws: index + 1
                readonly property bool active: Hypr.activeWsId === ws
                readonly property bool isOccupied: root.occupied[ws] ?? false

                implicitWidth: active ? 22 : 10
                implicitHeight: 10
                radius: height / 2
                color: active ? Colours.palette.m3primary
                    : isOccupied ? Colours.palette.m3onSurfaceVariant
                    : Colours.palette.m3outlineVariant

                // Smooth width morph when the active workspace changes.
                Behavior on implicitWidth {
                    Anim {}
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Hypr.dispatch(`hl.dsp.focus({ workspace = ${dot.ws} })`)
                }
            }
        }
    }
}
