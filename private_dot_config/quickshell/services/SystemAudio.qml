pragma Singleton

// SYSTEM AUDIO SINGLETON — default PipeWire sink/source for the right panel.

import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    property var sink: Pipewire.defaultAudioSink
    property var source: Pipewire.defaultAudioSource

    readonly property bool sinkReady: root.sink?.ready ?? false
    readonly property bool sourceReady: root.source?.ready ?? false
    readonly property int volume: Math.round((root.sink?.audio?.volume ?? 0) * 100)
    readonly property int micVolume: Math.round((root.source?.audio?.volume ?? 0) * 100)
    readonly property bool muted: root.sink?.audio?.muted ?? true
    readonly property bool micMuted: root.source?.audio?.muted ?? true

    function clamp01(value: real): real {
        return Math.max(0, Math.min(1, value));
    }

    function setVolume(percent: int): void {
        if (!root.sink?.audio)
            return;
        root.sink.audio.volume = root.clamp01(percent / 100);
    }

    function setMicVolume(percent: int): void {
        if (!root.source?.audio)
            return;
        root.source.audio.volume = root.clamp01(percent / 100);
    }

    function toggleMute(): void {
        if (!root.sink?.audio)
            return;
        root.sink.audio.muted = !root.sink.audio.muted;
    }

    function toggleMicMute(): void {
        if (!root.source?.audio)
            return;
        root.source.audio.muted = !root.source.audio.muted;
    }

    function deviceName(node: var): string {
        return node?.nickname || node?.description || node?.name || "default";
    }

    PwObjectTracker {
        objects: [root.sink, root.source]
    }
}
