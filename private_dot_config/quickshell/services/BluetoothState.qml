pragma Singleton

// BLUETOOTH STATE SINGLETON — host bluetoothctl bridge.

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool available: false
    property bool enabled: false
    property int connectedCount: 0
    property string firstConnectedName: ""
    property string status: "Unavailable"

    function refresh(): void {
        if (!statusProc.running)
            statusProc.running = true;
    }

    function toggle(): void {
        actionProc.command = ["adhd-bluetooth.sh", "toggle"];
        actionProc.running = true;
        actionRefresh.start();
    }

    Process {
        id: statusProc

        command: ["adhd-bluetooth.sh", "status"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const o = JSON.parse(text.trim() || "{}");
                    root.available = o.available === true;
                    root.enabled = o.enabled === true;
                    root.connectedCount = o.connectedCount ?? 0;
                    root.firstConnectedName = o.firstConnectedName ?? "";
                    root.status = o.status ?? "Unavailable";
                } catch (e) {
                    root.available = false;
                    root.enabled = false;
                    root.connectedCount = 0;
                    root.firstConnectedName = "";
                    root.status = "Unavailable";
                }
            }
        }
    }

    Process {
        id: actionProc
    }

    Timer {
        id: actionRefresh

        interval: 600
        repeat: false
        onTriggered: root.refresh()
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
