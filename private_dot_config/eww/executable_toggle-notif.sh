#!/usr/bin/env bash
# Toggle the EWW notification center panel

# Inherit display from i3 process
eval $(cat /proc/$(pgrep -u $USER -x i3 | head -1)/environ 2>/dev/null | tr '\0' '\n' | grep -E '^DISPLAY=|^XAUTHORITY=')
export DISPLAY XAUTHORITY

# Ensure EWW daemon is running
if ! eww ping >/dev/null 2>&1; then
    eww daemon --no-daemonize &
    sleep 1
fi

if eww active-windows 2>/dev/null | grep -q "notification-center"; then
    eww close notification-center
else
    eww open notification-center
fi
