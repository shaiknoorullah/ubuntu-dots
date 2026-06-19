pragma Singleton

// BAR STATE SINGLETON — shared UI state across the three bars
// (pattern: caelestia services/* singletons that hold cross-module UI flags,
//  e.g. its visibility / popout state singletons.)
//
// The mockup is a small state machine (body.state-{idle,left,focus,...}). The
// only cross-bar coupling the bottom + left bars need is "is the LEFT bar
// summoned?" — when it is, the bottom bar slides away (mockup:
// `body.state-left #bottom{opacity:0; transform:translateY(8px)}`).
//
// LeftBar binds its slide-in to `leftOpen`; BottomBar binds its slide-out to the
// same flag. A keybind / IPC handler / hover trigger flips it via toggleLeft().
// Kept deliberately tiny so any future trigger (Hyprland keybind -> qs ipc,
// edge-hover MouseArea, command-palette action) can drive it.

import Quickshell
import QtQuick
import Quickshell.Hyprland
import Quickshell.Io

Singleton {
    id: root

    // Is the summoned LEFT "what am I chasing" bar visible?
    property bool leftOpen: false

    function toggleLeft(): void {
        root.leftOpen = !root.leftOpen;
    }
    function openLeft(): void {
        root.leftOpen = true;
    }
    function closeLeft(): void {
        root.leftOpen = false;
    }

    // IPC so a Hyprland keybind can summon the bar:
    //   bind = SUPER, SPACE, exec, qs ipc call leftbar toggle
    IpcHandler {
        target: "leftbar"

        function toggle(): void {
            root.toggleLeft();
        }
        function open(): void {
            root.openLeft();
        }
        function close(): void {
            root.closeLeft();
        }
    }

    // The dedicated centered "start a block" command palette (FocusPalette.qml),
    // summoned by $mod+Shift+Return → `qs ipc call palette open`.
    property bool paletteOpen: false

    function togglePalette(): void {
        root.paletteOpen = !root.paletteOpen;
    }
    function openPalette(): void {
        root.paletteOpen = true;
    }
    function closePalette(): void {
        root.paletteOpen = false;
    }

    IpcHandler {
        target: "palette"

        function toggle(): void {
            root.togglePalette();
        }
        function open(): void {
            root.openPalette();
        }
        function close(): void {
            root.closePalette();
        }
    }

    // The quickshell wallpaper picker widget (WallpaperPicker.qml),
    // summoned by $mod+Shift+W → `qs ipc call wallpaper open`.
    property bool wallpaperOpen: false

    function toggleWallpaper(): void { root.wallpaperOpen = !root.wallpaperOpen; }
    function openWallpaper(): void   { root.wallpaperOpen = true; }
    function closeWallpaper(): void  { root.wallpaperOpen = false; }

    IpcHandler {
        target: "wallpaper"

        function toggle(): void { root.toggleWallpaper(); }
        function open(): void   { root.openWallpaper(); }
        function close(): void  { root.closeWallpaper(); }
    }
}
