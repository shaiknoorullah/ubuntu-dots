// COVER ART — rounded MPRIS album-art tile w/ Dracula-gradient fallback.
// (extracted from Island.qml so both player layers can reuse it.)

import QtQuick
import Quickshell.Widgets
import qs.services

ClippingRectangle {
    id: cov

    property url source: ""
    property int rad: 13

    radius: rad
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        visible: art.status !== Image.Ready
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Theme.purple }
            GradientStop { position: 0.5; color: Theme.pink }
            GradientStop { position: 1.0; color: Theme.orange }
        }
    }

    Image {
        id: art
        anchors.fill: parent
        source: cov.source
        fillMode: Image.PreserveAspectCrop
        cache: true
        asynchronous: true
        sourceSize.width: width
        sourceSize.height: height
    }
}
