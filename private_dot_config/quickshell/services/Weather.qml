pragma Singleton

// SHELL-SCRIPT POLLING SINGLETON  (pattern: caelestia Process + Timer usage,
// e.g. services/Brightness.qml ddcProc, services/NetworkUsage.qml)
//
// THE CANONICAL "run a script and poll it" PATTERN:
//   - Process { command:[...]; stdout: StdioCollector { onStreamFinished: ... } }
//   - set `process.running = true` to fire it once
//   - a Timer with repeat:true restarts it on an interval
//   - for fire-and-forget (no output needed) use Quickshell.execDetached([...])
//
// `import Quickshell.Io` is required for Process / StdioCollector / FileView.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string raw: ""
    property string summary: "…"

    // Trigger a refresh: just flip running. StdioCollector buffers full stdout
    // and emits streamFinished once when the process exits.
    function refresh(): void {
        proc.running = true;
    }

    Process {
        id: proc

        // Replace with any script; argv form avoids shell-injection.
        command: ["sh", "-c", "echo example-weather-output"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.raw = text.trim();
                root.summary = root.raw.split("\n")[0] ?? "";
            }
        }
    }

    // Poll every 15 min. triggeredOnStart fires immediately on load.
    Timer {
        interval: 15 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
