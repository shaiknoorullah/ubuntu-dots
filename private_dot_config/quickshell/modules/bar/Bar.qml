pragma ComponentBehavior: Bound

// BAR CONTENT  (pattern: caelestia modules/bar/Bar.qml — there it's a vertical
// ColumnLayout; here a horizontal top bar to keep the example obvious)
//
// This is just the *content* laid out edge-to-edge. The PanelWindow / layer-shell
// surface that hosts it lives in BarWindow.qml. Splitting content from the window
// mirrors caelestia's Bar.qml (content) vs BarWrapper.qml (sizing/exclusion).

import QtQuick
import QtQuick.Layouts
import "components"
import qs.components
import qs.services

Item {
    id: root

    required property ShellScreen screen

    implicitHeight: 36

    // Left cluster
    RowLayout {
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Workspaces {
            screen: root.screen
        }
    }

    // Center: active window title
    ActiveWindow {
        anchors.centerIn: parent
        width: Math.min(implicitWidth, root.width * 0.4)
    }

    // Right cluster: media island + clock
    RowLayout {
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        Media {}

        Clock {}
    }
}
