// CLOCK WIDGET  (pattern: caelestia modules/bar/components/Clock.qml)
// Pure binding to the Time singleton — no Timer here, SystemClock drives it.

import QtQuick
import qs.components
import qs.services

StyledText {
    horizontalAlignment: Text.AlignHCenter
    text: Time.timeStr
    color: Colours.palette.m3tertiary
    font.pixelSize: 14
    font.bold: true
}
