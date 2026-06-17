#!/usr/bin/env bash

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch polybar on all monitors
if command -v xrandr >/dev/null 2>&1; then
    for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
        MONITOR=$m polybar main 2>&1 | tee /tmp/polybar-$m.log & disown
    done
else
    polybar main 2>&1 | tee /tmp/polybar.log & disown
fi

echo "Polybar launched."
