pragma ComponentBehavior: Bound

// FOCUS PANEL — multi-page task control center (grew out of the command palette).
// Full-screen dim+click-away backdrop, centered glass card with a LEFT NAV and a
// content Loader that swaps in pages/<Page>.qml. Summoned by $mod+Shift+Return
// (qs ipc call palette open). Esc / click-away closes.
//
// Pages (PanelState.page): focus | tasks | detail | projects | tags | reports.
// All data via Tasks (read) + TaskActions (write, host-bridged) + PanelState (nav).

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.services

PanelWindow {
    id: root

    required property ShellScreen modelData
    screen: modelData
    color: "transparent"
    visible: BarState.paletteOpen

    WlrLayershell.namespace: "quickshell-palette"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: BarState.paletteOpen
        ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    exclusiveZone: 0

    readonly property var pageFiles: ({
        "focus": "pages/FocusPage.qml",
        "tasks": "pages/TasksPage.qml",
        "detail": "pages/DetailPage.qml",
        "projects": "pages/ProjectsPage.qml",
        "tags": "pages/TagsPage.qml",
        "reports": "pages/ReportsPage.qml"
    })
    readonly property var navItems: [
        { "id": "focus", "label": "Focus", "glyph": "\u{F0EBB}" },
        { "id": "tasks", "label": "Tasks", "glyph": "\u{F05B7}" },
        { "id": "projects", "label": "Projects", "glyph": "\u{F0256}" },
        { "id": "tags", "label": "Tags", "glyph": "\u{F04FA}" },
        { "id": "reports", "label": "Reports", "glyph": "\u{F0379}" }
    ]

    onVisibleChanged: if (visible) {
        Tasks.refresh();
        Focus.refresh();
        PanelState.go("focus");
        card.forceActiveFocus();
    }

    // ── Dim + click-away backdrop ───────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45)
        opacity: BarState.paletteOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 140 } }
        MouseArea {
            anchors.fill: parent
            onClicked: BarState.closePalette()
        }
    }

    // ── The panel card ──────────────────────────────────────────────────
    Rectangle {
        id: card

        anchors.centerIn: parent
        width: 900
        height: 600
        radius: 18
        color: Theme.glass
        border.width: 1
        border.color: Theme.bd
        clip: true

        focus: true
        Keys.onEscapePressed: BarState.closePalette()

        opacity: BarState.paletteOpen ? 1 : 0
        scale: BarState.paletteOpen ? 1 : 0.97
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on scale  { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }

        MouseArea { anchors.fill: parent }   // swallow clicks (don't fall to backdrop)

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // ── Left nav rail ──────────────────────────────────────────
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 184
                color: Theme.withAlpha(Theme.bg, 0.55)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 4

                    StyledText {
                        text: "FOCUS PANEL"
                        color: Theme.comment
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                        Layout.bottomMargin: 10
                    }

                    Repeater {
                        model: root.navItems

                        Rectangle {
                            id: navRow
                            required property var modelData

                            Layout.fillWidth: true
                            implicitHeight: 38
                            radius: 10
                            color: PanelState.page === navRow.modelData.id
                                ? Theme.withAlpha(Theme.purple, 0.18) : "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 11

                                StyledText {
                                    text: navRow.modelData.glyph
                                    color: PanelState.page === navRow.modelData.id
                                        ? Theme.purple : Theme.comment
                                    font.family: Theme.fontMono
                                    font.pixelSize: 15
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    text: navRow.modelData.label
                                    color: PanelState.page === navRow.modelData.id
                                        ? Theme.fg : Theme.subtext0
                                    font.family: Theme.fontMono
                                    font.pixelSize: 13
                                    font.bold: PanelState.page === navRow.modelData.id
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: PanelState.go(navRow.modelData.id)
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // context + close hint
                    StyledText {
                        text: "esc to close"
                        color: Theme.comment
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                    }
                }
            }

            Rectangle { Layout.fillHeight: true; implicitWidth: 1; color: Theme.bd }

            // ── Page content ───────────────────────────────────────────
            Loader {
                id: pageLoader
                Layout.fillWidth: true
                Layout.fillHeight: true
                source: root.pageFiles[PanelState.page] ?? root.pageFiles["focus"]
            }
        }
    }
}
