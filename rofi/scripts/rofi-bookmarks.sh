#!/usr/bin/env bash
#
# rofi-bookmarks.sh -- Firefox Bookmarks Browser
#
# Description:
#   Reads bookmarks directly from Firefox's SQLite database (places.sqlite)
#   and presents them in a rofi menu. The user can search/filter by title
#   and open the selected bookmark in Firefox. Supports both Snap-packaged
#   and standard Firefox installations by checking both profile paths.
#
# Keybinding: $mod+Shift+o
#
# Dependencies:
#   - rofi        : menu/prompt interface
#   - sqlite3     : queries Firefox's places.sqlite database
#   - firefox     : web browser (the source of bookmarks and the open target)
#   - find        : locates the places.sqlite file within the Firefox profile
#   - notify-send : desktop notifications
#
# Usage:
#   ~/.config/rofi/scripts/rofi-bookmarks.sh
#
# Technical notes:
#   - Firefox holds a WAL (write-ahead log) lock on places.sqlite while
#     running, so the database is copied to /tmp before querying. This
#     avoids "database is locked" errors and ensures a consistent read.
#   - The copy uses $$ (current PID) in the filename to avoid collisions
#     if multiple instances run simultaneously.
#   - Bookmark data spans two tables: moz_bookmarks (metadata) and
#     moz_places (URLs). They are joined via moz_bookmarks.fk -> moz_places.id.
#

THEME="$HOME/.config/rofi/themes/bookmarks.rasi"

# find_firefox_db()
#   Locates the places.sqlite file inside the active Firefox profile.
#   Checks the Snap path first (Ubuntu default since 22.04), then falls
#   back to the standard ~/.mozilla/firefox path.
#
#   Parameters: none
#   Output:     absolute path to places.sqlite on stdout
#   Returns:    0 on success, 1 if no Firefox profile directory exists
find_firefox_db() {
    local snap_path="$HOME/snap/firefox/common/.mozilla/firefox"
    local standard_path="$HOME/.mozilla/firefox"

    local search_path=""
    if [[ -d "$snap_path" ]]; then
        search_path="$snap_path"
    elif [[ -d "$standard_path" ]]; then
        search_path="$standard_path"
    else
        return 1
    fi

    # -print -quit stops after the first match (there's typically one profile)
    find "$search_path" -maxdepth 2 -name "places.sqlite" -print -quit 2>/dev/null
}

db_path=$(find_firefox_db)

if [[ -z "$db_path" ]]; then
    notify-send "Bookmarks" "Firefox profile not found" -u critical
    exit 1
fi

# Copy the database to /tmp to avoid locking conflicts with a running
# Firefox instance. The $$ suffix ensures unique filenames per invocation.
tmp_db="/tmp/rofi-places-$$.sqlite"
cp "$db_path" "$tmp_db"

# Query bookmarks from the copied database.
# - moz_bookmarks.type = 1 filters for actual bookmarks (vs. folders, separators)
# - Exclude NULL/empty titles (these are internal Firefox entries)
# - Exclude 'place:' URLs (Firefox's internal smart-bookmark queries)
# - Order by dateAdded DESC so the most recent bookmarks appear first
# - sqlite3 outputs pipe-delimited columns by default; we reformat to "title | url"
bookmarks=$(sqlite3 "$tmp_db" "
    SELECT b.title, p.url
    FROM moz_bookmarks b
    JOIN moz_places p ON b.fk = p.id
    WHERE b.type = 1
    AND b.title IS NOT NULL
    AND b.title != ''
    AND p.url NOT LIKE 'place:%'
    ORDER BY b.dateAdded DESC;
" 2>/dev/null | while IFS='|' read -r title url; do
    echo "$title | $url"
done)

# Clean up the temporary database copy
rm -f "$tmp_db"

if [[ -z "$bookmarks" ]]; then
    notify-send "Bookmarks" "No bookmarks found" -u normal
    exit 0
fi

chosen=$(echo "$bookmarks" | rofi -dmenu -theme "$THEME" -p "Bookmarks" -mesg "Firefox Bookmarks")

if [[ -n "$chosen" ]]; then
    # Extract the URL portion after the " | " separator.
    # sed greedily matches everything up to the last " | " to handle titles
    # that might themselves contain pipe characters.
    url=$(echo "$chosen" | sed 's/.*| //')
    firefox "$url" &
fi
