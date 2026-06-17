#!/usr/bin/env bash
# eww-active.sh — the currently-active taskwarrior task + live timewarrior
# elapsed, as JSON for the eww bottom bar's center cell.
#
#   {"task":"boolgen otel","elapsed":"0:42:11"}
#
# - Taskwarrior is invoked via $TASK (TASK_BIN override) because go-task
#   shadows `task` on PATH; default /usr/bin/task.
# - Active task = first id in `task +ACTIVE ids`; its description via
#   `task _get <id>.description`.
# - Live elapsed comes from `timew get dom.active.duration` (the duration
#   of the open interval). When nothing is tracking, timew prints nothing
#   or errors — we fall back to "0:00:00".
# - With no active task we still emit valid JSON ("—" em dash placeholder),
#   so eww's defpoll never sees malformed output.
set -euo pipefail

TASK="${TASK_BIN:-/usr/bin/task}"

# JSON string escaper: backslash, double-quote, strip control chars.
json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    printf '%s' "$s" | tr -d '\000-\037'
}

# Active task id (first one if several are active).
id="$("$TASK" +ACTIVE ids 2>/dev/null | head -n1 | tr -d '[:space:]')"

desc=""
if [ -n "$id" ]; then
    desc="$("$TASK" _get "${id}.description" 2>/dev/null | head -n1)"
fi
[ -z "$desc" ] && desc="—"

# Live elapsed of the open interval; fall back to a zero clock.
elapsed="$(timew get dom.active.duration 2>/dev/null | head -n1 | tr -d '[:space:]')"
[ -z "$elapsed" ] && elapsed="0:00:00"

printf '{"task":"%s","elapsed":"%s"}\n' "$(json_escape "$desc")" "$(json_escape "$elapsed")"
