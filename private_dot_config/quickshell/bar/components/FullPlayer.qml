// FULL PLAYER — expanded island layer (click-pinned).
// blurred art backdrop · [art | title/artist/album | live-activity pill]
// · full-width mirrored cava band · seekable scrub · transport+shuffle/repeat.

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Services.Mpris
import qs.components
import qs.services

Item {
    id: root

    property var player: null

    // ---- Blurred album-art backdrop (art-driven ambiance) -------------------
    Image {
        id: backdropSrc
        anchors.fill: parent
        source: root.player?.trackArtUrl ?? ""
        fillMode: Image.PreserveAspectCrop
        visible: false
        asynchronous: true
        cache: true
    }
    MultiEffect {
        anchors.fill: parent
        source: backdropSrc
        blurEnabled: true
        blur: 1.0
        blurMax: 48
        opacity: backdropSrc.status === Image.Ready ? 0.18 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.durBase } }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 16
        anchors.bottomMargin: 14
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        spacing: 0

        // ---- Row 1: art + meta + live-activity ------------------------------
        RowLayout {
            Layout.fillWidth: true
            spacing: 13

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
                    text: {
                        const a = root.player?.trackArtist ?? "";
                        const al = root.player?.trackAlbum ?? "";
                        return al ? `${a} · ${al}` : a;
                    }
                    color: Theme.comment
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }

                // Live-activity pill (focus/salah) — kept from the old design.
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
                            text: {
                                const state = Focus.running ? `deep block · ${Focus.blockMinutes}m` : "idle";
                                const next = Focus.nextPrayerName ? ` → ${Focus.nextPrayerName} ${Focus.nextPrayerTime}` : "";
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

        // ---- Full-width spectrum band — the centerpiece. It fills the vertical
        // slack between the meta row and the scrub so there's no dead void.
        Visualizer {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 12
            Layout.bottomMargin: 4
            values: Cava.values
            gap: 3
            maxH: 56
            minH: 3
            radius: 2
            color: Theme.ctxAccent
        }

        // ---- Seekable scrub -------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 6
            spacing: 9

            StyledText {
                text: root.fmtTime(root.player?.position ?? 0)
                color: Theme.comment
                font.family: Theme.fontMono
                font.pixelSize: 10
            }

            Rectangle {
                id: track
                Layout.fillWidth: true
                implicitHeight: 4
                radius: 2
                color: Theme.withAlpha(Theme.fg, 0.12)

                Rectangle {
                    height: parent.height
                    radius: parent.radius
                    width: parent.width * root.progressFrac
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Theme.purple }
                        GradientStop { position: 1.0; color: Theme.pink }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.player?.canSeek ?? false
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: mouse => {
                        const len = root.player?.length ?? 0;
                        if (len > 0)
                            root.player.position = (mouse.x / width) * len;
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

        // ---- Transport: shuffle · prev · play/pause · next · repeat ---------
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 10
            Layout.alignment: Qt.AlignHCenter
            spacing: 20

            MediaButton {
                icon: "shuffle"
                size: 18
                enabled: root.player?.shuffleSupported ?? false
                active: root.player?.shuffle ?? false
                onClicked: if (root.player) root.player.shuffle = !root.player.shuffle
            }

            MediaButton {
                icon: "skip_previous"
                size: 22
                enabled: root.player?.canGoPrevious ?? false
                onClicked: root.player?.previous()
            }

            // Big filled play/pause.
            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                radius: width / 2
                color: Theme.fg

                MaterialIcon {
                    anchors.centerIn: parent
                    text: (root.player?.isPlaying ?? false) ? "pause" : "play_arrow"
                    color: Theme.oled
                    font.pixelSize: 22
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: root.player?.canTogglePlaying ?? false
                    onClicked: root.player?.togglePlaying()
                }
            }

            MediaButton {
                icon: "skip_next"
                size: 22
                enabled: root.player?.canGoNext ?? false
                onClicked: root.player?.next()
            }

            MediaButton {
                // Track → repeat_one; anything else → repeat. On/off state
                // conveyed by the `active` color, not by glyph switching.
                icon: (root.player?.loopState === MprisLoopState.Track) ? "repeat_one" : "repeat"
                size: 18
                enabled: root.player?.canControl ?? false
                active: (root.player?.loopState ?? MprisLoopState.None) !== MprisLoopState.None
                onClicked: {
                    if (!root.player) return;
                    const s = root.player.loopState;
                    root.player.loopState = s === MprisLoopState.None ? MprisLoopState.Playlist
                        : s === MprisLoopState.Playlist ? MprisLoopState.Track
                        : MprisLoopState.None;
                }
            }
        }
    }

    readonly property real progressFrac: {
        const len = root.player?.length ?? 0;
        if (len <= 0) return 0;
        return Math.max(0, Math.min(1, (root.player?.position ?? 0) / len));
    }

    function fmtTime(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds));
        const m = Math.floor(s / 60);
        const r = s % 60;
        return `${m}:${r < 10 ? "0" + r : r}`;
    }
}
