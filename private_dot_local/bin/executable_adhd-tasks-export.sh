#!/usr/bin/env bash
# adhd-tasks-export.sh — snapshot pending tasks to a shared file the quickshell
# drawer reads (the Arch container's taskwarrior 3.x can't read the host's 2.6.2
# data, so the HOST exports JSON here and quickshell just `cat`s it).
set -uo pipefail
TASK="${TASK_BIN:-/usr/bin/task}"
dir="$HOME/.cache/adhd"
mkdir -p "$dir"
"$TASK" rc.json.array=on +PENDING export 2>/dev/null > "$dir/tasks.json.tmp" \
    && mv "$dir/tasks.json.tmp" "$dir/tasks.json"
