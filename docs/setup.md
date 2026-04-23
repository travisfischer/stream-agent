# Setup guide

Step-by-step setup for the `prestream` skill. Order matters — some later steps depend on earlier ones.

Total time: about 30 minutes of active work, plus a potential 24-hour wait if you're enabling YouTube Live.

## Prerequisites

- **macOS 12 (Monterey) or newer** — the skill uses `shortcuts`, `networkquality`, `pbcopy`, and `defaults` commands that ship with Monterey+
- **Claude Code** installed and working
- **OBS Studio** (free) — https://obsproject.com
- **Homebrew** (for installing `gh` and `op`) — https://brew.sh

Optional but recommended:

- **1Password 8** — for the `op://` secret-resolution flow in Phase 2
- **Elgato Key Lights** (Air, Mini, or full) — for automatic lighting in Phase 1
- **Chrome** or **Edge** — for the Phase 4 browser audit (Chrome MCP integration is Chrome-only currently)

## 1. Install the skill

Run these from the directory you want the repo cloned into (e.g. `~/code`):

```bash
git clone https://github.com/travisfischer/stream-agent.git
cp -r ./stream-agent/skills/prestream ~/.claude/skills/
chmod +x ~/.claude/skills/prestream/scripts/*.sh
```

Verify the skill is discovered:

```bash
ls ~/.claude/skills/prestream/
# should list: SKILL.md, scripts/, references/
```

In Claude Code, start a new session. It should list `prestream` among available skills. You can invoke it by saying anything like "run a prestream check" or "I want to go live soon" — the skill description is designed to trigger broadly.

## 2. Create the local config files from `.example` templates

Only `lights.conf.example` has an example template to copy — the other reference files (`expected_env_vars.txt`, `op_refs.txt`) ship as editable templates themselves.

```bash
cd ~/.claude/skills/prestream/references
cp lights.conf.example lights.conf
# now edit lights.conf for your specific lights (step 4 below)
```

## 3. Create the macOS Do-Not-Disturb Shortcuts

The skill's lockdown script toggles DnD via two macOS Shortcuts. You create them once in Shortcuts.app; they then run invisibly.

1. Open **Shortcuts.app**
2. Click **+** (top-right of the main window) to create a new shortcut
3. In the action library (right sidebar), search for `Set Focus`
4. Double-click **Set Focus** to add it to the shortcut
5. Configure the action: **Turn Do Not Disturb On** (default is "On" — leave it, or pick a specific duration if you prefer)
6. Rename the shortcut to exactly `Toggle DND On`
7. Close the editor window (⌘W) — autosaves

Repeat for the off-switch:

1. **+** again for a new shortcut
2. Add another **Set Focus** action
3. Change it to **Turn Do Not Disturb Off**
4. Rename to exactly `Toggle DND Off`
5. ⌘W

Verify from the terminal:

```bash
shortcuts list | grep -i "toggle dnd"
# should show both: Toggle DND On, Toggle DND Off
```

Test:

```bash
shortcuts run "Toggle DND On"   # menu bar should show crescent moon
shortcuts run "Toggle DND Off"  # moon disappears
```

If either fails, double-check the shortcut names match exactly (case-insensitive match in lockdown.sh, but misspellings won't match).

## 4. Configure your smart lights

If you have Elgato Key Lights on your local network:

```bash
bash ~/.claude/skills/prestream/scripts/lights.sh discover
```

This does an mDNS scan for Elgato devices and prints the hostnames it finds.

Edit `~/.claude/skills/prestream/references/lights.conf` and replace the placeholder hostnames with yours. Tune per-light brightness and color temperature — see the comments in the file for guidance.

Test:

```bash
bash ~/.claude/skills/prestream/scripts/lights.sh status   # queries state
bash ~/.claude/skills/prestream/scripts/lights.sh on       # turns them on
bash ~/.claude/skills/prestream/scripts/lights.sh off      # turns them off
```

**Dialing in your lighting.** Classic key/fill setup:
- The **key** light is opposite any strong natural light source (e.g., window). Brighter (60-75%).
- The **fill** light is on the window side. Softer (30-50% of key).
- Both usually at the same color temperature, around 4500-5000K for daylight-neutral.

Iterate with OBS open showing your webcam feed — run `lights.sh on 70 5000` with different values and watch the preview until you're happy. Then bake those into `lights.conf`.

Don't have Elgato Key Lights? See [`alternatives.md`](alternatives.md) for other options.

## 5. Set up 1Password CLI (optional)

This enables Phase 2's `op://` ref resolution — the cleanest way to verify API keys are ready before streaming without ever echoing them.

Install:

```bash
brew install --cask 1password-cli
op --version   # verify
```

Enable biometric integration (Touch ID unlock):

1. Open the **1Password** app (not System Settings)
2. ⌘, to open its Settings
3. Sidebar → **Developer**
4. Check **☑ Integrate with 1Password CLI**
5. Confirm with Touch ID when prompted

Test:

```bash
op account list       # shows your 1Password account
op vault list         # prompts Touch ID, lists your vaults
```

Create a dedicated `Agents` vault in 1Password (isolate agent-accessible credentials from your personal vault):

1. In the 1Password app → **New vault** → name it `Agents`
2. Add an item (e.g., API Credential for Anthropic) with the field name `credential` holding the API key

Reference it in the skill:

```bash
# edit ~/.claude/skills/prestream/references/op_refs.txt
# uncomment/add lines like:
op://Agents/Anthropic/credential
op://Agents/OpenAI/credential
```

Test the resolution:

```bash
bash ~/.claude/skills/prestream/scripts/verify_secrets.sh
# should list each ref with ✓ if resolvable, ✗ if not
```

**Using secrets at stream time** — put your launch flow through `op run`:

```bash
# ~/.config/agents.env (safe to commit — no values, just refs)
ANTHROPIC_API_KEY=op://Agents/Anthropic/credential
OPENAI_API_KEY=op://Agents/OpenAI/credential

# in ~/.zshrc:
alias claude-stream='op run --env-file=~/.config/agents.env -- claude'
```

Then `claude-stream` during streams. The secrets only exist inside the Claude Code subprocess env; your shell never sees them, and 1Password masks any accidental echoes in subprocess output.

Not using 1Password? Use the `expected_env_vars.txt` file instead — list your env var names, set them manually in your shell, and the Phase 2 check verifies they're populated.

## 6. Set up a dedicated Stream Chrome profile

Isolates streaming-time browsing from your main/personal profile. Critical if your main profile has Gmail, banking, personal social, etc.

1. Open Chrome → profile avatar (top-right) → **Add** → **Sign in** with a dedicated streaming Google/Workspace account (or skip if you don't want sync)
2. Name the profile `Stream` or `Streamer`
3. In the new profile window: **turn off sync** (or scope it to just this profile's data) — `chrome://settings/syncSetup`
4. Audit autofill: `chrome://settings/addresses` and `chrome://settings/payments` — should be empty. If Chrome populated them from sync, clear.
5. Extensions: install only what you need for streams (e.g., [Claude in Chrome](https://chromewebstore.google.com/detail/claude/fcoeoabgfenejglbffodgkkbkcdhcgfn) if you want Phase 4 automation)
6. Bookmarks bar: curate to streaming-safe URLs, or hide it (⌘⇧B)

If you're on a Google Workspace account, the profile chip may show "Work" regardless of what you name the profile — that's a Workspace-side label you can't override from Chrome settings. Use the profile avatar/color to visually distinguish it.

## 7. Install the Claude in Chrome extension (optional)

Enables Phase 4 browser audit to list tabs programmatically.

1. Install from the [Chrome Web Store](https://chromewebstore.google.com/detail/claude/fcoeoabgfenejglbffodgkkbkcdhcgfn) into your **Stream** profile (not your main)
2. Restart Chrome
3. Launch Claude Code with `claude --chrome`, or toggle it in-session with `/chrome`

Verify by running `/chrome` in Claude Code — it shows connection status.

## 8. Configure OBS scenes

See [`obs-scenes.md`](obs-scenes.md) for the full walkthrough: building Starting Soon / Main / Camera / BRB / Ending scenes, adding your webcam with color/crop filters, binding a BRB hotkey.

## 9. First dry run

From Claude Code:

> run a prestream check

The skill invokes. You'll get a verdict at the end. For a first run, expect yellows for things like "no Window Capture for IDE in Main scene" (expected — add right before real streams) or "X Producer tab not open" (expected unless you're actually about to stream). That's fine — the skill surfaces anything you'd need to fix, and you pick your real cutoff for what's acceptable.

Run `bash ~/.claude/skills/prestream/scripts/unlock.sh` after to reverse lockdown.

## Ready to go live

Actually going live is outside the skill's scope. Once you've got a green verdict:

1. Open your platform's broadcast console (YouTube Studio, X Producer, Twitch Creator Dashboard)
2. OBS → Settings → Stream → paste your platform's stream key
3. Click **Start Streaming** in OBS
4. Watch your broadcast page for a few seconds to confirm video/audio are landing

**Belt and suspenders:** click **Start Recording** in OBS too. If the stream has an issue, you'll still have a local VOD.

Good luck. Use the BRB scene liberally — viewers don't mind brief breaks, and leaked secrets are expensive.
