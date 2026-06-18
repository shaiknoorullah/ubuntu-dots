pragma Singleton

// TIME SINGLETON  (pattern: caelestia services/Time.qml)
//
// Uses SystemClock (NOT a polling Timer) for clock ticks — it's the correct
// quickshell primitive: it only wakes on the requested precision boundary.
// For shell-script polling use a Timer + Process (see services/Weather.qml).

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property date date: clock.date
    readonly property string timeStr: Qt.formatDateTime(clock.date, "hh:mm")
    readonly property string dateStr: Qt.formatDateTime(clock.date, "ddd d MMM")

    function format(fmt: string): string {
        return Qt.formatDateTime(clock.date, fmt);
    }

    SystemClock {
        id: clock

        precision: SystemClock.Seconds
    }
}
