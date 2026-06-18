#!/usr/bin/env bash
# adhd-start.sh — open the quickshell focus drawer (the in-shell block picker
# that replaced the rofi launcher). Bound to $mod+Shift+Return. Pick a task or
# type a new one in the drawer's quick-add to open a deep-focus block.
exec "$HOME/.local/bin/qs-ipc" call leftbar open
