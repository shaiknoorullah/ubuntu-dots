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
//   volume    → Volume.vol / .muted          (eww-vol.sh)
//   notifs    → Notifs.count                 (native NotificationServer)
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
        anchors.horizontalCenter: parent.horizontalCenter
    }

    // =======================================================================
    // RIGHT PILL — clock · volume · notifications  (mockup .barpill right)
    // =======================================================================
    GlassPill {
        id: rightPill

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

            // ---- Volume (mockup .tic 󰕾 62) ---------------------------------
            RowLayout {
                spacing: 6

                StyledText {
                    // Nerd Font speaker / muted glyphs (󰖁 muted, 󰕾 high).
                    text: Volume.muted ? "\u{F0581}" : "\u{F057E}"
                    color: Theme.withAlpha(Theme.fg, 0.66)
                    font.family: Theme.fontMono
                    font.pixelSize: 13
                }

                StyledText {
                    text: Volume.muted ? "muted" : `${Volume.vol}`
                    color: Theme.withAlpha(Theme.fg, 0.66)
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                }
            }

            // ---- Notifications (mockup .tic 󰂚 + .badge) --------------------
            Item {
                Layout.preferredWidth: bell.implicitWidth + (Notifs.count > 0 ? 12 : 0)
                Layout.preferredHeight: 16

                StyledText {
                    id: bell

                    anchors.verticalCenter: parent.verticalCenter
                    // Nerd Font bell (󰂚).
                    text: "\u{F009A}"
                    color: Theme.withAlpha(Theme.fg, 0.66)
                    font.family: Theme.fontMono
                    font.pixelSize: 13
                }

                // Red count badge (mockup .badge), only when there are unread.
                Rectangle {
                    visible: Notifs.count > 0
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
                        text: `${Notifs.count}`
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
    // layer namespace (Hyprland: `layerrule = blur, quickshell-topbar`); the
    // translucent glass colour reads correctly with or without it.
    // The single child (a RowLayout) is centred and the pill sizes to it +
    // horizontal padding. We measure the child via childrenRect so we don't
    // create a width<->fill cycle (the child must NOT anchors.fill the pill).
    component GlassPill: StyledRect {
        default property alias content: contentItem.data

        implicitWidth: contentItem.childrenRect.width + 24
        implicitHeight: Theme.pillHeight
        radius: Theme.pill
        color: Theme.glass
        border.width: 1
        border.color: Theme.bd

        Item {
            id: contentItem
            anchors.centerIn: parent
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
        }
    }
}
