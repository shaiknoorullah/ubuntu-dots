pragma ComponentBehavior: Bound

// FOCUS COMMAND PALETTE  (mockup: centered Raycast/Spotlight-style block starter)
// ============================================================================
// A dedicated full-screen overlay with a dimmed/click-away backdrop and a
// centred glass card. Summoned by $mod+Shift+Return (qs ipc call palette open).
//
//   • search input (auto-focused) — type to FUZZY-FILTER pending tasks
//   • ↑/↓ move selection · ⏎ start a deep block on it · esc close
//   • non-matching text offers "+ create <text>" → quick-add + start
//   • salah runway footer ("→ ʿAsr 16:42 · one block, one outcome")
//
// Data: Tasks.items (host snapshot) + Focus (prayer runway). Starting a block
// writes ~/.cache/adhd/start-request → the host actuator (adhd-block.path).

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
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
    // Grab the keyboard exclusively while open so typing + nav land here.
    WlrLayershell.keyboardFocus: BarState.paletteOpen
        ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    exclusiveZone: 0

    // ── State ───────────────────────────────────────────────────────────
    property string query: ""
    property int sel: 0

    readonly property var results: {
        const q = root.query.trim().toLowerCase();
        const all = Tasks.items || [];
        if (!q)
            return all;
        return all.filter(t => (t.description || "").toLowerCase().includes(q));
    }
    readonly property bool canCreate: root.query.trim().length > 0
    readonly property int rowCount: root.results.length + (root.canCreate ? 1 : 0)

    onVisibleChanged: if (visible) {
        Tasks.refresh();
        Focus.refresh();
        root.query = "";
        root.sel = 0;
        input.text = "";
        input.forceActiveFocus();
    }

    function clampSel(): void {
        if (root.sel < 0)
            root.sel = root.rowCount > 0 ? root.rowCount - 1 : 0;
        if (root.sel >= root.rowCount)
            root.sel = 0;
    }
    function startBlock(req: string): void {
        startProc.command = ["sh", "-c",
            "printf '%s' \"$1\" > \"$HOME/.cache/adhd/start-request\"", "sh", req];
        startProc.running = true;
        BarState.closePalette();
    }
    function activate(): void {
        if (root.sel < root.results.length)
            root.startBlock(String(root.results[root.sel].id));
        else if (root.canCreate)
            root.startBlock("new:" + root.query.trim());
    }
    Process { id: startProc }

    // ── Dim + blur click-away backdrop ──────────────────────────────────
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

    // ── The palette card ────────────────────────────────────────────────
    Rectangle {
        id: card

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Math.round(root.height * 0.16)
        width: 580
        implicitHeight: col.implicitHeight
        radius: 18
        color: Theme.glass
        border.width: 1
        border.color: Theme.bd

        // entrance: scale + fade
        opacity: BarState.paletteOpen ? 1 : 0
        scale: BarState.paletteOpen ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on scale  { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

        // swallow clicks so they don't hit the backdrop
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: col
            width: parent.width
            spacing: 0

            // ── Search row ──────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: 16
                spacing: 12

                StyledText {
                    text: "\u{F0349}"            // magnify glyph
                    color: Theme.purple
                    font.family: Theme.fontMono
                    font.pixelSize: 18
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: 24

                    TextInput {
                        id: input
                        anchors.fill: parent
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.fg
                        font.family: Theme.fontMono
                        font.pixelSize: 16
                        clip: true
                        selectByMouse: true
                        onTextChanged: {
                            root.query = text;
                            root.sel = 0;
                        }
                        Keys.onUpPressed: { root.sel -= 1; root.clampSel(); }
                        Keys.onDownPressed: { root.sel += 1; root.clampSel(); }
                        Keys.onReturnPressed: root.activate()
                        Keys.onEnterPressed: root.activate()
                        Keys.onEscapePressed: BarState.closePalette()
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: input.text.length === 0
                        text: "start a block — type or pick…"
                        color: Theme.comment
                        font.family: Theme.fontMono
                        font.pixelSize: 16
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.bd }

            // ── Results ─────────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: 8
                spacing: 2

                Repeater {
                    model: root.results

                    Rectangle {
                        id: rowItem
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        implicitHeight: 40
                        radius: 10
                        color: root.sel === rowItem.index
                            ? Theme.withAlpha(Theme.purple, 0.18) : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 11

                            StyledText {
                                text: root.sel === rowItem.index ? "\u{F0142}" : "\u{F0764}"  // ▸ / ·
                                color: root.sel === rowItem.index ? Theme.purple : Theme.comment
                                font.family: Theme.fontMono
                                font.pixelSize: 13
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: rowItem.modelData.description ?? ""
                                color: root.sel === rowItem.index ? Theme.fg : Theme.subtext0
                                font.family: Theme.fontMono
                                font.pixelSize: 13
                                elide: Text.ElideRight
                            }
                            StyledText {
                                text: rowItem.modelData.project ?? ""
                                color: Theme.comment
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.sel = rowItem.index
                            onClicked: { root.sel = rowItem.index; root.activate(); }
                        }
                    }
                }

                // create-new row
                Rectangle {
                    visible: root.canCreate
                    Layout.fillWidth: true
                    implicitHeight: 40
                    radius: 10
                    color: root.sel === root.results.length
                        ? Theme.withAlpha(Theme.green, 0.18) : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 11

                        StyledText {
                            text: "\u{F0415}"   // plus
                            color: Theme.green
                            font.family: Theme.fontMono
                            font.pixelSize: 13
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: `create “${root.query.trim()}”`
                            color: Theme.green
                            font.family: Theme.fontMono
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.sel = root.results.length
                        onClicked: { root.sel = root.results.length; root.activate(); }
                    }
                }

                // empty state
                StyledText {
                    visible: root.rowCount === 0
                    Layout.margins: 8
                    text: "no pending tasks — type to create one"
                    color: Theme.comment
                    font.family: Theme.fontMono
                    font.pixelSize: 13
                }
            }

            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.bd }

            // ── Footer: hints + salah runway ───────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: 14
                spacing: 14

                StyledText {
                    text: "↑↓ move   ⏎ start   esc close"
                    color: Theme.comment
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                }
                Item { Layout.fillWidth: true }
                StyledText {
                    text: Focus.nextPrayerName
                        ? `→ ${Focus.nextPrayerName} ${Focus.nextPrayerTime} · one block, one outcome`
                        : "one block, one outcome"
                    color: Theme.ctxAccent
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                }
            }
        }
    }
}
