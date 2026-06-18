pragma Singleton

// MPRIS MEDIA SINGLETON  (pattern: caelestia services/Players.qml)
//
// `import Quickshell.Services.Mpris` gives `Mpris.players` (ObjectModel of
// MprisPlayer). An MprisPlayer exposes:
//   trackTitle, trackArtist, trackAlbum, trackArtUrl
//   isPlaying, canPlay, canPause, canTogglePlaying, canGoNext, canGoPrevious
//   position (real seconds), length, canSeek, positionSupported
//   shuffle/shuffleSupported, loopState (MprisLoopState.{None,Track,Playlist})
//   togglePlaying(), play(), pause(), next(), previous(), stop()
// NOTE: `position` does NOT tick on its own — caelestia drives a repeating
// Timer that calls `active.positionChanged()` to force the binding to update
// (see Details widget in PATTERN_GUIDE.md section 6).

import QtQml
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property list<MprisPlayer> list: Mpris.players.values
    // Pick first available player; caelestia adds a manual-override + alias layer.
    readonly property MprisPlayer active: list[0] ?? null

    function artUrl(player: MprisPlayer): string {
        return player?.trackArtUrl ?? "";
    }
}
