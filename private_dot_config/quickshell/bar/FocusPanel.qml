pragma ComponentBehavior: Bound

// FOCUS PANEL — multi-page task control center.
// A real floating TOPLEVEL window (not a layer surface), so Hyprland draws its
// gradient border + rounding + shadow and blurs the desktop directly behind it
// (like any translucent window). No QML backdrop/border — that's the compositor's
// job. Floated + centered by a windowrule (match title "focus-panel").
// Summoned by $mod+Shift+Return (qs ipc call panel focus). Esc closes / goes back.
//
// Pages (PanelState.page): focus | tasks | detail | projects | tags | reports.

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.services

FloatingWindow {
    id: root

    implicitWidth: 900
    implicitHeight: 600
    title: "focus-panel"
    // Translucent → Hyprland frosts the desktop behind it. A bit more opaque
    // for text contrast; the dim_around windowrule darkens the background too.
    color: Theme.withAlpha(Theme.base, 0.82)
    visible: BarState.paletteOpen

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
        Qt.callLater(root.focusActive);
    }

    function focusActive(): void {
        if (PanelState.page !== "focus" && PanelState.page !== "detail")
            scope.forceActiveFocus();
    }

    Connections {
        target: PanelState
        function onPageChanged(): void { Qt.callLater(root.focusActive); }
    }

    // Key router lives on a FocusScope filling the window.
    FocusScope {
        id: scope
        anchors.fill: parent
        focus: true

        readonly property var pageItem: pageLoader.item
        readonly property int navCount: (pageItem && pageItem.navCount !== undefined) ? pageItem.navCount : 0

        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_Escape:
                if (PanelState.page === "detail")
                    PanelState.go("tasks");
                else
                    BarState.closePalette();
                event.accepted = true;
                break;
            case Qt.Key_Tab:
                PanelState.cycle(1); event.accepted = true; break;
            case Qt.Key_Backtab:
                PanelState.cycle(-1); event.accepted = true; break;
            case Qt.Key_Down:
            case Qt.Key_J:
                PanelState.sel = Math.min(scope.navCount - 1, PanelState.sel + 1);
                event.accepted = true; break;
            case Qt.Key_Up:
            case Qt.Key_K:
                PanelState.sel = Math.max(0, PanelState.sel - 1);
                event.accepted = true; break;
            case Qt.Key_Return:
            case Qt.Key_Enter:
                if (scope.pageItem && scope.pageItem.navActivate)
                    scope.pageItem.navActivate();
                event.accepted = true; break;
            case Qt.Key_1: case Qt.Key_2: case Qt.Key_3: case Qt.Key_4: case Qt.Key_5:
                PanelState.go(PanelState.order[event.key - Qt.Key_1]);
                event.accepted = true; break;
            }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // ── Left nav rail (slightly more opaque so it reads) ───────────
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 184
                color: Theme.withAlpha(Theme.bg, 0.4)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 4

                    StyledText {
                        text: "FOCUS PANEL"
                        color: Theme.subtext0
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
                                ? Theme.withAlpha(Theme.purple, 0.22) : "transparent"

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

                    StyledText {
                        text: "esc to close"
                        color: Theme.subtext0
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                    }
                }
            }

            Rectangle { Layout.fillHeight: true; implicitWidth: 1; color: Theme.bd }

            // ── Page content ───────────────────────────────────────────────
            Loader {
                id: pageLoader
                Layout.fillWidth: true
                Layout.fillHeight: true
                source: root.pageFiles[PanelState.page] ?? root.pageFiles["focus"]
            }
        }
    }
}
