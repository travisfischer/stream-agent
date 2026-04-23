#!/bin/bash
# prestream lockdown — pre-stream environment prep
# Quits messaging apps, hides desktop icons, enables Focus/DnD,
# clears clipboard, and turns on smart lights.
# Safe to run multiple times. Reverse with unlock.sh.

set -u

echo ""
echo "🔒 PRESTREAM LOCKDOWN"
echo "════════════════════════════"
echo ""

# ─── Quit messaging apps ──────────────────────────────────────────
APPS_TO_QUIT=("Slack" "Messages" "Discord")
echo "Quitting messaging apps..."
for app in "${APPS_TO_QUIT[@]}"; do
  if pgrep -x "$app" >/dev/null 2>&1; then
    osascript -e "tell application \"$app\" to quit" >/dev/null 2>&1
    # Give it a moment to exit cleanly
    sleep 0.5
    if pgrep -x "$app" >/dev/null 2>&1; then
      echo "  ⚠ $app did not quit cleanly (might be showing 'unsaved' dialog)"
    else
      echo "  ✓ Quit $app"
    fi
  else
    echo "  · $app was not running"
  fi
done
echo ""

# ─── Hide desktop icons ──────────────────────────────────────────
echo "Hiding desktop icons..."
defaults write com.apple.finder CreateDesktop false
killall Finder >/dev/null 2>&1 || true
echo "  ✓ Desktop icons hidden"
echo ""

# ─── Enable Focus / Do Not Disturb ──────────────────────────────
echo "Enabling Focus / Do Not Disturb..."
# macOS makes programmatic Focus toggling awkward. Best-effort:
# 1. If a Shortcut named "Toggle DND On" exists, run it.
# 2. Otherwise, prompt the user to toggle manually.

if command -v shortcuts >/dev/null 2>&1; then
  if shortcuts list 2>/dev/null | grep -iq "^toggle dnd on$"; then
    shortcuts run "Toggle DND On" 2>/dev/null \
      && echo "  ✓ Focus enabled via 'Toggle DND On' Shortcut" \
      || echo "  ⚠ Shortcut found but didn't run. Toggle Focus manually (Control Center → Focus)."
  else
    echo "  ⚠ No 'Toggle DND On' Shortcut found."
    echo "    One-time setup: open Shortcuts.app, create a Shortcut named"
    echo "    'Toggle DND On' with the 'Set Focus' action set to Do Not Disturb → On."
    echo "    Until then, toggle Focus manually: Control Center → Focus."
  fi
else
  echo "  ⚠ 'shortcuts' command not available (need macOS Monterey+)."
  echo "    Toggle Focus manually: Control Center → Focus."
fi
echo ""

# ─── Clipboard clear ────────────────────────────────────────────
echo "Clearing clipboard..."
pbcopy < /dev/null
echo "  ✓ Clipboard cleared"
echo ""

# ─── Turn on Elgato Key Lights ──────────────────────────────────
LIGHTS_SCRIPT="$(dirname "$0")/lights.sh"
if [ -x "$LIGHTS_SCRIPT" ]; then
  bash "$LIGHTS_SCRIPT" on
  echo ""
fi

# ─── Done ───────────────────────────────────────────────────────
echo "════════════════════════════"
echo "✅ Lockdown complete."
echo ""
echo "Next: tell Claude the lockdown is done so it can run the visual audit."
echo ""
