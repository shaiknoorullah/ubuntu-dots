//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1

// ENTRY POINT  (pattern: caelestia shell.qml)
//
// quickshell auto-loads `shell.qml` (or `<conf>.qml` via `qs -c <name>`). The
// root MUST be a ShellRoot (from `import Quickshell`). Everything else hangs off
// it. `settings.watchFiles: true` enables hot reload on save.
//
// MULTI-MONITOR: `Variants` (NOT a Repeater — Variants works outside the visual
// tree) instantiates its delegate once per element of `model`. Binding the model
// to Screens.screens spawns one BarWindow per output. Each delegate receives the
// element as `modelData` (here a ShellScreen). This is THE quickshell idiom for
// per-monitor panels. `Scope` can wrap multiple per-screen windows if needed.
//
// `import qs.*` maps to subfolders of the config root automatically (quickshell
// exposes the root as the `qs` prefix). No qmldir files are needed — singletons
// are auto-registered via their `pragma Singleton`.

import QtQuick
import Quickshell
import qs.services
import qs.bar            // TopBar + Island + BottomBar + LeftBar (all in bar/)

ShellRoot {
    // Hot reload QML on file save (caelestia sets this on ShellRoot).
    settings.watchFiles: true

    // One TOP bar per monitor — mockup-faithful: two floating glass pills
    // (context·workspaces·window / clock·volume·notif) + a centred OLED
    // Dynamic-Island notch (bar/TopBar.qml + bar/Island.qml).
    Variants {
        model: Screens.screens

        // TopBar declares `required property ShellScreen modelData`, which
        // Variants fills in per instance. No extra wiring needed.
        TopBar {}
    }

    // One BOTTOM context bar per monitor (project/branch · active task · stats).
    Variants {
        model: Screens.screens
        BottomBar {}
    }

    // One summoned LEFT "what am I chasing" bar per monitor (hidden by default;
    // slides in on BarState.leftOpen — `qs ipc call leftbar toggle`).
    Variants {
        model: Screens.screens
        LeftBar {}
    }
}
