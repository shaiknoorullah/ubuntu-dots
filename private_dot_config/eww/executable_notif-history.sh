#!/usr/bin/env bash
# Fetch dunst history, group by app, separate latest from rest

dunstctl history 2>/dev/null | jq -c '
  def app_icon:
    if . == "Slack" then "󰒱"
    elif . == "discord" or . == "Discord" then "󰙯"
    elif . == "Zen Browser" or . == "zen" or . == "firefox" then "󰈹"
    elif . == "kitty" or . == "Alacritty" then ""
    elif . == "Spotify" then "󰓇"
    elif . == "notify-send" then "󰂞"
    elif . == "dunstify" then "󰂞"
    elif . == "Obsidian" then "󰎚"
    elif . == "code" or . == "Code" then "󰨞"
    elif . == "telegram" or . == "Telegram" then ""
    else "󰂚"
    end;

  def rel_time:
    . / 1000000000 |
    if . < 60 then "Now"
    elif . < 3600 then "\(. / 60 | floor)m"
    elif . < 86400 then "\(. / 3600 | floor)h"
    else "\(. / 86400 | floor)d"
    end;

  [.data[0][] | {
    id: .id.data,
    app: .appname.data,
    summary: (.summary.data // ""),
    body: (.body.data // "" | gsub("\n"; " ") | if length > 100 then .[:100] + "…" else . end),
    time: (.timestamp.data | rel_time)
  }] |
  group_by(.app) |
  [.[] | {
    app: .[0].app,
    icon: (.[0].app | app_icon),
    count: length,
    latest_id: .[0].id,
    latest_summary: .[0].summary,
    latest_body: .[0].body,
    latest_time: .[0].time,
    rest: (if length > 1 then .[1:] else [] end)
  }] | .[0:10]'
