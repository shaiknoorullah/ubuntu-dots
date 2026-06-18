pragma Singleton

// VOLUME SINGLETON — default sink volume + mute
// (pattern: caelestia Process + Timer poll, see services/Weather.qml)
//
// Wraps `eww-vol.sh` which prints:  {"vol":62,"muted":false}
// Exposes `vol` (0–100 int) and `muted` (bool). The top-bar right pill renders
// a Nerd-Font speaker glyph + the percentage, swapping to a muted glyph when
// `muted` is true.
//
// Polled every 2 s. Volume changes are user-driven and bursty; a short poll is
// cheap and keeps the readout responsive. A future native PipeWire binding
// (Quickshell.Services.Pipewire) could replace this Process without touching
// the widget — the widget only reads `Volume.vol` / `Volume.muted`.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int vol: 0
    property bool muted: false

    function refresh(): void {
        proc.running = true;
    }

    Process {
        id: proc

        command: ["sh", "-c", "eww-vol.sh"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const o = JSON.parse(text.trim());
                    root.vol = o.vol ?? 0;
                    root.muted = o.muted ?? false;
                } catch (e) {
                    // keep last good
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
