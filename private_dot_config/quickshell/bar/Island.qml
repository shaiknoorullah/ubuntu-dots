pragma ComponentBehavior: Bound

// DYNAMIC ISLAND / OLED NOTCH  (mockup #notch, states: collapsed -> .open)
// ============================================================================
// A pure-black notch carved into the centre of the top edge. It self-morphs:
//
//   collapsed (content-driven width, 32px tall)
//     → art+ring (progress) · title · cava bars ⇄ prev/play/next on hover
//   click → morphs open (460 x 210) into FullPlayer:
//                              • blurred art backdrop
//                              • big art, title/artist·album, live-activity pill
//                              • full-width mirrored cava band
//                              • seekable scrub · shuffle/prev/play/next/repeat
//
// INTERACTION MODEL (Task 7): hover only reveals MiniPlayer's inline
// prev/play/next controls (the island stays collapsed); a click PINS
// FullPlayer open. `open` = `pinned` only — hover no longer auto-expands.
//
// DATA: media from MPRIS (Players.active); live-activity from Focus service.
// All colour from Theme; live-activity dot + accents follow Theme.ctxAccent.
//
// MOTION: calm settle. Width/height use the Emphasized curve (~500ms); opacity
// uses the standard curve. Nothing bounces aggressively.

import QtQuick
import Quickshell.Services.Mpris
import qs.components
import qs.services
import qs.bar.components

Item {
    id: root

    // The notch is positioned by its parent (TopBar centres it on the top edge).
    implicitWidth: notch.width
    implicitHeight: notch.height

    // ---- State -------------------------------------------------------------
    // Click PINS the full player open; hover only reveals inline mini controls.
    property bool pinned: false
    property bool hovered: false
    readonly property bool open: root.pinned

    readonly property MprisPlayer player: Players.active
    readonly property bool hasPlayer: player !== null

    // Un-pin the island if the player disappears while open.
    onHasPlayerChanged: if (!hasPlayer) root.pinned = false

    // ---- The carved OLED body ---------------------------------------------
    Rectangle {
        id: notch

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        color: Theme.oled
        clip: true

        // Fully-rounded floating pill; widens its radius when open.
        radius: root.open ? 30 : 19

        // MORPH: collapsed = content-driven (mini.implicitWidth + 28px padding,
        //        clamped to 460), open = fixed Theme.notchOpenW.
        //        Hover no longer changes width — the crossfade is in-place.
        width: root.open ? Theme.notchOpenW
            : Math.min(mini.implicitWidth + 28, 460)
        height: root.open ? Theme.notchOpenH : Theme.notchH

        // A barely-there border around the floating body.
        border.width: 1
        border.color: Theme.oledBorder

        // Calm spring-ish settle on the morph (Emphasized M3 curve).
        Behavior on width {
            NumberAnimation {
                duration: Theme.durSlow
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.34, 1.42, 0.5, 1, 1, 1]
            }
        }
        Behavior on height {
            NumberAnimation {
                duration: Theme.durSlow
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.34, 1.42, 0.5, 1, 1, 1]
            }
        }
        Behavior on radius {
            NumberAnimation {
                duration: Theme.durBase
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.calmBezier.concat([1, 1])
            }
        }

        // Click toggles pinned; hover tracks pointer for mini controls.
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: root.open ? Qt.ArrowCursor : Qt.PointingHandCursor
            onEntered: root.hovered = true
            onExited: root.hovered = false
            // Transport buttons in the open layer have child MouseAreas stacked
            // ABOVE this one, so a button press never reaches this handler.
            onClicked: root.pinned = !root.pinned
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: root.open ? Theme.withAlpha(Theme.ctxAccent, 0.34) : Theme.oledBorder

            Behavior on color {
                CAnim {}
            }
        }

        // ===================================================================
        // COLLAPSED LAYER — MiniPlayer (art+ring · title · cava⇄transport)
        // ===================================================================
        MiniPlayer {
            id: mini
            anchors.centerIn: parent
            player: root.player
            hovered: root.hovered
            opacity: root.open ? 0 : 1
            visible: opacity > 0
            Behavior on opacity {
                NumberAnimation { duration: Theme.durFast; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.calmBezier.concat([1, 1]) }
            }
        }

        // ===================================================================
        // OPEN LAYER — FullPlayer (blurred backdrop + full media controls)
        // ===================================================================
        FullPlayer {
            id: full
            anchors.fill: parent
            anchors.margins: 0
            player: root.player
            opacity: root.open ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.calmBezier.concat([1, 1]) } }
        }
    }

    // MPRIS position does NOT self-tick — drive positionChanged() on every
    // playback tick (the caelestia trick). Runs whenever audio plays regardless
    // of open state so the collapsed ProgressRing also advances.
    Timer {
        running: root.player?.isPlaying ?? false
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.player?.positionChanged()
    }

    // Run the cava capture only while audio is actively playing.
    Binding {
        target: Cava
        property: "enabled"
        value: root.hasPlayer && (root.player?.isPlaying ?? false)
    }
}
