#!/usr/bin/env bash
#
# rofi-screenshot.sh — Screenshot utility with multiple capture modes
#
# Description:
#   Presents a rofi dmenu with 3 screenshot modes: fullscreen, area selection,
#   and active window. Every screenshot is both saved to disk (for archival)
#   and copied to the clipboard (for immediate pasting into chat, docs, etc.).
#   A desktop notification confirms the save with a thumbnail preview.
#
# Keybinding: Print (PrintScreen key, defined in i3 config)
#
# Dependencies:
#   - rofi        : menu launcher (dmenu mode)
#   - maim        : screenshot tool (lightweight alternative to scrot)
#   - xclip       : copies the image to the X clipboard
#   - xdotool     : identifies the active window ID for window-mode capture
#   - notify-send : desktop notification (typically provided by dunst)
#
# Usage:
#   ~/.config/rofi/scripts/rofi-screenshot.sh
#
# Output:
#   Screenshots are saved to ~/Pictures/Screenshots/ with a timestamped
#   filename (screenshot-YYYYMMDD-HHMMSS.png).

# Path to the dedicated rofi theme for the screenshot menu
THEME="$HOME/.config/rofi/themes/screenshot.rasi"

# Directory where screenshots are persisted on disk
SAVE_DIR="$HOME/Pictures/Screenshots"

# Generate a unique filename using the current date and time. This is
# computed once at script start so that the filename reflects when the
# user initiated the action, not when maim finishes capturing.
FILENAME="screenshot-$(date +%Y%m%d-%H%M%S).png"

# Ensure the save directory exists (safe to call repeatedly via -p)
mkdir -p "$SAVE_DIR"

# --------------------------------------------------------------------------
# Menu options — Nerd Font icons for each capture mode.
# --------------------------------------------------------------------------
fullscreen="󰍹"
area="󰩭"
window="󰖯"

options="$fullscreen\n$area\n$window"

chosen=$(echo -e "$options" | rofi -dmenu -theme "$THEME" -p "Screenshot" -mesg "Select Mode")

# take_screenshot — Captures the screen and saves/copies the result.
#
# Handles three capture modes via maim, then copies the resulting image
# to the clipboard and sends a desktop notification.
#
# Parameters:
#   $1 — Capture mode: "fullscreen", "area", or "window"
#
# Returns:
#   No explicit return value. Side effects:
#     - Writes a PNG file to $SAVE_DIR/$FILENAME
#     - Copies the PNG to the X clipboard (image/png MIME type)
#     - Sends a desktop notification with the file path and thumbnail
take_screenshot() {
    local filepath="$SAVE_DIR/$FILENAME"
    case "$1" in
        # Fullscreen: sleep briefly so rofi has time to close and its
        # window doesn't appear in the capture. 0.3s is enough for the
        # compositor to finish the close animation.
        fullscreen) sleep 0.3; maim "$filepath" ;;

        # Area: maim -s lets the user click-and-drag a rectangle.
        # No sleep needed because rofi closes before the selection starts.
        area)       maim -s "$filepath" ;;

        # Window: capture only the currently focused window by passing its
        # X window ID to maim via xdotool. This avoids capturing panels,
        # bars, or other overlapping windows.
        window)     maim -i "$(xdotool getactivewindow)" "$filepath" ;;
    esac

    # Only proceed if maim successfully wrote the file (it won't exist if
    # the user cancelled area selection, for example).
    if [[ -f "$filepath" ]]; then
        # Copy to clipboard so the screenshot can be pasted immediately
        # (e.g. Ctrl+V in Slack, Discord, etc.)
        xclip -selection clipboard -t image/png < "$filepath"

        # Desktop notification with the screenshot as its icon/thumbnail,
        # auto-dismissed after 3 seconds.
        notify-send "Screenshot Saved" "$filepath" -i "$filepath" -t 3000
    fi
}

# --------------------------------------------------------------------------
# Action dispatch — map the selected icon to a capture mode string.
# --------------------------------------------------------------------------
case "$chosen" in
    "$fullscreen") take_screenshot "fullscreen" ;;
    "$area")       take_screenshot "area" ;;
    "$window")     take_screenshot "window" ;;
esac
