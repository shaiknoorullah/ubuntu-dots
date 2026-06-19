pragma ComponentBehavior: Bound

// TOP BAR  (mockup #top — floating glass pills + centred OLED Dynamic Island)
// ============================================================================
// A layer-shell PanelWindow pinned to the top edge, full width, transparent —
// the chrome is two FLOATING glass pills (not a solid bar) plus the carved
// OLED notch (Island.qml) centred on the top edge:
//
//   LEFT pill  (mockup .barpill, left):  context chip · workspaces · window
//   CENTRE     (mockup #notch):          the Dynamic Island
//   RIGHT pill (mockup .barpill, right): clock · volume · notification bell
//                                         click → right system panel
//
// The window is `Theme.barHeight` (84) tall so the notch has room to morph
// DOWN into the bar's empty space without the surface clipping it. The pills
// sit at the very top (mockup padding:7px). The window background is fully
// transparent — only the pills + notch are painted, so the wallpaper shows
// through the gaps (the mockup's pointer-events:none / >* pointer-events:auto).
//
// EXCLUSIVE ZONE: we reserve only the pill height (≈ 39px), NOT the full 84 —
// the lower portion is transparent click-through space the island morphs into,
// so tiled windows may sit under it (mockup tiles start at top:46px).
//
// DATA (cleanest source per field):
//   context   → Ctx.ctx / Ctx.accent        (eww-ctx.sh)
//   workspaces→ Hypr (native Quickshell.Hyprland)
//   window    → Hypr.activeToplevel.title    (native)
//   clock     → Time (native SystemClock)
//   volume    → SystemAudio.volume / .muted  (native PipeWire)
//   notifs    → SystemNotifs.count           (dunst or native fallback)
//   island    → Players (MPRIS) + Focus (adhd-focus.sh)
//
// All colour via Theme. The whole bar tints subtly to the live context accent
// (Theme.ctx is fed from Ctx so a12/a18/a35 follow it).

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.services
import Quickshell.Hyprland
import Quickshell.Services.Notifications

PanelWindow {
    id: root

    required property ShellScreen modelData

    screen: modelData
    color: "transparent"
    WlrLayershell.namespace: "quickshell-topbar"
    WlrLayershell.layer: WlrLayer.Top

    // Pin to the top edge, stretch full width (anchoring L+R stretches X).
    anchors.top: true
    anchors.left: true
    anchors.right: true

    implicitHeight: Theme.barHeight

    // Reserve only the pill band; the lower (notch-morph) area is click-through.
    exclusiveZone: Theme.barTopPad + Theme.pillHeight

    // Input mask — the window is 232px tall but only the three interactive
    // shapes (left pill, right pill, island notch) receive clicks.  The rest of
    // the transparent strip is click-through so tiled windows and titlebars
    // remain reachable.  Nested Region children default to Intersection.Combine
    // (union), giving us exactly the three interactive zones.
    mask: Region {
        Region { item: leftPill }
        Region { item: rightPill }
        Region { item: island }
    }

    // Feed the live context into the Theme so accent-tinted tokens (a12/a18/a35,
    // ctxAccent) follow the operator's current context everywhere.
    Binding {
        target: Theme
        property: "ctx"
        value: Ctx.ctx
    }

    // =======================================================================
    // LEFT PILL — context · workspaces · window  (mockup .barpill left)
    // =======================================================================
    GlassPill {
        id: leftPill

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: Theme.barSidePad
        anchors.topMargin: Theme.barTopPad

        RowLayout {
            spacing: 7

            // ---- Context chip (mockup .ctxpill: accent-tinted, dot + name) --
            StyledRect {
                Layout.preferredHeight: 24
                implicitWidth: ctxRow.implicitWidth + 24
                radius: Theme.pill
                color: Theme.a18

                RowLayout {
                    id: ctxRow

                    anchors.centerIn: parent
                    spacing: 7

                    Rectangle {
                        Layout.preferredWidth: 7
                        Layout.preferredHeight: 7
                        radius: width / 2
                        color: Ctx.accent
                    }

                    StyledText {
                        text: Ctx.ctx
                        color: Theme.fg
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                        font.bold: true
                    }
                }
            }

            // ---- Workspaces (native Hyprland) ------------------------------
            Workspaces {
                Layout.alignment: Qt.AlignVCenter
                screen: root.modelData
            }

            // ---- Active window title (mockup .winttl) ----------------------
            StyledText {
                Layout.fillWidth: false
                Layout.maximumWidth: 260
                Layout.leftMargin: 4
                text: Hypr.activeToplevel?.title ?? ""
                color: Theme.withAlpha(Theme.fg, 0.7)
                font.family: Theme.fontMono
                font.pixelSize: 12
                elide: Text.ElideRight
                visible: text.length > 0
            }
        }
    }

    // =======================================================================
    // CENTRE — the Dynamic Island / OLED notch
    // =======================================================================
    Island {
        id: island

        anchors.top: parent.top
        // Same top inset as the pills so the notch floats in line with them
        // (it morphs DOWN from here) instead of hugging the screen edge.
        anchors.topMargin: Theme.barTopPad
        anchors.horizontalCenter: parent.horizontalCenter
    }

    // =======================================================================
    // RIGHT PILL — clock · volume · notifications  (mockup .barpill right)
    // =======================================================================
    GlassPill {
        id: rightPill

        interactive: true
        active: BarState.quickPanelOpen
        onClicked: BarState.toggleQuickPanel()

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: Theme.barSidePad
        anchors.topMargin: Theme.barTopPad

        RowLayout {
            spacing: 7

            // ---- Clock (mockup .clock: HH:mm + dimmed date) ----------------
            RowLayout {
                spacing: 8

                StyledText {
                    text: Time.timeStr
                    color: Theme.fg
                    font.family: Theme.fontMono
                    font.pixelSize: 13
                    font.bold: true
                }

                StyledText {
                    text: Time.dateStr
                    color: Theme.comment
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                }
            }

            // ---- Volume -----------------------------------------------------
            RowLayout {
                spacing: 6

                MaterialIcon {
                    text: SystemAudio.muted ? "volume_off" : "volume_up"
                    color: Theme.withAlpha(Theme.fg, 0.66)
                    font.pixelSize: 16
                    Layout.preferredWidth: 16
                    Layout.alignment: Qt.AlignVCenter
                }

                StyledText {
                    text: SystemAudio.muted ? "muted" : `${SystemAudio.volume}`
                    color: Theme.withAlpha(Theme.fg, 0.66)
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                }
            }

            // ---- Notifications ---------------------------------------------
            Item {
                Layout.preferredWidth: bell.implicitWidth + (SystemNotifs.count > 0 ? 12 : 0)
                Layout.preferredHeight: 16

                MaterialIcon {
                    id: bell

                    anchors.verticalCenter: parent.verticalCenter
                    text: SystemNotifs.dnd ? "notifications_paused" : "notifications"
                    color: SystemNotifs.dnd ? Theme.orange : Theme.withAlpha(Theme.fg, 0.66)
                    font.pixelSize: 16
                }

                // Red count badge (mockup .badge), only when there are unread.
                Rectangle {
                    visible: SystemNotifs.count > 0
                    anchors.left: bell.right
                    anchors.leftMargin: 2
                    anchors.verticalCenter: bell.verticalCenter
                    anchors.verticalCenterOffset: -4
                    implicitWidth: Math.max(14, badgeText.implicitWidth + 6)
                    implicitHeight: 14
                    radius: Theme.pill
                    color: Theme.red

                    StyledText {
                        id: badgeText

                        anchors.centerIn: parent
                        text: `${SystemNotifs.count}`
                        color: Theme.base
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        font.bold: true
                    }
                }
            }
        }
    }

    // =======================================================================
    // GLASS PILL — reusable floating blurred pill  (mockup .barpill)
    // =======================================================================
    // A 32px-tall rounded translucent pill with a hairline border and a soft
    // drop shadow. Sizes to its content (the RowLayout placed inside it). Real
    // backdrop-blur needs a compositor blur rule on the `quickshell-topbar`
    // layer namespace (Hyprland 0.55+ Lua:
    // `hl.layer_rule({ match = { namespace = "quickshell-.*" }, blur = true })`);
    // the translucent glass colour reads correctly with or without it.
    // The single child (a RowLayout) is centred and the pill sizes to it +
    // horizontal padding. We measure the child via childrenRect so we don't
    // create a width<->fill cycle (the child must NOT anchors.fill the pill).
    component GlassPill: StyledRect {
        id: glass

        default property alias content: contentItem.data
        property bool interactive: false
        property bool active: false
        property bool hovered: false
        signal clicked

        // Equal inset on every side: the horizontal extra is forced to match the
        // vertical extra (pillHeight − contentHeight), so content sits the same
        // distance from all four edges instead of ~12px L/R vs ~4px T/B.
        implicitWidth: contentItem.childrenRect.width + (Theme.pillHeight - contentItem.childrenRect.height)
        implicitHeight: Theme.pillHeight
        radius: Theme.pill
        color: glass.active ? Theme.withAlpha(Theme.ctxAccent, 0.20)
            : glass.hovered ? Theme.withAlpha(Theme.base, 0.86)
            : Theme.panel
        border.width: 1
        border.color: glass.active ? Theme.withAlpha(Theme.ctxAccent, 0.44) : Theme.edge
        clip: true

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Theme.shine }
                GradientStop { position: 0.48; color: "transparent" }
                GradientStop { position: 1.0; color: Theme.withAlpha(Theme.ctxAccent, 0.055) }
            }
        }

        Item {
            id: contentItem
            anchors.centerIn: parent
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
        }

        MouseArea {
            anchors.fill: parent
            enabled: glass.interactive
            hoverEnabled: true
            cursorShape: glass.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
            onEntered: glass.hovered = true
            onExited: glass.hovered = false
            onClicked: glass.clicked()
        }
    }
}
