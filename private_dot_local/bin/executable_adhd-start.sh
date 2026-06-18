#!/usr/bin/env bash
# adhd-start.sh — open the focus panel on its Focus page (the quick-start block
# launcher). Bound to $mod+Shift+Return. Tab/1-5 switch pages once open.
exec "$HOME/.local/bin/qs-ipc" call panel focus
