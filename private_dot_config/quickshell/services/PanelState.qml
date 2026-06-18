pragma Singleton

// PANEL STATE SINGLETON — navigation + cross-page state for the multi-page focus
// panel (FocusPanel.qml). Pages read/drive this to switch views and pass a
// selected task to the Detail page.

import Quickshell

Singleton {
    id: root

    // Current page: "focus" | "tasks" | "detail" | "projects" | "tags" | "reports"
    property string page: "focus"

    // The task the Detail page edits (taskwarrior id).
    property int selectedTaskId: -1

    // Tasks-page filters.
    property string filterProject: ""           // "" = all
    property string filterTag: ""               // "" = all
    property string filterStatus: "pending"     // pending | today | overdue | all

    function go(p: string): void {
        root.page = p;
    }
    function openDetail(id: int): void {
        root.selectedTaskId = id;
        root.page = "detail";
    }
    function reset(): void {
        root.page = "focus";
        root.selectedTaskId = -1;
        root.filterProject = "";
        root.filterTag = "";
        root.filterStatus = "pending";
    }
}
