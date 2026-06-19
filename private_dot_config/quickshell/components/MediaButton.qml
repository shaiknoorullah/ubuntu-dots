// MEDIA BUTTON — reusable transport / toggle control (Material Symbol glyph).
// Dims when disabled, accents when `active` (shuffle/repeat on-state).

import QtQuick
import qs.components
import qs.services

Item {
    id: root

    property string icon: ""
    property bool enabled: true
    property bool active: false
    property int size: 22
    signal clicked

    implicitWidth: size
    implicitHeight: size

    MaterialIcon {
        anchors.centerIn: parent
        text: root.icon
        font.pixelSize: root.size
        color: !root.enabled ? Theme.comment
             : root.active ? Theme.ctxAccent
             : Theme.fg
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
