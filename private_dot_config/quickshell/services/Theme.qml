pragma Singleton

// THEME SINGLETON — DRACULA OPERATOR PALETTE
// (pattern: caelestia services/Colours.qml — a pragma Singleton exposing a flat
//  set of `color` properties; widgets reference Theme.purple etc., never hex.)
//
// This is the single source of truth for every colour in the bottom + left bars.
// Values mirror ~/ubuntu-dots/.chezmoidata.yaml `dracula:` / `context:` blocks
// EXACTLY (the operator's own Dracula variant, already in use by polybar + eww),
// so the quickshell shell converges on the same palette as the rest of the dots.
//
// NOTE on the two colour singletons:
//   * Colours.qml   — Material-3 token palette used by the generic caelestia
//                     scaffold components (StyledRect/StyledText defaults).
//   * Theme.qml     — THIS — the Dracula brand palette the ADHD-OS mockup is
//                     painted in. The bottom/left bars below paint with Theme.*
//                     to match docs/superpowers/mockups/adhd-os.html.
//
// Auto-registers as `Theme` via `pragma Singleton` + basename (no qmldir, per
// caelestia). Any file: `import qs.services` -> `Theme.purple`, `Theme.glass2`…

import QtQuick

QtObject {
    id: root

    // ── Core Dracula (from .chezmoidata.yaml `dracula:`) ───────────────
    readonly property color base: "#1a1a2e"
    readonly property color bg: "#13131f"
    readonly property color fg: "#f8f8f2"
    readonly property color comment: "#585880"
    readonly property color selection: "#2d2d44"
    readonly property color surface0: "#232336"
    readonly property color surface1: "#2d2d44"
    readonly property color surface2: "#3a3a52"
    readonly property color subtext0: "#9a9ab8"

    readonly property color purple: "#bd93f9"
    readonly property color pink: "#ff79c6"
    readonly property color blue: "#6a8cff"
    readonly property color cyan: "#8be9fd"
    readonly property color green: "#50fa7b"
    readonly property color orange: "#ff9e3b"
    readonly property color red: "#ff4d4d"
    readonly property color yellow: "#f5d547"

    // ── Derived "glass" / surface tints (mirror the mockup CSS vars) ───
    // The mockup uses translucent glass panels; we approximate its
    // --glass2 / --s1 / --s2 / --bd / --hov over our base.
    readonly property color glass: root.withAlpha(root.base, 0.72)   // --glass
    readonly property color glass2: root.withAlpha(root.bg, 0.85)    // --glass2
    readonly property color s1: root.withAlpha(root.fg, 0.04)        // --s1
    readonly property color s2: root.withAlpha(root.fg, 0.07)        // --s2
    readonly property color bd: root.withAlpha(root.fg, 0.09)        // --bd  (border)
    readonly property color hov: root.withAlpha(root.fg, 0.10)       // --hov

    // ── Radii (mirror mockup --rad/--radbar/--pill/--chip) ─────────────
    readonly property int rad: 16
    readonly property int radBar: 20
    readonly property int pill: 99
    readonly property int chip: 9

    // ── OLED notch surface (mockup #notch: pure black, top-less border) ─
    readonly property color oled: "#000000"
    readonly property color oledBorder: root.withAlpha("#ffffff", 0.06)

    // ── Top-bar + notch metrics (mockup #top / .barpill / #notch) ──────
    // Added for TopBar.qml + Island.qml. The bottom/left bars don't use these.
    readonly property int barHeight: 84      // #top height (incl. notch travel)
    readonly property int barTopPad: 7       // #top padding-top
    readonly property int barSidePad: 14     // #top side padding
    readonly property int pillHeight: 32     // .barpill height
    readonly property int notchW: 226        // #notch collapsed width
    readonly property int notchH: 30         // #notch collapsed height
    readonly property int notchHoverW: 244   // #notch:hover width
    readonly property int notchOpenW: 396    // #notch.open width
    readonly property int notchOpenH: 194    // #notch.open height

    // ── Typography (mockup --mono) ─────────────────────────────────────
    // JetBrainsMono Nerd Font carries the 󰒮 󰒭   transport glyphs.
    readonly property string fontMono: "JetBrainsMono Nerd Font"

    // ── Motion (mockup --ease = cubic-bezier(.25,1,.5,1)) ──────────────
    // calm, settle-in easing — exposed as bezier control points for
    // Easing.BezierSpline. Kept here so every animation in the bars uses it.
    readonly property var calmBezier: [0.25, 1, 0.5, 1]
    readonly property int durFast: 200
    readonly property int durBase: 350
    readonly property int durSlow: 480

    // ── Context accent map (.chezmoidata.yaml `context:`) ──────────────
    // accentFor("work") -> purple, "lab" -> pink, "agents" -> cyan,
    // "personal"/unknown -> green. Mirrors eww-ctx.sh exactly.
    function accentFor(ctx: string): color {
        switch (ctx) {
        case "work":
            return root.purple;
        case "lab":
            return root.pink;
        case "agents":
            return root.cyan;
        case "personal":
            return root.green;
        default:
            return root.green;
        }
    }

    // ── Live context accent (driven by EwwCtx.ctx) ─────────────────────
    // TopBar.qml binds `Theme.ctx = EwwCtx.ctx` so the context pill, the
    // active workspace, and the island live-activity all tint to the
    // operator's current context. The mockup --a12/--a18/--a35 are the
    // accent at 12/18/35% alpha (purple there; the live accent here).
    property string ctx: "personal"
    readonly property color ctxAccent: root.accentFor(root.ctx)
    readonly property color a12: root.withAlpha(root.ctxAccent, 0.12)
    readonly property color a18: root.withAlpha(root.ctxAccent, 0.18)
    readonly property color a35: root.withAlpha(root.ctxAccent, 0.35)

    // Tint a colour with alpha (caelestia's Colours.alpha equivalent).
    function withAlpha(c: color, a: real): color {
        return Qt.rgba(c.r, c.g, c.b, a);
    }
}
