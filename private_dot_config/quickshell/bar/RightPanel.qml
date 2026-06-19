pragma ComponentBehavior: Bound

// RIGHT SYSTEM PANEL — End-4-style action center adapted to this shell.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.services
import qs.bar.components

PanelWindow {
    id: root

    required property ShellScreen modelData

    screen: modelData
    visible: BarState.quickPanelOpen
    color: "transparent"
    WlrLayershell.namespace: "quickshell-rightpanel"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: BarState.quickPanelOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    anchors.top: true
    anchors.right: true
    anchors.bottom: true
    exclusiveZone: 0
    implicitWidth: root.panelWidth + root.clickAwayWidth + Theme.barSidePad * 2

    readonly property int panelWidth: 420
    readonly property int clickAwayWidth: BarState.quickPanelOpen ? 720 : 0
    readonly property int gap: Theme.barSidePad

    onVisibleChanged: if (visible) {
        SystemNotifs.refresh();
        panelFocus.forceActiveFocus();
    }

    mask: Region {
        item: BarState.quickPanelOpen ? hit : null
    }

    Item {
        id: hit

        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            onClicked: BarState.closeQuickPanel()
        }
    }

    Item {
        id: panelFocus

        anchors.fill: parent
        focus: BarState.quickPanelOpen
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                BarState.closeQuickPanel();
                event.accepted = true;
            }
        }
    }

    StyledRect {
        id: panel

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.topMargin: root.gap
        anchors.bottomMargin: root.gap
        anchors.rightMargin: root.gap
        width: root.panelWidth
        radius: Theme.radBar
        color: Theme.panelStrong
        border.width: 1
        border.color: Theme.edge
        clip: true

        transform: Translate {
            x: BarState.quickPanelOpen ? 0 : root.panelWidth + 24
            Behavior on x {
                NumberAnimation {
                    duration: 340
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.25, 1, 0.5, 1, 1, 1]
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Theme.shine }
                GradientStop { position: 0.24; color: "transparent" }
                GradientStop { position: 1.0; color: Theme.shade }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {} // swallow click-away
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            // Top row mirrors End-4's status pill + compact system buttons, but
            // keeps only controls that are useful in this setup.
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 3
                spacing: 8

                StatusPill {
                    Layout.fillWidth: true
                }

                HeaderButton {
                    icon: "close"
                    tooltip: "Close"
                    onClicked: BarState.closeQuickPanel()
                }
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: sliderColumn.implicitHeight + 12
                radius: Theme.rad
                color: Theme.s1
                border.width: 1
                border.color: Theme.bd

                ColumnLayout {
                    id: sliderColumn

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 7

                    LevelSlider {
                        Layout.fillWidth: true
                        icon: "volume_up"
                        value: SystemAudio.volume
                        muted: SystemAudio.muted
                        enabled: SystemAudio.sinkReady
                        onMoved: value => SystemAudio.setVolume(value)
                        onIconClicked: SystemAudio.toggleMute()
                    }

                    LevelSlider {
                        Layout.fillWidth: true
                        icon: "mic"
                        value: SystemAudio.micVolume
                        muted: SystemAudio.micMuted
                        enabled: SystemAudio.sourceReady
                        onMoved: value => SystemAudio.setMicVolume(value)
                        onIconClicked: SystemAudio.toggleMicMute()
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 7

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 7

                    QuickTile {
                        Layout.fillWidth: true
                        expanded: true
                        icon: BluetoothState.enabled ? "bluetooth" : "bluetooth_disabled"
                        title: "Bluetooth"
                        subtitle: BluetoothState.status
                        active: BluetoothState.enabled
                        enabled: BluetoothState.available
                        onClicked: BluetoothState.toggle()
                    }

                    QuickTile {
                        Layout.preferredWidth: 58
                        expanded: false
                        icon: SystemNotifs.dnd ? "notifications_paused" : "notifications"
                        active: SystemNotifs.dnd
                        onClicked: SystemNotifs.toggleDnd()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 7

                    QuickTile {
                        Layout.fillWidth: true
                        expanded: false
                        icon: SystemAudio.muted ? "volume_off" : "volume_up"
                        active: !SystemAudio.muted
                        enabled: SystemAudio.sinkReady
                        onClicked: SystemAudio.toggleMute()
                    }

                    QuickTile {
                        Layout.fillWidth: true
                        expanded: false
                        icon: SystemAudio.micMuted ? "mic_off" : "mic"
                        active: !SystemAudio.micMuted
                        enabled: SystemAudio.sourceReady
                        onClicked: SystemAudio.toggleMicMute()
                    }

                    QuickTile {
                        Layout.fillWidth: true
                        expanded: false
                        icon: "coffee"
                        active: Caffeine.enabled
                        onClicked: Caffeine.toggle()
                    }
                }
            }

            Section {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 230
                title: "Notifications"
                subtitle: SystemNotifs.backend

                SystemNotificationList {
                    anchors.fill: parent
                    anchors.topMargin: 34
                }
            }

            Section {
                Layout.fillWidth: true
                Layout.preferredHeight: 348
                Layout.minimumHeight: 310
                title: "Calendar"
                subtitle: Qt.formatDate(new Date(), "ddd d")

                CalendarMonth {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 36
                    anchors.leftMargin: 2
                    anchors.rightMargin: 2
                }
            }
        }
    }

    component StatusPill: StyledRect {
        implicitHeight: 38
        radius: Theme.pill
        color: Theme.s2
        border.width: 1
        border.color: Theme.bd

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 11
            anchors.rightMargin: 13
            spacing: 8

            MaterialIcon {
                text: "calendar_month"
                font.pixelSize: 19
                color: Theme.ctxAccent
            }

            StyledText {
                text: `${Time.timeStr}  ${Time.dateStr}`
                color: Theme.fg
                font.family: Theme.fontMono
                font.pixelSize: 12
                font.bold: true
            }

            Item {
                Layout.fillWidth: true
            }

            MaterialIcon {
                visible: Caffeine.enabled
                text: "coffee"
                font.pixelSize: 16
                color: Theme.ctxAccent
            }

            MaterialIcon {
                visible: SystemNotifs.dnd
                text: "notifications_paused"
                font.pixelSize: 16
                color: Theme.orange
            }
        }
    }

    component HeaderButton: Item {
        id: button

        property string icon: ""
        property string tooltip: ""
        signal clicked

        Layout.preferredWidth: 38
        Layout.preferredHeight: 38

        StyledRect {
            anchors.fill: parent
            radius: Theme.pill
            color: mouse.containsMouse ? Theme.hov : Theme.s2
            border.width: 1
            border.color: Theme.bd
        }

        MaterialIcon {
            anchors.centerIn: parent
            text: button.icon
            font.pixelSize: 19
            color: Theme.fg
        }

        MouseArea {
            id: mouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }

    component Section: StyledRect {
        id: section

        property string title: ""
        property string subtitle: ""
        default property alias sectionContent: sectionBody.data

        radius: Theme.rad
        color: Theme.withAlpha(Theme.surface0, 0.50)
        border.width: 1
        border.color: Theme.bd
        clip: true

        RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.topMargin: 10

            StyledText {
                Layout.fillWidth: true
                text: section.title
                color: Theme.fg
                font.family: Theme.fontMono
                font.pixelSize: 13
                font.bold: true
            }

            StyledText {
                text: section.subtitle
                color: Theme.comment
                font.family: Theme.fontMono
                font.pixelSize: 10
            }
        }

        Item {
            id: sectionBody

            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            anchors.bottomMargin: 10
        }
    }
}
