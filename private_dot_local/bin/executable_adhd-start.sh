#!/usr/bin/env bash
# adhd-start.sh — open the quickshell "start a block" command palette (the
# centered, fuzzy-search focus launcher that replaced rofi). Bound to
# $mod+Shift+Return. Type to filter/create a task, ↑↓ to pick, ⏎ to start.
exec "$HOME/.local/bin/qs-ipc" call palette open
