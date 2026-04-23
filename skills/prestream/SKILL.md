---
name: prestream
description: Pre-stream safety and readiness check for livestreaming AI coding sessions from macOS. Use this skill whenever the streamer says anything about going live, starting a stream, running a prestream check, getting ready to stream, preparing for YouTube/Twitch/X live, "prestream", "pre-stream", "ready to stream", or similar phrasing — the exact words don't matter. The skill orchestrates environment lockdown (quits messaging apps, hides desktop icons, enables Focus/DnD, turns on smart lights), verifies secrets are resolvable, audits desktop and browser for sensitive content, sanity-checks OBS, runs a bandwidth check, and asks human-judgment questions (mic/camera/room/readiness) before giving a green/yellow/red verdict on whether it's safe to go live. Use proactively any time a stream is imminent, not just when explicitly invoked.
---

# Prestream Safety Check

You are a pre-stream safety officer for the streamer using this skill. Before they go live, run this full check. The goal is to catch privacy leaks, notifications, sensitive tabs, and misconfigured OBS **before** their audience sees them — not after.

Typical use case: the streamer runs AI coding sessions on macOS (Apple Silicon). API keys, personal tabs, messages, and desktop files showing up on-stream would be bad. This skill is the bulwark against that.

## Core principle

**Anything visible on the streamer's screen while live is effectively public forever.** A pre-stream check is not a formality — it's the critical gate. Be thorough but efficient. Aim for the full check to take under 2 minutes of wall time.

When in doubt, flag it. A yellow light is much cheaper than a leaked API key.

## Environment detection

This skill runs best in Claude Code, where your Bash tool executes on the streamer's Mac directly. It also gracefully degrades in sandboxed environments (like Cowork, where Bash runs in a Linux VM and shell commands have to be handed off to the streamer).

At the top of every run, check your environment:
- If your `bash` can execute `uname` and return `Darwin`, you're on the streamer's Mac directly (native flow). Run shell commands yourself.
- If `uname` returns `Linux`, you're in a sandbox. Tell the streamer to run the shell commands themselves and wait for confirmation before proceeding.

Proceed with the phases below, adapting each one based on environment.

## Phase 1: Environment lockdown

This quits messaging apps, hides desktop icons, tries to enable Focus, clears the clipboard, and turns on smart lights at preset brightness/temp.

Lights are controlled via their local REST API (no cloud, no vendor app needed). Default integration is for Elgato Key Lights — see `references/lights.conf` (copy from `lights.conf.example`). Per-light brightness/temp live in that file. Override at invocation via `LIGHTS_BRIGHTNESS` / `LIGHTS_TEMP_K` env vars, or call `scripts/lights.sh` directly. First-time setup: run `bash scripts/lights.sh discover` to auto-populate the config.

**Native flow:**
```bash
bash ~/.claude/skills/prestream/scripts/lockdown.sh
```
Run it, capture the output, and report the result inline.

**Sandboxed flow:**
Tell the streamer: "Run this in your streaming Terminal, then tell me it's done:"
```
bash ~/.claude/skills/prestream/scripts/lockdown.sh
```
Wait for confirmation.

In either case, inspect the script's output. If the script reports that Focus/DnD couldn't be enabled automatically (no matching Shortcut), remind them to toggle Focus manually via Control Center before going live, or create the `Toggle DND On` / `Toggle DND Off` Shortcuts (see `docs/setup.md`).

## Phase 2: Secret / env-var verification

Two ways the streamer may manage secrets for streaming sessions:

1. **Host env vars** — keys loaded into their shell before launching Claude. Check via `references/expected_env_vars.txt` (one var name per line). Used when not using a secrets injector.
2. **1Password refs** — secrets live in a vault; they launch with `op run --env-file=… -- claude`. Check via `references/op_refs.txt` (one `op://` ref per line). Verifies the refs resolve *before* going live. Requires the 1Password CLI (`op`) with biometric integration enabled.

Both files support `#` comments and blank lines. Both empty = phase is N/A (expected for brand-new setups).

**Native flow:**
```bash
bash ~/.claude/skills/prestream/scripts/verify_secrets.sh
```
Run it and report the output inline. If any 1Password ref fails to resolve, flag it — that's a red before going live. Common causes: wrong vault/item name, `op` CLI not signed in, Touch ID integration disabled.

Do NOT print actual secret values — the script only reports which refs resolve/don't.

**Sandboxed flow:**
Sandboxed bash can't see the host's `op` CLI or env. Ask the streamer to run `bash scripts/verify_secrets.sh` themselves and paste the output.

## Phase 3: Visual desktop audit

**If you have computer-use tools** (`mcp__computer-use__screenshot`):

1. Take a screenshot of each display.
2. Describe explicitly what's visible — don't just say "looks fine." Go through:
   - Menu bar apps (anything identifying? Dropbox/Drive sync showing filenames? 1Password vault name? Calendar event titles?)
   - Desktop background (should be empty — icons hidden in Phase 1)
   - Dock
   - Any background window bleeding through (Messages, Mail, calendar, banking, personal browser profile?)
   - Any visible real name, personal email, card number, API key, recovery phrase

**If you don't have computer-use tools:**
Ask the streamer to do the visual audit themselves using the bullet list above.

## Phase 4: Browser / tab audit

**If you have Chrome MCP** (`mcp__Claude_in_Chrome__*` tools). These tools require the **Claude in Chrome** extension installed in Chrome (Chrome Web Store, v1.0.36+) and Claude Code launched with `--chrome` (or `/chrome` toggled on in-session). If the tools are listed as deferred, load them with ToolSearch query `claude-in-chrome` before use. If the extension isn't connected, `/chrome` shows the status and offers a reconnect.

1. List tabs in the frontmost Chrome window.
2. If profile detection is possible, verify it's the streamer's dedicated streaming profile, not their main.
3. Check each open tab against `references/tab_allowlist.md`:
   - Allowed categories: pass
   - Yellow flags: ask the streamer before proceeding
   - Hard stops (email, banking, personal social, etc.): red verdict until closed

Do not auto-close tabs without confirmation — they might have reasons.

**If Chrome MCP isn't available:**
Ask the streamer to confirm their profile (top-right Chrome avatar) and to eyeball open tabs against the allowlist.

## Phase 5: OBS sanity check

**If you have computer-use tools:**

1. Bring OBS forward: `mcp__computer-use__open_application` with "OBS".
2. Screenshot and verify:
   - OBS is running
   - Active scene is whatever the streamer uses for main content (typically "Main" with IDE capture + webcam overlay)
   - Audio meters are present (ask them to say "test" and look for movement)
   - Stream destination is correct (Settings → Stream)
   - Start Streaming button is visible — do **not** click it

**If you don't have computer-use tools:**
Ask the streamer to visually confirm each of the bullets above.

If the streamer has configured OBS WebSocket, prefer API-based verification over screenshots (future enhancement).

## Phase 6: Bandwidth check

**Native flow:**
```bash
networkquality -v
```
(This is built into macOS Monterey+.) Parse the upload speed from the output.

**Sandboxed flow:**
Ask the streamer to run the same command and paste the result.

Thresholds:
- **≥ 10 Mbps up** → pass (comfortable headroom for 1080p at 5000 kbps)
- **6–10 Mbps up** → yellow (adequate; consider 720p)
- **< 6 Mbps up** → red (delay or drop to 720p)

## Phase 7: Human judgment

Use `AskUserQuestion` (or equivalent inline prompting in Claude Code) for all of these in one batch:

1. **Mic** — Does your mic sound clear when you speak at normal volume? (Yes / No / Not tested)
2. **Camera** — Is your camera framing and lighting good? (Yes / No / Not using camera)
3. **Room** — Is the visible area behind you clear of anything private? (Yes / No / N/A)
4. **Readiness** — Do you know what you're streaming about today? (Yes / Let me think / No)

Respect their answers. If they say no to any of the first three, do **not** give a green verdict.

## Phase 8: Verdict

Summarize in a tight, scannable format:

```
🟢 / 🟡 / 🔴 PRESTREAM CHECK COMPLETE

ENVIRONMENT:   [result]
SECRETS:       [result]
DESKTOP:       [result]
BROWSER:       [result]
OBS:           [result]
BANDWIDTH:     [result]
HUMAN CHECKS:  [result]

Fix these before going live:
- [item]

You're clear to hit Start Streaming when ready.
```

Verdict rules:
- 🟢 **Green** — every phase passed. Safe to go live.
- 🟡 **Yellow** — minor issues, streamer's call (forgotten tab, borderline bandwidth, unverified phase).
- 🔴 **Red** — critical issue. Do not go live until resolved. Triggers: visible credential, messaging app running, banking/email tab open, no audio detected, upload <6 Mbps.

Be decisive. Don't soften a red into a yellow out of politeness — this skill is specifically designed to produce honest verdicts.

## Post-stream

When the streamer says "I'm done," "stream's over," or similar, offer to run:

**Native:**
```bash
bash ~/.claude/skills/prestream/scripts/unlock.sh
```

**Sandboxed:** Tell them to run it themselves.

This restores desktop icons, turns off Focus, and turns off the lights. Messaging apps stay quit — they can relaunch when ready.

Also prompt them to:
- Verify the local OBS recording saved
- Watch the first 2–3 minutes of the VOD back
- **Rotate any credential they even partially suspect was glimpsed**

## What this skill explicitly does NOT do

- **Does not press "Start Streaming."** That's always the streamer's call. Consent moments stay manual.
- **Does not auto-close browser tabs without asking.** They might have a reason.
- **Does not assume a phase passed.** If a phase can't be verified, flag yellow and move on.

## Reference files

- `references/tab_allowlist.md` — what tabs pass/yellow/red during a stream
- `references/checklist.md` — the full human-readable pre-stream checklist this skill is based on
- `references/lights.conf` — your smart lights config (copy from `lights.conf.example`)
- `references/op_refs.txt` — 1Password refs to verify resolvable
- `references/expected_env_vars.txt` — host env vars to verify set
