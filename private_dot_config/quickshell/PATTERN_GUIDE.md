# Quickshell Hyprland Bar — Pattern Guide

Derived by studying `caelestia-dots/shell` (cloned at build time). All snippets
below are quoted from real caelestia files unless marked "scaffold" (= the
minimal working files in this same directory). Caelestia uses a heavily
abstracted plugin (`Caelestia.*` C++ modules, `Config`, `Tokens`); this guide
strips those to the plain Quickshell APIs you can use without the plugin.

Caelestia's actual bar is **vertical, left-anchored, drawn inside one giant
full-screen `PanelWindow` ("drawers")** with the bar as content and an SDF blob
border. That is advanced. The faithful but minimal scaffold here is a normal
top bar — same primitives, no blob plugin.

---

## 0. Module / import system (IMPORTANT — no qmldir needed)

Caelestia has **zero `qmldir` files**. Quickshell auto-exposes the config root
under the import prefix `qs`, mapping `qs.<subdir>` to that folder:

```qml
import qs.services        // -> ./services/*.qml
import qs.components       // -> ./components/*.qml
import qs.modules.bar      // -> ./modules/bar/*.qml
import "components"        // relative import of a sibling subfolder (used for
                           //   modules/bar's *local* components subfolder)
```

- A file with `pragma Singleton` is auto-registered and referenced by its
  **basename** (`Colours`, `Time`, `Hypr`, `Players`). No `singleton` qmldir
  line required.
- A normal `.qml` file becomes a component named by its basename.
- Hot reload: caelestia sets `settings.watchFiles: true` on `ShellRoot`.

---

## 1. Entry point, ShellRoot, PanelWindow, layer-shell, multi-monitor

### Root — `shell.qml` (caelestia, trimmed)
```qml
import Quickshell
ShellRoot {
    settings.watchFiles: true
    Background {}
    Drawers {}        // <- contains the Variants-per-screen panels
    // ... more global scopes
}
```
`ShellRoot` (from `import Quickshell`) is the mandatory root. quickshell loads
`shell.qml` by default.

### Multi-monitor — `Variants` + `Scope` (caelestia `modules/drawers/Drawers.qml`, verbatim)
```qml
import Quickshell
import qs.services
Variants {
    model: Screens.screens                 // list<ShellScreen>
    Scope {
        id: scope
        required property ShellScreen modelData   // injected per instance
        Exclusions { screen: scope.modelData; bar: content.bar }
        ContentWindow { id: content; screen: scope.modelData }
    }
}
```
`Variants` (NOT `Repeater`) is the quickshell idiom for instantiating
non-visual / window objects once per model element. Each delegate declares
`required property <T> modelData` and Variants fills it. `Scope` is a
non-visual grouping node when you need several windows per screen.

### The layer-shell window — `PanelWindow` + `WlrLayershell`
Base wrapper (caelestia `components/containers/StyledWindow.qml`, verbatim):
```qml
import Quickshell
import Quickshell.Wayland
PanelWindow {
    required property string name
    WlrLayershell.namespace: `caelestia-${name}`
    color: "transparent"
}
```
- `PanelWindow` (from `import Quickshell`) **is** a layer-shell surface.
- `import Quickshell.Wayland` adds the `WlrLayershell` attached props:
  `.namespace`, `.layer` (`WlrLayer.Background|Bottom|Top|Overlay`),
  `.exclusionMode` (`ExclusionMode.Auto|Normal|Ignore`),
  `.keyboardFocus` (`WlrKeyboardFocus.None|OnDemand|Exclusive`).

Anchoring & exclusive zones (caelestia `Background.qml` / `Exclusions.qml`):
```qml
anchors.top: true; anchors.bottom: true; anchors.left: true; anchors.right: true
WlrLayershell.exclusionMode: ExclusionMode.Ignore   // I reserve space manually
```
Anchoring two opposite edges stretches that axis. To reserve space for a bar,
either anchor to one edge and set `exclusiveZone: <thickness>`, OR (caelestia's
trick for a morphing bar) keep the window `ExclusionMode.Ignore` and create a
separate zero-size window per edge whose only job is the exclusion:
```qml
// caelestia modules/drawers/Exclusions.qml (verbatim core)
ExclusionZone { anchors.left: true; exclusiveZone: root.bar.exclusiveZone }
// component ExclusionZone: StyledWindow { exclusiveZone: ...; mask: Region {}; implicitWidth: 1 }
```

The drawers window also shows the fullscreen-aware layer switching pattern
(caelestia `ContentWindow.qml`):
```qml
WlrLayershell.layer: (fsTransitionProg > 0 && Config.general.showOverFullscreen)
    ? WlrLayer.Overlay : WlrLayer.Top
WlrLayershell.keyboardFocus: visibilities.launcher ? WlrKeyboardFocus.OnDemand
                                                    : WlrKeyboardFocus.None
mask: hasFullscreen ? emptyRegion : regions   // input mask via Region {}
```

**Scaffold equivalents:** `components/StyledWindow.qml`, `modules/bar/BarWindow.qml`
(top-anchored, `exclusiveZone: bar.implicitHeight`), `shell.qml`.

---

## 2. Hyprland workspaces + active window, and MPRIS

### Hyprland (`import Quickshell.Hyprland`)
Core reactive surface (caelestia `services/Hypr.qml`):
```qml
readonly property var toplevels: Hyprland.toplevels        // ObjectModel; .values
readonly property var workspaces: Hyprland.workspaces      // .values
readonly property var monitors: Hyprland.monitors
readonly property HyprlandToplevel activeToplevel: Hyprland.activeToplevel
readonly property HyprlandWorkspace focusedWorkspace: Hyprland.focusedWorkspace
readonly property HyprlandMonitor focusedMonitor: Hyprland.focusedMonitor
readonly property int activeWsId: focusedWorkspace?.id ?? 1
function dispatch(req: string): void { Hyprland.dispatch(req); }
function monitorFor(s: ShellScreen): HyprlandMonitor { return Hyprland.monitorFor(s); }
```
- Per-object raw JSON is `obj.lastIpcObject` — e.g. workspace occupancy:
  `ws.lastIpcObject.windows > 0`; fullscreen: `t.lastIpcObject.fullscreen > 1`.
- Active window title: `Hyprland.activeToplevel?.title`.
- **Models are not auto-refreshed for all events.** Caelestia listens and
  refreshes explicitly (verbatim):
```qml
Connections {
    target: Hyprland
    function onRawEvent(event: HyprlandEvent): void {
        const n = event.name;
        if (n.endsWith("v2")) return;
        if (["workspace","moveworkspace","activespecial","focusedmon"].includes(n)) {
            Hyprland.refreshWorkspaces(); Hyprland.refreshMonitors();
        } else if (["openwindow","closewindow","movewindow"].includes(n)) {
            Hyprland.refreshToplevels(); Hyprland.refreshWorkspaces();
        } // ... window/group/fullscreen -> refreshToplevels()
    }
}
```
Workspace click (caelestia `Workspaces.qml`): `Hypr.dispatch(`workspace ${ws}`)`.

### MPRIS (`import Quickshell.Services.Mpris`)
Caelestia `services/Players.qml`:
```qml
readonly property list<MprisPlayer> list: Mpris.players.values
readonly property MprisPlayer active: /* manual ?? aliased ?? */ list[0] ?? null
```
`MprisPlayer` fields used by the bar/media UI: `trackTitle`, `trackArtist`,
`trackAlbum`, `trackArtUrl`, `isPlaying`, `position`, `length`, `canSeek`,
`positionSupported`, `shuffle`/`shuffleSupported`,
`loopState` (`MprisLoopState.None|Track|Playlist`), and methods
`togglePlaying()/play()/pause()/next()/previous()/stop()`.

**Scaffold:** `services/Hypr.qml`, `services/Players.qml`,
`modules/bar/components/Workspaces.qml`, `.../ActiveWindow.qml`, `.../Media.qml`.

---

## 3. Running scripts (`Process`) and polling (`Timer`)

`import Quickshell.Io` gives `Process`, `StdioCollector`, `FileView`, `IpcHandler`.

One-shot with captured stdout (caelestia `services/Brightness.qml`, verbatim):
```qml
Process {
    id: ddcProc
    command: ["ddcutil", "detect", "--brief"]
    stdout: StdioCollector {
        onStreamFinished: root.ddcMonitors = text.trim().split("\n\n") /* ... */
    }
}
// fire it: ddcProc.running = true
```
Fire-and-forget (no output): `Quickshell.execDetached(["brightnessctl","s","50%"])`.

Polling loop (caelestia `services/Time.qml` uses `SystemClock` for clocks;
generic polling uses a `Timer`):
```qml
Timer {
    interval: 500            // ms
    running: true
    repeat: true             // omit for one-shot
    triggeredOnStart: true   // fire immediately on load
    onTriggered: proc.running = true
}
```
Clocks specifically should use `SystemClock { precision: SystemClock.Seconds }`
(caelestia `Time.qml`) — NOT a polling Timer.

Watch a file instead of polling (caelestia `Colours.qml`):
```qml
FileView { path: ".../scheme.json"; watchChanges: true
           onFileChanged: reload(); onLoaded: root.load(text()) }
```

**Scaffold:** `services/Weather.qml` (Process+StdioCollector+Timer),
`services/Time.qml` (SystemClock).

---

## 4. Theme / Colours singleton (NO scattered hex)

Caelestia `services/Colours.qml` is a `pragma Singleton` exposing a Material-3
token object; every widget reads `Colours.palette.m3*` / `Colours.tPalette.m3*`
(the `tPalette` variant applies transparency). The palette is a `QtObject`
component with one `property color m3<token>` per M3 role, e.g.:
```qml
component M3Palette: QtObject {
    property color m3surface: "#191114"
    property color m3onSurface: "#efdfe2"
    property color m3primary: "#ffb0ca"
    // ... full M3 set + term0..term15
}
```
Live theming: a `FileView` watches `scheme.json` and rewrites the palette props
(`load()` maps `m3<name>` JSON keys onto the object). Helpers like
`alpha()/layer()/on()` derive tints so widgets never hardcode variants.

Rule enforced throughout: **widgets reference the singleton, never a hex
literal.** Colour transitions animate because `StyledRect`/`StyledText` put a
`Behavior on color { CAnim {} }` on themselves.

**Scaffold:** `services/Colours.qml` (static M3 palette + `alpha()`, with the
FileView live-reload block included but commented).

---

## 5. Minimal COMPLETE bar PanelWindow (quoted from scaffold)

`modules/bar/BarWindow.qml` (the window) + `modules/bar/Bar.qml` (content):
```qml
// BarWindow.qml
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.services
StyledWindow {
    id: root
    required property ShellScreen modelData
    screen: modelData
    name: "bar"
    anchors.top: true; anchors.left: true; anchors.right: true
    implicitHeight: bar.implicitHeight
    exclusiveZone: bar.implicitHeight
    StyledRect { anchors.fill: parent; color: Colours.alpha(Colours.palette.m3surface, 0.85) }
    Bar { id: bar; anchors.fill: parent; screen: root.modelData }
}
```
```qml
// Bar.qml  (content: workspaces left, title center, media+clock right)
import QtQuick
import QtQuick.Layouts
import "components"
import qs.components
import qs.services
Item {
    id: root
    required property ShellScreen screen
    implicitHeight: 36
    RowLayout { anchors.left: parent.left; anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                Workspaces { screen: root.screen } }
    ActiveWindow { anchors.centerIn: parent; width: Math.min(implicitWidth, root.width*0.4) }
    RowLayout { anchors.right: parent.right; anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter; spacing: 12
                Media {}; Clock {} }
}
```
Spawned per monitor by `shell.qml`'s `Variants { model: Screens.screens; BarWindow {} }`.

Two representative widgets (scaffold):
```qml
// Clock.qml — pure binding, no timer (SystemClock drives Time)
StyledText { text: Time.timeStr; color: Colours.palette.m3tertiary; font.bold: true }
```
```qml
// Workspaces.qml core — occupancy + active-id from Hypr, click dispatches
readonly property var occupied: { const occ={};
    for (const ws of Hypr.workspaces.values) occ[ws.id]=ws.lastIpcObject.windows>0;
    return occ; }
StyledRect {                                   // each dot
    readonly property bool active: Hypr.activeWsId === ws
    implicitWidth: active ? 22 : 10            // active pill is wider
    color: active ? Colours.palette.m3primary : ...
    Behavior on implicitWidth { Anim {} }      // morphs smoothly
    MouseArea { anchors.fill: parent; onClicked: Hypr.dispatch(`workspace ${ws}`) }
}
```

---

## 6. Media player + notch/island morph + animations

### Animations: `Behavior` + a shared `Anim`/`CAnim` preset
Caelestia funnels every motion through `components/Anim.qml`
(a `NumberAnimation` subclass with an M3 motion enum) and `CAnim.qml`
(`ColorAnimation`). Usage everywhere:
```qml
Behavior on implicitWidth { Anim {} }                 // spatial
Behavior on color { CAnim {} }                        // colour
Behavior on opacity { Anim { type: Anim.DefaultEffects } }
```
State-driven morphs use `states:` + `transitions:` with `Anim` (caelestia
`BarWrapper.qml` animates `implicitWidth` between "" and "visible").

### The island/notch morph (caelestia `modules/bar/popouts/Wrapper.qml`)
The bar popout/island is an `Item` whose `implicitWidth/implicitHeight` follow
the active child's size, animated so the surrounding background blob deforms to
match:
```qml
readonly property real nonAnimWidth: children.find(c => c.shouldBeActive)?.implicitWidth
                                     ?? content.implicitWidth
implicitWidth: nonAnimWidth
Behavior on implicitWidth { Anim { duration: root.animLength; easing: root.animCurve } }
Behavior on implicitHeight { enabled: root.offsetScale < 1
                             Anim { duration: root.animLength; easing: root.animCurve } }
```
Child loaders cross-fade via a state machine (`Comp: Loader` with
`states: State { name:"active"; when: shouldBeActive; PropertyChanges { active:true; opacity:1 } }`
and `transitions` running `Anim` on opacity + a `PropertyAction` on `active` so
the loader loads on the same frame it becomes visible). That same `implicitWidth`
animation is what produces caelestia's "dynamic island" feel.

### Media transport + the position-tick gotcha (caelestia `dashboard/media/Details.qml`)
```qml
Timer {                                   // MprisPlayer.position does NOT self-tick
    running: Players.active?.isPlaying ?? false
    interval: GlobalConfig.dashboard.mediaUpdateInterval
    triggeredOnStart: true; repeat: true
    onTriggered: Players.active?.positionChanged()   // force the binding to refresh
}
StyledText { text: Players.active?.trackTitle ?? ""; animate: true }   // cross-fade title
// transport buttons:
IconButton { icon: Players.active?.isPlaying ? "pause" : "play_arrow"
             disabled: !Players.active?.canTogglePlaying
             onClicked: Players.active?.togglePlaying() }
IconButton { icon: "skip_next"; disabled: !Players.active?.canGoNext
             onClicked: Players.active?.next() }
// seek slider value: Players.active.position / (Players.active.length || 1)
```

**Scaffold:** `modules/bar/components/Media.qml` combines all three — a collapsed
pill that morphs to an expanded island on hover via `Behavior on implicitWidth`,
the position-tick `Timer`, and `togglePlaying()` on click.

---

## File map (this directory)
- `shell.qml` — ShellRoot + Variants per monitor
- `services/` — Colours (theme), Hypr, Players (MPRIS), Time, Weather (Process+Timer), Screens
- `components/` — Anim, CAnim, StyledRect, StyledText, MaterialIcon, StyledWindow
- `modules/bar/` — Bar (content), BarWindow (layer-shell surface)
- `modules/bar/components/` — Workspaces, Clock, ActiveWindow, Media (island morph)
```
```
