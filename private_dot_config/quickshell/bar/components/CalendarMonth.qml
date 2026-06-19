import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

Item {
    id: root

    property int monthOffset: 0
    readonly property date today: new Date()
    readonly property date visibleMonth: new Date(today.getFullYear(), today.getMonth() + monthOffset, 1)
    readonly property var days: root.makeDays()

    implicitHeight: column.implicitHeight

    function daysInMonth(year: int, month: int): int {
        return new Date(year, month + 1, 0).getDate();
    }

    function makeDays(): var {
        const year = root.visibleMonth.getFullYear();
        const month = root.visibleMonth.getMonth();
        const first = new Date(year, month, 1);
        const mondayFirst = (first.getDay() + 6) % 7;
        const prevCount = root.daysInMonth(year, month - 1);
        const count = root.daysInMonth(year, month);
        const out = [];

        for (let i = 0; i < 42; i++) {
            const n = i - mondayFirst + 1;
            let day = n;
            let inMonth = true;
            if (n < 1) {
                day = prevCount + n;
                inMonth = false;
            } else if (n > count) {
                day = n - count;
                inMonth = false;
            }
            out.push({
                day,
                inMonth,
                today: inMonth
                    && day === root.today.getDate()
                    && month === root.today.getMonth()
                    && year === root.today.getFullYear()
            });
        }
        return out;
    }

    ColumnLayout {
        id: column

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            StyledText {
                Layout.fillWidth: true
                text: Qt.formatDate(root.visibleMonth, "MMMM yyyy")
                color: Theme.fg
                font.family: Theme.fontMono
                font.pixelSize: 14
                font.bold: true
            }

            IconButton {
                icon: "chevron_left"
                onClicked: root.monthOffset--
            }
            IconButton {
                icon: "chevron_right"
                onClicked: root.monthOffset++
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 7
            columnSpacing: 4
            rowSpacing: 4

            Repeater {
                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                delegate: StyledText {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    text: modelData
                    color: Theme.comment
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Repeater {
                model: root.days
                delegate: StyledRect {
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    radius: Theme.rad
                    color: modelData.today ? Theme.ctxAccent : "transparent"

                    StyledText {
                        anchors.centerIn: parent
                        text: `${modelData.day}`
                        color: modelData.today ? Theme.base
                            : modelData.inMonth ? Theme.fg
                            : Theme.comment
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        font.bold: modelData.today
                    }
                }
            }
        }
    }

    component IconButton: Item {
        id: button

        property string icon: ""
        signal clicked

        Layout.preferredWidth: 30
        Layout.preferredHeight: 30

        StyledRect {
            anchors.fill: parent
            radius: Theme.pill
            color: buttonMouse.containsMouse ? Theme.hov : Theme.s2
            border.width: 1
            border.color: Theme.bd
        }

        MaterialIcon {
            anchors.centerIn: parent
            text: button.icon
            font.pixelSize: 18
            color: Theme.fg
        }

        MouseArea {
            id: buttonMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }
}
