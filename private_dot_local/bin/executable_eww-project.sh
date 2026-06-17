#!/usr/bin/env bash
# eww-project.sh — current project name + git branch for the bottom bar's
# left cell, as JSON.
#
#   {"project":"pnow-ats-v2","branch":"feat/boolgen-otel"}
#
# Deliberately NOT `git -C $PWD branch`: eww has no meaningful working
# directory, so $PWD is wrong. Instead we read the recorded *project path*
# from ~/.cache/ctx-project (written by adhd-start when a project is entered),
# derive the project name from its basename, and read that repo's current
# branch with `git -C <dir>`.
#
# Missing / unreadable cache, a non-existent dir, or a non-git dir all fall
# back to calm placeholders so the bar never blanks and never errors:
#   project -> "—"   branch -> ""  (the widget hides an empty branch)
#
# Reads:  ~/.cache/ctx-project   (optional, a directory path)
# Wired:  defpoll bb-proj in widgets/bottombar.yuck
set -euo pipefail

PROJ_FILE="${EWW_CTX_PROJECT_FILE:-$HOME/.cache/ctx-project}"
GIT="${GIT_BIN:-git}"

# JSON string escaper: backslash, double-quote, strip control chars.
json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    printf '%s' "$s" | tr -d '\000-\037'
}

# Recorded project directory (tolerate missing/unreadable file under set -e).
dir=""
if [ -r "$PROJ_FILE" ]; then
    dir="$(head -n1 "$PROJ_FILE" 2>/dev/null | tr -d '\r\n' || true)"
fi

# Project name = basename of the path; em-dash placeholder when unknown.
project="—"
if [ -n "$dir" ]; then
    project="$(basename "$dir" 2>/dev/null || true)"
    [ -z "$project" ] && project="—"
fi

# Current branch of that repo (only when the dir exists and is a git work tree).
branch=""
if [ -n "$dir" ] && [ -d "$dir" ]; then
    if "$GIT" -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        branch="$("$GIT" -C "$dir" branch --show-current 2>/dev/null | head -n1 || true)"
    fi
fi

printf '{"project":"%s","branch":"%s"}\n' \
    "$(json_escape "$project")" "$(json_escape "$branch")"
