pragma Singleton

// PROJECT SINGLETON — current project name + git branch (bottom-bar left cell)
// (pattern: caelestia Process + Timer poll, see services/Weather.qml)
//
// Wraps `eww-project.sh` which prints:
//   {"project":"pnow-ats-v2","branch":"feat/boolgen-otel"}
// `project` is "—" and `branch` is "" when no project is entered (the bar then
// shows a calm placeholder and hides the empty branch).
//
// `region` is NOT supplied by the script; the mockup shows "work · ap-south".
// We derive a light region label from the context (purely cosmetic) and let it
// be overridden later if a region cache is added. Kept here so the bottom bar's
// left cluster has a single source for all three tokens.
//
// Polled every 5 s — project/branch change on human timescales (entering a
// project, switching git branches).

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root

    property string name: "—"
    property string branch: ""

    // Cosmetic region label. Work lives in ap-south by default; other contexts
    // get "local". Replace with a real cache read if/when one exists.
    readonly property string region: Ctx.ctx === "work" ? "ap-south" : "local"

    function refresh(): void {
        proc.running = true;
    }

    Process {
        id: proc

        command: ["sh", "-c", "eww-project.sh"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const o = JSON.parse(text.trim());
                    root.name = o.project ?? "—";
                    root.branch = o.branch ?? "";
                } catch (e) {
                    // keep last good
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
