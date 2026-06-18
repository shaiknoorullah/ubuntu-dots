#!/usr/bin/env bash
# adhd-start.sh — pick (or quick-add) a task and open a deep-focus block.
# Bound to $mod+Shift+Return. Prefers today's tasks; falls back to all pending;
# typing a new line creates that task (+today) and starts a block on it.
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"   # so adhd-focus.sh / tmux resolve

CTX=$(cat "$HOME/.cache/ctx" 2>/dev/null || echo personal)
TASK="${TASK_BIN:-/usr/bin/task}"      # go-task shadows `task` on PATH

list() {
    "$TASK" "$@" status:pending export 2>/dev/null \
        | python3 -c "import json,sys;[print(t['id'],t.get('description','')) for t in json.load(sys.stdin)]" 2>/dev/null || true
}

opts=$(list +today)
[ -z "$opts" ] && opts=$(list)        # fall back to all pending if no +today

line=$(printf '%s' "$opts" | rofi -dmenu -p "Start block (or type a new one)" \
        -theme "$HOME/.config/rofi/themes/simple.rasi") || exit 0
[ -z "$line" ] && exit 0

id=${line%% *}
# If the first token isn't an existing task id, treat the typed text as a NEW
# task: quick-add it (+today) and start a block on it.
if ! printf '%s' "$id" | grep -qE '^[0-9]+$'; then
    id=$("$TASK" add +today "$line" 2>&1 | grep -oE 'Created task [0-9]+' | grep -oE '[0-9]+' || true)
fi

[ -n "$id" ] && adhd-focus.sh start "$id"
tmux has-session -t "$CTX" 2>/dev/null && tmux switch-client -t "$CTX" 2>/dev/null || true
