#!/bin/bash
# prestream unlock — reverses lockdown.sh after the stream is done.
# Restores desktop icons and turns off Focus. Messaging apps stay quit —
# relaunch them yourself when you're ready.

set -u

echo ""
echo "🔓 POST-STREAM UNLOCK"
echo "════════════════════════════"
echo ""

# ─── Restore desktop icons ──────────────────────────────────────
echo "Restoring desktop icons..."
defaults write com.apple.finder CreateDesktop true
killall Finder >/dev/null 2>&1 || true
echo "  ✓ Desktop icons restored"
echo ""

# ─── Disable Focus / Do Not Disturb ─────────────────────────────
echo "Disabling Focus / Do Not Disturb..."
if command -v shortcuts >/dev/null 2>&1; then
  if shortcuts list 2>/dev/null | grep -iq "^toggle dnd off$"; then
    shortcuts run "Toggle DND Off" 2>/dev/null \
      && echo "  ✓ Focus disabled via 'Toggle DND Off' Shortcut" \
      || echo "  ⚠ Shortcut found but didn't run. Toggle Focus manually."
  else
    echo "  ⚠ No 'Toggle DND Off' Shortcut found."
    echo "    Toggle Focus manually: Control Center → Focus."
  fi
else
  echo "  ⚠ 'shortcuts' not available. Toggle Focus manually."
fi
echo ""

# ─── Turn off Elgato Key Lights ─────────────────────────────────
LIGHTS_SCRIPT="$(dirname "$0")/lights.sh"
if [ -x "$LIGHTS_SCRIPT" ]; then
  bash "$LIGHTS_SCRIPT" off
  echo ""
fi

echo "════════════════════════════"
echo "✅ Unlock complete."
echo ""
echo "Reminders:"
echo "  • Verify the local OBS recording saved."
echo "  • Watch the first 2–3 minutes of the VOD with fresh eyes."
echo "  • Rotate any credential you even partially suspect was glimpsed."
echo ""
