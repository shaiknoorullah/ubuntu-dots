#!/usr/bin/env bash
set -euo pipefail
CTX=$(cat "$HOME/.cache/ctx" 2>/dev/null || echo personal)
TASK="${TASK_BIN:-/usr/bin/task}"  # taskwarrior (go-task shadows `task` in PATH)
opts=$("$TASK" +today status:pending export 2>/dev/null | python3 -c "import json,sys;[print(t['id'],t.get('description','')) for t in json.load(sys.stdin)]" 2>/dev/null || true)
line=$(printf '%s' "$opts" | rofi -dmenu -p "Start" -theme "$HOME/.config/rofi/themes/simple.rasi") || exit 0
[ -z "$line" ] && exit 0
id=${line%% *}
adhd-focus.sh start "$id"
tmux has-session -t "$CTX" 2>/dev/null && tmux switch-client -t "$CTX" 2>/dev/null || true
