import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

StyledRect {
    id: root

    property string icon: "radio_button_unchecked"
    property string title: ""
    property string subtitle: ""
    property bool active: false
    property bool enabled: true
    property bool expanded: false
    signal clicked

    implicitWidth: root.expanded ? 132 : 58
    implicitHeight: 58
    radius: root.active ? Theme.rad : Theme.pill
    color: !root.enabled ? Theme.withAlpha(Theme.surface0, 0.34)
        : root.active ? Theme.withAlpha(Theme.ctxAccent, 0.72)
        : hover.containsMouse ? Theme.hov
        : Theme.s2
    border.width: 1
    border.color: root.active ? Theme.withAlpha(Theme.ctxAccent, 0.42) : Theme.bd
    opacity: root.enabled ? 1 : 0.52

    Behavior on radius {
        NumberAnimation {
            duration: Theme.durFast
            easing.type: Easing.OutCubic
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: root.expanded ? 7 : 0

        StyledRect {
            Layout.preferredWidth: 46
            Layout.preferredHeight: 46
            radius: root.active ? Theme.rad : Theme.pill
            color: root.expanded ? (root.active ? Theme.withAlpha(Theme.base, 0.14) : Theme.withAlpha(Theme.fg, 0.05)) : "transparent"

            MaterialIcon {
                anchors.centerIn: parent
                text: root.icon
                font.pixelSize: root.expanded ? 22 : 24
                color: root.active ? Theme.base : Theme.fg
            }
        }

        ColumnLayout {
            visible: root.expanded
            Layout.fillWidth: true
            spacing: -1

            StyledText {
                Layout.fillWidth: true
                text: root.title
                color: root.active ? Theme.base : Theme.fg
                font.family: Theme.fontMono
                font.pixelSize: 11
                font.bold: true
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: root.subtitle
                color: root.active ? Theme.withAlpha(Theme.base, 0.72) : Theme.subtext0
                font.family: Theme.fontMono
                font.pixelSize: 10
                elide: Text.ElideRight
                visible: text.length > 0
            }
        }
    }

    MouseArea {
        id: hover

        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
