pragma Singleton

// CAVA SPECTRUM SINGLETON — real audio-reactive visualiser data
// (pattern: caelestia services + Quickshell.Io streaming Process, cf. Focus.qml)
//
// Streams `cava` raw-ascii output (one frame per line: 24 ';'-separated ints
// 0..1000) and normalises each frame into `values` (length 24, each 0..1).
// cava runs INSIDE the arch distrobox (where quickshell lives); the host
// pipewire/pulse sockets are visible there, so it captures host audio. The
// process only runs while `enabled` is true (the island sets it from the
// player presence) so we never capture audio needlessly.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property int bars: 24
    readonly property int maxRange: 1000
    property var values: root._zeros()
    property bool enabled: false
    readonly property bool active: proc.running

    function _zeros(): var {
        const a = [];
        for (let i = 0; i < root.bars; i++)
            a.push(0);
        return a;
    }

    Process {
        id: proc

        running: root.enabled
        // sh -c so $HOME expands to the (shared) config path; exec keeps the
        // tree clean so SplitParser reads cava's own stdout.
        command: ["sh", "-c", "exec cava -p \"$HOME/.config/quickshell/assets/cava-raw.conf\""]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                const t = line.trim();
                if (!t)
                    return;
                const parts = t.split(";");
                const out = [];
                for (let i = 0; i < root.bars; i++) {
                    const v = parseInt(parts[i]);
                    out.push(isNaN(v) ? 0 : Math.min(1, v / root.maxRange));
                }
                root.values = out;
            }
        }

        onRunningChanged: if (!running) root.values = root._zeros()
    }
}
