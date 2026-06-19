pragma ComponentBehavior: Bound

// BOTTOM CONTEXT BAR  (mockup #bottom — the calm "where am I" strip)
// (window pattern: caelestia StyledWindow / PanelWindow + WlrLayershell)
//
// A layer-shell panel pinned to the BOTTOM edge. The visible surface is a single
// centred glass PILL (mockup: width 1860, height 30, blurred glass2, --pill
// radius) holding three clusters, justified space-between:
//
//   LEFT   project · branch · context — "where the work lives"
//            project (purple) · branch (green) · context·region (muted)
//   CENTER active task + live elapsed
//            active · <task> · <elapsed cyan>            (ActiveTask service)
//   RIGHT  focus-score ring · streak · pips · coffee/walks · encouragement
//            (Stats service) — SHAME-FREE: positive framing only, no red/scold.
//
// Data: Ctx, ActiveTask, Stats singletons (each polls an ~/.local/bin script).
// The bar hides itself (slides down + fades) while the LEFT bar is summoned,
// mirroring the mockup's `body.state-left #bottom{opacity:0;translateY(8px)}`.
// LeftBar drives that via the shared `BarState` singleton.

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

    WlrLayershell.namespace: "quickshell-bottombar"
    WlrLayershell.layer: WlrLayer.Top

    // Pin to the bottom edge, stretch horizontally. Reserve the bar's height so
    // tiled windows stop above it instead of being hidden underneath.
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 30 + bottomGap * 2
    exclusiveZone: 30 + bottomGap

    readonly property int bottomGap: 8

    // ── The centred glass pill ─────────────────────────────────────────
    StyledRect {
        id: pill

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.bottomGap

        // Mockup is 1860 on a 1920 screen — keep ~30px breathing room each side.
        width: Math.min(1860, root.width - 60)
        height: 30
        radius: Theme.pill
        color: Theme.panelStrong
        border.width: 1
        border.color: Theme.edge
        clip: true

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Theme.shine }
                GradientStop { position: 0.58; color: "transparent" }
                GradientStop { position: 1.0; color: Theme.shade }
            }
        }

        // Calm slide-down + fade when the left bar is summoned.
        opacity: BarState.leftOpen ? 0 : 1
        transform: Translate {
            y: BarState.leftOpen ? 8 : 0
            Behavior on y {
                NumberAnimation {
                    duration: Theme.durBase
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.25, 1, 0.5, 1, 1, 1]
                }
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: Theme.durBase
                easing.type: Easing.OutCubic
            }
        }
        visible: opacity > 0.01

        // ── LEFT cluster: project · branch · context ──────────────────
        RowLayout {
            id: left

            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 14

            // project (accented by current context)
            RowLayout {
                spacing: 6
                MaterialIcon {
                    text: "folder_open"
                    color: Ctx.accent
                    font.pixelSize: 15
                    Layout.preferredWidth: 15
                    Layout.alignment: Qt.AlignVCenter
                }
                StyledText {
                    text: Project.name
                    color: Ctx.accent
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                    font.bold: true
                }
            }
            RowLayout {
                spacing: 6
                MaterialIcon {
                    text: "fork_right"
                    color: Theme.green
                    font.pixelSize: 15
                    Layout.preferredWidth: 15
                    Layout.alignment: Qt.AlignVCenter
                }
                StyledText {
                    text: Project.branch
                    color: Theme.green
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                }
            }
            StyledText {
                text: `${Ctx.ctx} · ${Project.region}`
                color: Theme.comment
                font.family: Theme.fontMono
                font.pixelSize: 12
            }
        }

        // ── CENTER cluster: active task + elapsed ─────────────────────
        RowLayout {
            id: center

            anchors.centerIn: parent
            spacing: 14

            RowLayout {
                spacing: 6
                MaterialIcon {
                    text: "timer"
                    color: Theme.comment
                    font.pixelSize: 15
                    Layout.preferredWidth: 15
                    Layout.alignment: Qt.AlignVCenter
                }
                StyledText {
                    text: "active"
                    color: Theme.comment
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                }
            }
            StyledText {
                text: ActiveTask.task
                color: Theme.fg
                font.family: Theme.fontMono
                font.pixelSize: 12
                elide: Text.ElideRight
                Layout.maximumWidth: 420
            }
            StyledText {
                text: ActiveTask.elapsed
                color: Theme.cyan
                font.family: Theme.fontMono
                font.pixelSize: 12
                font.bold: true
                visible: ActiveTask.active
            }
        }

        // ── RIGHT cluster: focus ring · streak · pips · tallies · cheer ─
        RowLayout {
            id: right

            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 14

            // focus score ring + number
            RowLayout {
                spacing: 6
                FocusRing {
                    value: Stats.focusScore
                    color: Theme.green
                    trackColor: Theme.s2
                    Layout.alignment: Qt.AlignVCenter
                }
                StyledText {
                    text: `focus ${Stats.focusScore}`
                    color: Theme.fg
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                }
            }

            // streak — never "broken", always a count
            RowLayout {
                spacing: 6
                MaterialIcon {
                    text: "local_fire_department"
                    color: Theme.comment
                    font.pixelSize: 15
                    Layout.preferredWidth: 15
                    Layout.alignment: Qt.AlignVCenter
                }
                StyledText {
                    text: `${Stats.streak}-day`
                    color: Theme.comment
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                }
            }

            // pips — a tiny 4-pip rhythm strip (filled up to streak%4-ish).
            // Purely decorative consistency dots; an "off" pip is muted, not red.
            RowLayout {
                spacing: 3
                Repeater {
                    model: 4
                    StyledRect {
                        required property int index
                        implicitWidth: 6
                        implicitHeight: 6
                        radius: 2
                        // light up pips proportional to focus score (calm fill)
                        color: (index < Math.round(Stats.focusScore / 25))
                            ? Theme.green : Theme.s2
                    }
                }
            }

            // coffee + walks tallies
            RowLayout {
                spacing: 6
                MaterialIcon {
                    text: "local_cafe"
                    color: Theme.comment
                    font.pixelSize: 15
                    Layout.preferredWidth: 15
                    Layout.alignment: Qt.AlignVCenter
                }
                StyledText {
                    text: `${Stats.coffee}`
                    color: Theme.comment
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                }
                StyledText {
                    text: "·"
                    color: Theme.comment
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                }
                MaterialIcon {
                    text: "directions_walk"
                    color: Theme.comment
                    font.pixelSize: 15
                    Layout.preferredWidth: 15
                    Layout.alignment: Qt.AlignVCenter
                }
                StyledText {
                    text: `${Stats.walks} walks`
                    color: Theme.comment
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                }
            }

            // encouragement — warm, never scolding (script guarantees this)
            StyledText {
                text: Stats.encourage
                color: Theme.yellow
                font.family: Theme.fontMono
                font.pixelSize: 12
                font.bold: true
            }
        }
    }
}
