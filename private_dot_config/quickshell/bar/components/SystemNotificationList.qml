import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

Item {
    id: root

    implicitHeight: 260

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Flickable {
            id: flick

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: list.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: list

                width: flick.width
                spacing: 7

                Repeater {
                    model: SystemNotifs.items
                    delegate: StyledRect {
                        required property var modelData

                        Layout.fillWidth: true
                        implicitHeight: Math.max(66, notifBody.implicitHeight + 42)
                        radius: Theme.rad
                        color: Theme.withAlpha(Theme.surface0, 0.54)
                        border.width: 1
                        border.color: Theme.bd

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            StyledRect {
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 36
                                Layout.alignment: Qt.AlignTop
                                radius: Theme.pill
                                color: Theme.a18

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    text: "notifications"
                                    font.pixelSize: 20
                                    color: Theme.ctxAccent
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    Layout.fillWidth: true

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: modelData.app || "Notification"
                                        color: Theme.subtext0
                                        font.family: Theme.fontMono
                                        font.pixelSize: 10
                                        elide: Text.ElideRight
                                    }

                                    StyledText {
                                        text: modelData.time || ""
                                        color: Theme.comment
                                        font.family: Theme.fontMono
                                        font.pixelSize: 10
                                    }
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: modelData.summary || ""
                                    color: Theme.fg
                                    font.family: Theme.fontMono
                                    font.pixelSize: 12
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                StyledText {
                                    id: notifBody

                                    Layout.fillWidth: true
                                    text: modelData.body || ""
                                    color: Theme.subtext0
                                    font.family: Theme.fontMono
                                    font.pixelSize: 10
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                    visible: text.length > 0
                                }
                            }

                            Item {
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                Layout.alignment: Qt.AlignTop

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    text: "close"
                                    font.pixelSize: 16
                                    color: closeMouse.containsMouse ? Theme.red : Theme.comment
                                }

                                MouseArea {
                                    id: closeMouse

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: SystemNotifs.dismiss(modelData.id)
                                }
                            }
                        }
                    }
                }
            }

            StyledText {
                anchors.centerIn: parent
                visible: SystemNotifs.items.length === 0
                text: SystemNotifs.backend === "native" ? "No captured notifications" : "No notifications"
                color: Theme.comment
                font.family: Theme.fontMono
                font.pixelSize: 12
            }
        }

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: 38
            radius: Theme.pill
            color: Theme.s2
            border.width: 1
            border.color: Theme.bd

            RowLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 6

                FooterButton {
                    icon: SystemNotifs.dnd ? "notifications_paused" : "notifications"
                    active: SystemNotifs.dnd
                    onClicked: SystemNotifs.toggleDnd()
                }

                StyledText {
                    Layout.fillWidth: true
                    text: SystemNotifs.backend !== "native"
                        ? `${SystemNotifs.count} notifications`
                        : `${SystemNotifs.count} native`
                    color: Theme.subtext0
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                }

                FooterButton {
                    icon: "delete_sweep"
                    active: false
                    onClicked: SystemNotifs.clear()
                }
            }
        }
    }

    component FooterButton: Item {
        id: button

        property string icon: ""
        property bool active: false
        signal clicked

        Layout.preferredWidth: 34
        Layout.preferredHeight: 30

        StyledRect {
            anchors.fill: parent
            radius: Theme.pill
            color: button.active ? Theme.a35 : footerMouse.containsMouse ? Theme.hov : "transparent"
        }

        MaterialIcon {
            anchors.centerIn: parent
            text: button.icon
            font.pixelSize: 18
            color: button.active ? Theme.ctxAccent : Theme.fg
        }

        MouseArea {
            id: footerMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }
}
