#!/usr/bin/env bash
# Output notification icon with badge count for polybar

count=$(dunstctl count history 2>/dev/null || echo 0)

if [ "$count" -gt 0 ]; then
    echo "%{F#ff9e3b}󰂚%{F-} $count"
else
    echo "%{F#585880}󰂜%{F-}"
fi
