// ACTIVE WINDOW WIDGET  (pattern: caelestia modules/bar/components/ActiveWindow.qml)
// Reads Hypr.activeToplevel.title. `.lastIpcObject` holds extra raw fields
// (class, fullscreen, etc.) if you need them.

import QtQuick
import qs.components
import qs.services

StyledText {
    text: Hypr.activeToplevel?.title ?? ""
    color: Colours.palette.m3onSurface
    elide: Text.ElideRight
    font.pixelSize: 13
}
