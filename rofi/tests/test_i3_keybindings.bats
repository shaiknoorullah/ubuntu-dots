#!/usr/bin/env bats

setup() {
    load 'test_helper/common'
    I3_CONFIG="$HOME/.config/i3/config"
    if [[ ! -f "$I3_CONFIG" ]]; then
        skip "i3 config not found"
    fi
}

# Helper: check if a bindsym line exists containing all given substrings
assert_binding() {
    local key="$1"
    shift
    local line
    line=$(grep "bindsym $key " "$I3_CONFIG" | head -1)
    if [[ -z "$line" ]]; then
        echo "No binding found for key: $key"
        return 1
    fi
    for substr in "$@"; do
        if [[ "$line" != *"$substr"* ]]; then
            echo "Binding for $key missing '$substr'"
            echo "Actual: $line"
            return 1
        fi
    done
}

# ── Core Rofi Bindings ────────────────────────────────────────

@test "i3: mod+d launches drun with launcher theme" {
    assert_binding '$mod+d' "rofi -show drun" "launcher.rasi"
}

@test "i3: mod+Shift+d launches run with launcher theme" {
    assert_binding '$mod+Shift+d' "rofi -show run" "launcher.rasi"
}

@test "i3: mod+Tab launches window switcher" {
    assert_binding '$mod+Tab' "rofi -show window" "launcher.rasi"
}

@test "i3: mod+Shift+s launches SSH" {
    assert_binding '$mod+Shift+s' "rofi -show ssh" "launcher.rasi"
}

@test "i3: mod+Shift+f launches filebrowser" {
    assert_binding '$mod+Shift+f' "rofi -show filebrowser" "launcher.rasi"
}

@test "i3: mod+F1 launches rofi keys" {
    assert_binding '$mod+F1' "rofi -show keys" "keybindings.rasi"
}

# ── System Bindings ───────────────────────────────────────────

@test "i3: mod+Shift+e launches power menu" {
    assert_binding '$mod+Shift+e' "rofi-power.sh"
}

@test "i3: mod+c launches clipboard" {
    assert_binding '$mod+c' "rofi-clipboard.sh"
}

@test "i3: mod+Shift+b launches bluetooth" {
    assert_binding '$mod+Shift+b' "rofi-bluetooth.sh"
}

@test "i3: mod+Shift+m launches display manager" {
    assert_binding '$mod+Shift+m' "rofi-display.sh"
}

@test "i3: mod+Shift+w launches wallpaper" {
    assert_binding '$mod+Shift+w' "rofi-wallpaper.sh"
}

@test "i3: Print launches screenshot" {
    assert_binding 'Print' "rofi-screenshot.sh"
}

@test "i3: mod+Shift+p launches systemd" {
    assert_binding '$mod+Shift+p' "rofi-systemd.sh"
}

# ── Productivity Bindings ─────────────────────────────────────

@test "i3: mod+equal launches calculator with calc theme" {
    assert_binding '$mod+equal' "rofi -show calc" "calculator.rasi"
}

@test "i3: mod+period launches rofimoji with emoji theme" {
    assert_binding '$mod+period' "rofimoji" "emoji.rasi"
}

@test "i3: mod+slash launches websearch" {
    assert_binding '$mod+slash' "rofi-websearch.sh"
}

# ── Developer Bindings ────────────────────────────────────────

@test "i3: mod+p launches project manager" {
    assert_binding '$mod+p' "rofi-projects.sh"
}

@test "i3: mod+g launches git profile" {
    assert_binding '$mod+g' "rofi-git-profile.sh"
}

@test "i3: mod+t launches tmux" {
    assert_binding '$mod+t' "rofi-tmux.sh"
}

# ── Browser Bindings ─────────────────────────────────────────

@test "i3: mod+Shift+o launches bookmarks" {
    assert_binding '$mod+Shift+o' "rofi-bookmarks.sh"
}

# ── Notes Bindings ────────────────────────────────────────────

@test "i3: mod+n launches obsidian actions" {
    assert_binding '$mod+n' "rofi-obsidian.sh"
}

@test "i3: mod+Shift+n launches obsidian search" {
    assert_binding '$mod+Shift+n' "rofi-obsidian-search.sh"
}

# ── Other Bindings ────────────────────────────────────────────

@test "i3: mod+F2 launches keybinding viewer" {
    assert_binding '$mod+F2' "rofi-keybindings.sh"
}

@test "i3: mod+m launches media controls" {
    assert_binding '$mod+m' "rofi-media.sh"
}

# ── Autostart ─────────────────────────────────────────────────

@test "i3: greenclip daemon in autostart" {
    grep -q "greenclip daemon" "$I3_CONFIG"
}

@test "i3: fehbg in autostart" {
    grep -q "fehbg" "$I3_CONFIG"
}

# ── Script Existence ─────────────────────────────────────────

@test "i3: all referenced scripts exist and are executable" {
    local scripts_dir="$HOME/.config/rofi/scripts"
    local failures=""
    while IFS= read -r script; do
        if [[ ! -x "$script" ]]; then
            failures+="Not executable: $script\n"
        fi
    done < <(grep -oP '~/.config/rofi/scripts/\S+' "$I3_CONFIG" | sed "s|~|$HOME|g" | sort -u)

    if [[ -n "$failures" ]]; then
        echo -e "$failures"
        return 1
    fi
}
