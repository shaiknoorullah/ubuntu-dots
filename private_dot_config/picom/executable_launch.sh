#!/usr/bin/env bash
# Launch picom with glx if available, fall back to xrender
pkill picom 2>/dev/null
sleep 0.2

if glxinfo 2>/dev/null | grep -q 'direct rendering: Yes'; then
    picom -b --config ~/.config/picom.conf
else
    picom -b --config ~/.config/picom-xrender.conf
fi
