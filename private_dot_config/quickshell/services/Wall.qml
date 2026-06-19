pragma Singleton

// WALL SINGLETON — wallpaper list + set, for the quickshell wallpaper widget.
// Reads ~/walls via `wall.sh list` (shared home; no swww needed to list), and
// sets a wallpaper by writing the path to ~/.cache/adhd/wall-request — the host
// actuator (adhd-wall.path → adhd-wall-exec.sh → wall.sh set) applies it with
// swww (swww-daemon runs host-side).

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // [{ path, rel, collection, name }] sorted by collection.
    property var items: []
    readonly property var collections: {
        const seen = ({});
        const out = [];
        for (const it of root.items)
            if (it.collection && !seen[it.collection]) {
                seen[it.collection] = true;
                out.push(it.collection);
            }
        return out;
    }

    function refresh(): void {
        listProc.running = true;
    }
    function set(path: string): void {
        setProc.command = ["sh", "-c",
            "printf '%s' \"$1\" > \"$HOME/.cache/adhd/wall-request\"", "sh", path];
        setProc.running = true;
    }

    Process { id: setProc }

    Process {
        id: listProc
        command: ["sh", "-c", "wall.sh list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(Boolean);
                root.items = lines.map(p => {
                    const rel = p.replace(/^.*\/walls\//, "");
                    const parts = rel.split("/");
                    return {
                        path: p,
                        rel: rel,
                        collection: parts[0] ?? "",
                        name: (parts[parts.length - 1] ?? "").replace(/\.[^.]+$/, "")
                    };
                });
            }
        }
    }
}
