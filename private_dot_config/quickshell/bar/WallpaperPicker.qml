pragma ComponentBehavior: Bound

// WALLPAPER PICKER — a floating quickshell widget (replaces the rofi picker).
// A thumbnail grid of ~/walls; click or ⏎ to set (host-bridged via Wall.set →
// adhd-wall.path → wall.sh). Collection filter chips up top. Esc closes.
// Floated/centered/focused by a windowrule (title "wallpaper-picker").

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.components
import qs.services

FloatingWindow {
    id: root

    implicitWidth: 1000
    implicitHeight: 680
    title: "wallpaper-picker"
    color: Theme.withAlpha(Theme.base, 0.86)
    visible: BarState.wallpaperOpen

    property string filter: ""   // "" = all collections
    readonly property var shown: root.filter
        ? (Wall.items || []).filter(w => w.collection === root.filter)
        : (Wall.items || [])

    onVisibleChanged: if (visible) {
        Wall.refresh();
        root.filter = "";
        Qt.callLater(() => grid.forceActiveFocus());
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        // ── Header ──────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            StyledText {
                text: "\u{F1043}  Wallpaper"
                color: Theme.fg
                font.family: Theme.fontMono
                font.pixelSize: 16
                font.bold: true
            }
            Item { Layout.fillWidth: true }
            StyledText {
                text: `${root.shown.length} / ${(Wall.items || []).length}`
                color: Theme.subtext0
                font.family: Theme.fontMono
                font.pixelSize: 12
            }
        }

        // ── Collection filter chips ─────────────────────────────────────
        Flow {
            Layout.fillWidth: true
            spacing: 7

            Repeater {
                model: [""].concat(Wall.collections)
                Rectangle {
                    id: chip
                    required property var modelData
                    readonly property bool on: root.filter === chip.modelData
                    implicitHeight: 26
                    implicitWidth: chipText.implicitWidth + 22
                    radius: 99
                    color: chip.on ? Theme.withAlpha(Theme.purple, 0.25) : Theme.s2
                    border.width: 1
                    border.color: chip.on ? Theme.purple : Theme.bd
                    StyledText {
                        id: chipText
                        anchors.centerIn: parent
                        text: chip.modelData === "" ? "all" : chip.modelData
                        color: chip.on ? Theme.fg : Theme.subtext0
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { root.filter = chip.modelData; grid.currentIndex = 0; }
                    }
                }
            }
        }

        // ── Thumbnail grid ──────────────────────────────────────────────
        GridView {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            focus: true
            cellWidth: Math.floor(width / Math.max(1, Math.floor(width / 236)))
            cellHeight: 156
            model: root.shown
            cacheBuffer: 1200
            boundsBehavior: Flickable.StopAtBounds

            Keys.onReturnPressed: grid.activate()
            Keys.onEnterPressed: grid.activate()
            Keys.onEscapePressed: BarState.closeWallpaper()
            function activate(): void {
                const w = root.shown[grid.currentIndex];
                if (w) {
                    Wall.set(w.path);
                    BarState.closeWallpaper();
                }
            }

            delegate: Item {
                id: cell
                required property var modelData
                required property int index
                width: grid.cellWidth
                height: grid.cellHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 6
                    radius: 12
                    color: "transparent"
                    border.width: cell.GridView.isCurrentItem ? 2 : 0
                    border.color: Theme.purple

                    ClippingRectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        radius: 11
                        color: Theme.surface0

                        Image {
                            anchors.fill: parent
                            source: "file://" + cell.modelData.path
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            sourceSize.width: 360
                        }

                        // name label on a bottom scrim
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 26
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.7) }
                            }
                            StyledText {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.margins: 6
                                text: cell.modelData.name
                                color: Theme.fg
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: grid.currentIndex = cell.index
                        onClicked: {
                            Wall.set(cell.modelData.path);
                            BarState.closeWallpaper();
                        }
                    }
                }
            }
        }

        StyledText {
            text: "↑↓←→ move   ⏎ set   esc close"
            color: Theme.subtext0
            font.family: Theme.fontMono
            font.pixelSize: 11
        }
    }
}
