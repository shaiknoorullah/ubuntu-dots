pragma Singleton

// SYSTEM NOTIFS SINGLETON — dunst first, native Quickshell fallback.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool dunstAvailable: false
    property bool dunstPaused: false
    property int dunstCount: 0
    property var dunstItems: []
    property string externalBackend: ""

    readonly property bool available: root.dunstAvailable || Notifs.count > 0
    readonly property bool dnd: root.dunstAvailable ? root.dunstPaused : Notifs.silent
    readonly property int count: root.dunstAvailable ? root.dunstCount : Notifs.count
    readonly property var items: root.dunstAvailable ? root.dunstItems : Notifs.items
    readonly property string backend: root.dunstAvailable ? root.externalBackend : "native"

    function refresh(): void {
        if (!statusProc.running)
            statusProc.running = true;
    }

    function toggleDnd(): void {
        if (root.dunstAvailable)
            root._runAction(["toggle-dnd"]);
        else
            Notifs.toggleSilent();
    }

    function clear(): void {
        if (root.dunstAvailable)
            root._runAction(["clear"]);
        else
            Notifs.clear();
    }

    function dismiss(id: int): void {
        if (root.dunstAvailable)
            root._runAction(["dismiss", String(id)]);
        else
            Notifs.dismiss(id);
    }

    function _runAction(args: var): void {
        actionProc.command = ["adhd-notifs.sh"].concat(args);
        actionProc.running = true;
        actionRefresh.start();
    }

    Process {
        id: statusProc

        command: ["adhd-notifs.sh", "status"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const o = JSON.parse(text.trim() || "{}");
                    root.dunstAvailable = o.available === true;
                    root.dunstPaused = o.paused === true;
                    root.dunstCount = o.count ?? 0;
                    root.dunstItems = o.items ?? [];
                    root.externalBackend = o.backend ?? (root.dunstAvailable ? "dunst" : "");
                } catch (e) {
                    root.dunstAvailable = false;
                    root.dunstPaused = false;
                    root.dunstCount = 0;
                    root.dunstItems = [];
                    root.externalBackend = "";
                }
            }
        }
    }

    Process {
        id: actionProc
    }

    Timer {
        id: actionRefresh

        interval: 250
        repeat: false
        onTriggered: root.refresh()
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
