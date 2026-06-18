// BASE LAYER-SHELL WINDOW  (pattern: caelestia components/containers/StyledWindow.qml)
//
// Wraps PanelWindow + WlrLayershell. PanelWindow (from `import Quickshell`) is a
// layer-shell surface; `import Quickshell.Wayland` adds the WlrLayershell
// attached props (namespace, layer, exclusionMode, keyboardFocus).
//
// Anchoring: set anchors.{top,bottom,left,right}=true to pin edges. Anchoring two
// opposite edges stretches the window across that axis. exclusiveZone reserves
// space so tiled windows don't overlap the bar (set automatically from the
// anchored edge unless exclusionMode is overridden).

import Quickshell
import Quickshell.Wayland

PanelWindow {
    required property string name

    WlrLayershell.namespace: `quickshell-${name}`
    WlrLayershell.layer: WlrLayer.Top
    color: "transparent"
}
