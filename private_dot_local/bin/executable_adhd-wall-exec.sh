#!/usr/bin/env bash
# adhd-wall-exec.sh — host actuator for the quickshell wallpaper widget.
# Triggered by adhd-wall.path when the widget writes ~/.cache/adhd/wall-request
# (a wallpaper path). Sets it via wall.sh (swww runs host-side).
set -uo pipefail
export PATH="$HOME/.local/bin:$PATH"
req="$HOME/.cache/adhd/wall-request"
[ -f "$req" ] || exit 0
p="$(head -n1 "$req" | tr -d '\r')"
rm -f "$req"
[ -n "$p" ] && [ -f "$p" ] && wall.sh set "$p"
