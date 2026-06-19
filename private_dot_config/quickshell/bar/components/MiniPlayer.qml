// MINI PLAYER — collapsed island layer.
// art (ringed by playback progress) · title · cava bars that cross-fade into
// prev/play/next on hover (the island stays collapsed; click opens FullPlayer).

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

RowLayout {
    id: root

    property var player: null
    property bool hovered: false

    spacing: 9

    // ---- Album art wrapped by a thin progress ring --------------------------
    ProgressRing {
        Layout.preferredWidth: 24
        Layout.preferredHeight: 24
        ringWidth: 2
        color: Theme.ctxAccent
        value: {
            const len = root.player?.length ?? 0;
            return len > 0 ? (root.player?.position ?? 0) / len : 0;
        }

        CoverArt {
            anchors.fill: parent
            rad: width / 2
            source: root.player?.trackArtUrl ?? ""
        }
    }

    // ---- Track title --------------------------------------------------------
    StyledText {
        Layout.maximumWidth: 150
        text: root.player?.trackTitle ?? "—"
        color: Theme.withAlpha(Theme.fg, 0.85)
        font.family: Theme.fontMono
        font.pixelSize: 11
        elide: Text.ElideRight
    }

    // ---- cava ⇄ transport crossfade slot (fixed width to limit morph jitter) -
    Item {
        Layout.preferredWidth: 80
        Layout.preferredHeight: 20

        Visualizer {
            anchors.centerIn: parent
            width: 64
            height: 18
            opacity: root.hovered ? 0 : 1
            visible: opacity > 0
            values: root.bucket(Cava.values, 7)
            gap: 3
            maxH: 18
            minH: 2
            radius: 1.5
            color: Theme.ctxAccent
            Behavior on opacity { NumberAnimation { duration: Theme.durFast } }
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: 10
            opacity: root.hovered ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.durFast } }

            MediaButton {
                icon: "skip_previous"
                size: 18
                enabled: root.player?.canGoPrevious ?? false
                onClicked: root.player?.previous()
            }
            MediaButton {
                icon: (root.player?.isPlaying ?? false) ? "pause" : "play_arrow"
                size: 20
                enabled: root.player?.canTogglePlaying ?? false
                onClicked: root.player?.togglePlaying()
            }
            MediaButton {
                icon: "skip_next"
                size: 18
                enabled: root.player?.canGoNext ?? false
                onClicked: root.player?.next()
            }
        }
    }

    // Bucket-average cava's 24 bands down to n bars.
    function bucket(arr: var, n: int): var {
        if (!arr || arr.length === 0)
            return [];
        const out = [];
        const size = arr.length / n;
        for (let i = 0; i < n; i++) {
            let sum = 0, c = 0;
            for (let j = Math.floor(i * size); j < Math.floor((i + 1) * size); j++) {
                sum += arr[j];
                c++;
            }
            out.push(c ? sum / c : 0);
        }
        return out;
    }
}
