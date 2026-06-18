pragma ComponentBehavior: Bound

// MEDIA WIDGET + ISLAND/NOTCH MORPH
// (pattern: caelestia modules/bar/popouts/Wrapper.qml morph + dashboard/media/Details.qml)
//
// Demonstrates the caelestia "island" morph idiom: a pill whose implicitWidth is
// driven by a state (collapsed -> expanded) and animated via `Behavior on
// implicitWidth { Anim {} }`. Caelestia animates implicitWidth/implicitHeight of
// a Wrapper Item exactly this way so the surrounding blob/background deforms to
// follow it. Hovering expands to reveal title + transport controls.
//
// MEDIA POSITION GOTCHA: MprisPlayer.position does not tick by itself. The
// repeating Timer below calls active.positionChanged() to force re-evaluation —
// this is the caelestia trick (dashboard/media/Details.qml lines 28-34).

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

StyledRect {
    id: root

    readonly property var player: Players.active
    readonly property bool hasPlayer: player !== null
    property bool expanded: false

    // The morph: collapsed pill vs expanded island.
    implicitWidth: !hasPlayer ? 0 : expanded ? 220 : 40
    implicitHeight: 32
    radius: height / 2
    color: Colours.palette.m3surfaceContainerHigh
    clip: true
    visible: hasPlayer

    // Animated width morph — the core island behaviour.
    Behavior on implicitWidth {
        Anim {
            type: Anim.Emphasized
        }
    }

    // Force MprisPlayer.position to update while playing.
    Timer {
        running: root.player?.isPlaying ?? false
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.player?.positionChanged()
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.expanded = true
        onExited: root.expanded = false
        onClicked: {
            if (root.player?.canTogglePlaying)
                root.player.togglePlaying();
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 8

        MaterialIcon {
            text: root.player?.isPlaying ? "pause" : "play_arrow"
            color: Colours.palette.m3primary
        }

        StyledText {
            Layout.fillWidth: true
            visible: root.expanded
            text: root.player ? `${root.player.trackTitle} — ${root.player.trackArtist}` : ""
            color: Colours.palette.m3onSurface
            elide: Text.ElideRight
            animate: true
            font.pixelSize: 12
        }
    }
}
