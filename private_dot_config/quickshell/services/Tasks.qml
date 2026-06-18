pragma Singleton

// TASKS SINGLETON — "now · next" task list for the LEFT bar
// (pattern: caelestia Process + Timer poll, see services/Weather.qml)
//
// Taskwarrior exports the active + a few next pending tasks as JSON. We invoke
// the real `task` binary (go-task shadows `task`, hence /usr/bin/task, matching
// eww-active.sh's TASK_BIN convention). Output is taskwarrior's native JSON
// array; we map it to { description, active, project, urgency }.
//
//   task rc.json.array=on +PENDING export   ->  [ {id,description,start?,project,urgency,...}, ... ]
//
// A task is "active" when it has a `start` attribute (timewarrior/`task start`
// set it). We sort active-first then by urgency, cap to a handful for the bar.
//
// Polled every 5 s — the left bar is summoned, not always visible, and tasks
// change on human timescales.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // list of { description, active, project, urgency }
    property var items: []

    function refresh(): void {
        proc.running = true;
    }

    Process {
        id: proc

        // Read the HOST-exported snapshot (the container's taskwarrior 3.x can't
        // read the host's 2.6.2 data; adhd-tasks-export.sh writes this JSON).
        command: ["sh", "-c", "cat \"$HOME/.cache/adhd/tasks.json\" 2>/dev/null || echo '[]'"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const arr = JSON.parse(text.trim() || "[]");
                    const mapped = arr.map(t => ({
                        description: t.description ?? "",
                        active: t.start !== undefined && t.start !== null,
                        project: t.project ?? "",
                        urgency: t.urgency ?? 0
                    }));
                    // active first, then by descending urgency
                    mapped.sort((a, b) => {
                        if (a.active !== b.active)
                            return a.active ? -1 : 1;
                        return b.urgency - a.urgency;
                    });
                    root.items = mapped.slice(0, 6);
                } catch (e) {
                    root.items = [];
                }
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
