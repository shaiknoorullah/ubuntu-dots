import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

StyledRect {
    id: root

    property string icon: "volume_up"
    property string label: ""
    property int value: 0
    property bool muted: false
    property bool enabled: true
    signal moved(int value)
    signal iconClicked

    implicitHeight: 42
    radius: Theme.rad
    color: hover.containsMouse ? Theme.hov : Theme.s2
    border.width: 1
    border.color: Theme.bd
    opacity: root.enabled ? 1 : 0.5

    function valueFromX(x: real): int {
        const left = track.x;
        const width = Math.max(1, track.width);
        return Math.max(0, Math.min(100, Math.round(((x - left) / width) * 100)));
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 9

        Item {
            Layout.preferredWidth: 26
            Layout.preferredHeight: 26

            MaterialIcon {
                anchors.centerIn: parent
                text: root.muted ? (root.icon === "mic" ? "mic_off" : "volume_off") : root.icon
                font.pixelSize: 20
                color: root.muted ? Theme.red : Theme.fg
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.enabled
                cursorShape: Qt.PointingHandCursor
                onClicked: root.iconClicked()
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 26

            StyledRect {
                id: track

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 7
                radius: Theme.pill
                color: Theme.withAlpha(Theme.fg, 0.10)
                clip: true

                StyledRect {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * (root.value / 100)
                    radius: Theme.pill
                    color: root.muted ? Theme.withAlpha(Theme.red, 0.48) : Theme.ctxAccent
                }
            }
        }

        StyledText {
            Layout.preferredWidth: 40
            text: root.muted ? "mute" : `${root.value}%`
            color: root.muted ? Theme.red : Theme.subtext0
            font.family: Theme.fontMono
            font.pixelSize: 10
            horizontalAlignment: Text.AlignRight
        }
    }

    MouseArea {
        id: hover

        anchors.fill: parent
        anchors.leftMargin: 45
        anchors.rightMargin: 48
        enabled: root.enabled
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onPressed: mouse => root.moved(root.valueFromX(mouse.x))
        onPositionChanged: mouse => {
            if (pressed)
                root.moved(root.valueFromX(mouse.x));
        }
    }
}
