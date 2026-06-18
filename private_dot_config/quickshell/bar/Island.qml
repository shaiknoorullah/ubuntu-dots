pragma ComponentBehavior: Bound

// DYNAMIC ISLAND / OLED NOTCH  (mockup #notch, states: collapsed -> .open)
// ============================================================================
// A pure-black notch carved into the centre of the top edge. It self-morphs:
//
//   collapsed (226 x 30)  →  circular art + live eq bars + truncated title
//   click                 →  morphs open (396 x 194) into:
//                              • a media player (big art, title/artist,
//                                scrub bar, prev / play-pause / next)
//                              • a live-activity row reading `adhd-focus.sh
//                                status` (deep-block · runway → next prayer)
//
// MORPH MECHANICS (caelestia island idiom): width/height are bound to `open`
// and animated by `Behavior on width/height { Anim { Emphasized } }`. Because
// the top edge sits at screen y=0, only the BOTTOM corners are visible, so a
// single `radius` reads as the carved `border-radius:0 0 R R` of the mockup.
// `clip:true` keeps the morphing children inside the rounded body. The two
// layers (mini / full) cross-fade on `open` via `Behavior on opacity`.
//
// DATA: media comes from the native MPRIS service (Players.active); the
// live-activity line comes from the Focus service (adhd-focus.sh status). All
// colour from the Theme singleton; the live-activity dot + accents follow the
// current context accent (Theme.ctxAccent).
//
// MOTION: calm. Width/height use the Emphasized curve (a soft settle, ~500ms);
// opacity/scrub use the standard curve. Nothing bounces aggressively — the
// mockup's spring is approximated by the Emphasized M3 bezier, not an overshoot.

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Widgets
import qs.components
import qs.services

Item {
    id: root

    // The notch is positioned by its parent (TopBar centres it on the top edge).
    // We expose implicitWidth/Height so the parent can centre us as we morph.
    implicitWidth: notch.width
    implicitHeight: notch.height

    // ---- State -------------------------------------------------------------
    // Dynamic-Island behaviour: hover to PEEK it open, click to PIN it open.
    // (open = hovered || pinned, so leaving collapses it unless pinned.)
    property bool pinned: false
    property bool hovered: false
    readonly property bool open: root.hovered || root.pinned

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

        // Carved corners: only the bottom shows (top edge is at screen y=0).
        radius: root.open ? 30 : 19

        // MORPH: collapsed 226x30, a touch wider on hover (244), open 396x194.
        width: root.open ? Theme.notchOpenW
            : root.hovered ? Theme.notchHoverW
            : Theme.notchW
        height: root.open ? Theme.notchOpenH : Theme.notchH

        // A barely-there border, top edge omitted (the carve sits flush).
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

        // Click toggles open; hover only nudges width while collapsed.
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: root.open ? Qt.ArrowCursor : Qt.PointingHandCursor
            onEntered: root.hovered = true
            onExited: root.hovered = false
            // Click the notch body to toggle. The transport buttons in the open
            // layer have their own child MouseAreas stacked ABOVE this one, so a
            // button press is consumed there and never reaches this handler
            // (Qt does not propagate to a parent MouseArea by default) — pressing
            // play/next therefore never collapses the island.
            onClicked: root.pinned = !root.pinned
        }

        // ===================================================================
        // COLLAPSED LAYER — art + eq + title  (mockup .mini)
        // ===================================================================
        RowLayout {
            id: mini

            anchors.centerIn: parent
            spacing: 9
            opacity: root.open ? 0 : 1
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.durFast
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.calmBezier.concat([1, 1])
                }
            }

            // Circular album art (mockup .mini .art — 17px circle).
            CoverArt {
                Layout.preferredWidth: 17
                Layout.preferredHeight: 17
                rad: 9   // ~circle
                source: root.player?.trackArtUrl ?? ""
            }

            // Live equaliser — five bars bouncing 5px..12px (mockup .mini .eq).
            Eq {
                Layout.preferredHeight: 12
                bars: 5
                playing: root.player?.isPlaying ?? false
            }

            // Truncated track title (mockup .mini .tk, max-width 128).
            StyledText {
                Layout.maximumWidth: 128
                text: root.player?.trackTitle ?? "—"
                color: Theme.withAlpha(Theme.fg, 0.8)
                font.family: Theme.fontMono
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }

        // ===================================================================
        // OPEN LAYER — media player + live-activity  (mockup .full)
        // ===================================================================
        ColumnLayout {
            id: full

            anchors.fill: parent
            anchors.topMargin: 17
            anchors.bottomMargin: 17
            anchors.leftMargin: 19
            anchors.rightMargin: 19
            spacing: 0
            opacity: root.open ? 1 : 0
            visible: opacity > 0

            // Fade in slightly after the body has begun expanding (mockup .full
            // transition-delay .1s).
            Behavior on opacity {
                NumberAnimation {
                    duration: 240
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.calmBezier.concat([1, 1])
                }
            }

            // ---- Row 1: big art + meta + live-activity (mockup .r1) --------
            RowLayout {
                Layout.fillWidth: true
                spacing: 13

                // 56px rounded album art (mockup .bigart).
                CoverArt {
                    Layout.preferredWidth: 56
                    Layout.preferredHeight: 56
                    rad: 13
                    source: root.player?.trackArtUrl ?? ""
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        Layout.fillWidth: true
                        text: root.player?.trackTitle ?? "Nothing playing"
                        color: Theme.fg
                        font.family: Theme.fontMono
                        font.pixelSize: 14
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: root.player?.trackArtist ?? ""
                        color: Theme.comment
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }

                    // LIVE-ACTIVITY PILL — reads adhd-focus.sh status (mockup
                    // .liveact "deep block · 1:47 → ʿAsr"). Tints to the live
                    // context accent.
                    Rectangle {
                        Layout.topMargin: 4
                        implicitWidth: liveRow.implicitWidth + 18
                        implicitHeight: liveRow.implicitHeight + 6
                        radius: height / 2
                        color: Theme.a12

                        RowLayout {
                            id: liveRow

                            anchors.centerIn: parent
                            spacing: 6

                            // Pulsing live dot (mockup .liveact .d, blink).
                            Rectangle {
                                Layout.preferredWidth: 5
                                Layout.preferredHeight: 5
                                radius: width / 2
                                color: Theme.ctxAccent

                                SequentialAnimation on opacity {
                                    running: true
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 0.25; duration: 700; easing.type: Easing.InOutSine }
                                    NumberAnimation { to: 1.0; duration: 700; easing.type: Easing.InOutSine }
                                }
                            }

                            StyledText {
                                // e.g. "block 47m → ʿAsr" / "idle → Dhuhr". We
                                // show the focus state + the prayer runway tail.
                                text: {
                                    const state = Focus.running
                                        ? `deep block · ${Focus.blockMinutes}m`
                                        : "idle";
                                    const next = Focus.nextPrayerName
                                        ? ` → ${Focus.nextPrayerName} ${Focus.nextPrayerTime}`
                                        : "";
                                    return state + next;
                                }
                                color: Theme.ctxAccent
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                            }
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }   // spacer

            // ---- Scrub bar (mockup .scrub: elapsed · track · length) -------
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8
                spacing: 9

                StyledText {
                    text: root.fmtTime(root.player?.position ?? 0)
                    color: Theme.comment
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                }

                // The track (mockup .trk) with a filled progress + knob.
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 4
                    radius: 2
                    color: Theme.withAlpha(Theme.fg, 0.12)

                    Rectangle {
                        id: progress

                        height: parent.height
                        radius: parent.radius
                        width: parent.width * root.progressFrac
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: Theme.purple }
                            GradientStop { position: 1.0; color: Theme.pink }
                        }

                        Behavior on width {
                            NumberAnimation {
                                duration: 400
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Theme.calmBezier.concat([1, 1])
                            }
                        }

                        // Knob at the playhead (mockup .trk i::after).
                        Rectangle {
                            width: 9
                            height: 9
                            radius: width / 2
                            color: Theme.fg
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: -4
                        }
                    }
                }

                StyledText {
                    text: root.fmtTime(root.player?.length ?? 0)
                    color: Theme.comment
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                }
            }

            // ---- Transport controls (mockup .ctrls) ------------------------
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 13
                Layout.alignment: Qt.AlignHCenter
                spacing: 24

                // Previous (Nerd Font 󰒮).
                IslandButton {
                    glyph: "\u{F04AE}"
                    enabled: root.player?.canGoPrevious ?? false
                    onClicked: root.player?.previous()
                }

                // Play / pause — filled circle (mockup .play).
                Rectangle {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    radius: width / 2
                    color: Theme.fg

                    StyledText {
                        anchors.centerIn: parent
                        // Nerd Font play / pause glyphs.
                        text: (root.player?.isPlaying ?? false) ? "\u{F03E4}" : "\u{F040A}"
                        color: Theme.oled
                        font.family: Theme.fontMono
                        font.pixelSize: 14
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: root.player?.canTogglePlaying ?? false
                        onClicked: root.player?.togglePlaying()
                    }
                }

                // Next (Nerd Font 󰒭).
                IslandButton {
                    glyph: "\u{F04AD}"
                    enabled: root.player?.canGoNext ?? false
                    onClicked: root.player?.next()
                }
            }
        }
    }

    // ---- Derived: scrub fraction ------------------------------------------
    readonly property real progressFrac: {
        const len = root.player?.length ?? 0;
        if (len <= 0)
            return 0;
        return Math.max(0, Math.min(1, (root.player?.position ?? 0) / len));
    }

    // MPRIS position does NOT self-tick — drive positionChanged() while playing
    // (the caelestia trick; without it the scrub bar freezes).
    Timer {
        running: (root.player?.isPlaying ?? false) && root.open
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.player?.positionChanged()
    }

    // ---- Helpers -----------------------------------------------------------
    function fmtTime(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds));
        const m = Math.floor(s / 60);
        const r = s % 60;
        return `${m}:${r < 10 ? "0" + r : r}`;
    }

    // Rounded album-cover tile: real MPRIS art, Dracula gradient as fallback
    // while it loads / when the player exposes none.
    component CoverArt: ClippingRectangle {
        id: cov
        property url source: ""
        property int rad: 13
        radius: rad
        color: "transparent"

        // Gradient placeholder (shows until the real art is Ready).
        Rectangle {
            anchors.fill: parent
            visible: art.status !== Image.Ready
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Theme.purple }
                GradientStop { position: 0.5; color: Theme.pink }
                GradientStop { position: 1.0; color: Theme.orange }
            }
        }

        Image {
            id: art
            anchors.fill: parent
            source: cov.source
            fillMode: Image.PreserveAspectCrop
            cache: true
            asynchronous: true
            sourceSize.width: width
            sourceSize.height: height
        }
    }

    // Small inline transport-button component (glyph + hover + clicked).
    component IslandButton: Item {
        property string glyph: ""
        property alias enabled: btnArea.enabled
        signal clicked

        implicitWidth: 22
        implicitHeight: 22

        StyledText {
            anchors.centerIn: parent
            text: parent.glyph
            color: parent.enabled ? Theme.fg : Theme.comment
            font.family: Theme.fontMono
            font.pixelSize: 16
        }

        MouseArea {
            id: btnArea
            anchors.fill: parent
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: parent.clicked()
        }
    }
}
