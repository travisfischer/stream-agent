# Alternatives — swap options for different stacks

The reference setup uses a specific set of tools. Here's how to adapt if yours differs.

## Streaming software

| Swap for OBS | How |
|---|---|
| **Streamlabs** | Mostly drop-in: skill Phase 5 screenshots your streaming app; rename scenes as you like. Hotkey assignment via Streamlabs' own settings. |
| **Twitch Studio** | Similar. Phase 5 adapts to whatever's running. You lose OBS-specific features (WebSocket API future enhancement won't apply). |
| **Xsplit** (Windows) | Requires porting the lockdown script (see Platform below). |
| **ffmpeg / custom RTMP** | No scene concept. Skip Phase 5 or replace with a check that your ffmpeg process is ready. |

## Platform / destination

| Platform | Phase 4 tab allowlist adjustment | Notes |
|---|---|---|
| **YouTube Live** | Safe: `studio.youtube.com`. Red: `youtube.com/feed/*`, `youtube.com/watch/*` (your personal feed) | 24-hour phone-verification wait on first-time live enablement |
| **Twitch** | Safe: `dashboard.twitch.tv`. Red: `twitch.tv/directory`, `twitch.tv/following` | Set up a separate Twitch account for streaming if your personal one has DMs/subs you don't want visible |
| **X (Twitter) Live** | Safe: `studio.x.com/producer/*`. Red: `x.com/home`, `x.com/messages`, `x.com/notifications`, `x.com/[handle]` | Uses your existing X account; discipline-based rather than account-based separation |
| **Kick** | Safe: `dashboard.kick.com`. Red: `kick.com/category/*` | |
| **LinkedIn Live** | Safe: `linkedin.com/live/*`. Red: everything else on linkedin.com | Needs LinkedIn Live access (application-gated) |
| **Multiple at once** | **Restream.io** acts as your RTMP ingest; OBS points at Restream, Restream fans out. | Adds another web tab to manage — Restream Studio at `app.restream.io` |

Edit `skills/prestream/references/tab_allowlist.md` to codify your platform's rules.

## Smart lights

The built-in `lights.sh` script talks the **Elgato Key Light HTTP API**. To swap:

| Light | Integration approach |
|---|---|
| **Philips Hue** | Use `hueadm` or curl against the Hue bridge API. Write an analogous `lights.sh` with Hue endpoints. Bridge discovery via SSDP. |
| **LIFX** | LAN protocol is UDP binary. Easier: use LIFX Cloud API (OAuth token, bypasses local). Less ideal for streaming safety (cloud dependency). |
| **Nanoleaf** | Local HTTP API similar to Elgato. Port `lights.sh` endpoints. |
| **Yeelight** | Local TCP API on port 55443. Different protocol shape. |
| **Govee** | Official API is cloud-only. For local, use the third-party `govee-lan` project. |
| **Dumb lights on a smart plug** | On/off only, no brightness/temp. Use TP-Link Kasa, Wemo, or similar via their local APIs. Edit `lights.sh` to only implement on/off. |
| **None** | Delete or empty `lights.conf`; `lights.sh` gracefully no-ops, Phase 1 still runs everything else. |

Pattern: fork `lights.sh`, keep the `on`/`off`/`status`/`discover` verb structure, swap the HTTP calls in `api_put` and `api_get`. `lockdown.sh` calls it generically.

## Webcam

The skill doesn't care which webcam you use — it only verifies OBS has a signal (Phase 5). Any USB webcam, iPhone via Continuity Camera, or capture-card-fed camera works. Frame/crop filters are OBS-side, not skill-side.

If you want the skill to verify a *specific* camera is active, extend Phase 5 with an `avfoundation` check or OBS WebSocket source query.

## Microphone

Same — skill just looks for audio-meter activity. Specific mic model doesn't matter. If you want filter verification (RNNoise active, gain set), that's an OBS-scene concern documented in `obs-scenes.md`, not a skill concern.

## Secrets management

| Swap for 1Password | How |
|---|---|
| **Bitwarden** | Use `bw` CLI. Extend `verify_secrets.sh` to add a third check: parse refs in a bitwarden-refs file, run `bw get password <id>`. |
| **Doppler** | Radically different model — Doppler injects the whole env directly. Replace the launch alias with `doppler run -- claude` and have Phase 2 verify a Doppler project is configured (`doppler configure --scope ~/.config/agents`). |
| **Infisical** | Same pattern as Doppler. `infisical run -- claude` for launch, Phase 2 verifies `infisical login` is active. |
| **macOS Keychain** | Use `security find-generic-password -s <name> -w`. Less ideal — no vault separation. |
| **Plain env vars** | Keep `expected_env_vars.txt` populated; skip 1Password entirely. Make sure those env vars aren't set in your shell *between* streams (so you don't accidentally echo them). |
| **None** | Empty both `expected_env_vars.txt` and `op_refs.txt`. Phase 2 reports N/A. Fine if your agent doesn't need API keys (e.g., Claude Code via OAuth only). |

## Terminal / shell

| Swap for Ghostty | Notes |
|---|---|
| **iTerm2** | No changes. The skill doesn't interact with terminal specifically. |
| **Terminal.app** | Same. |
| **Alacritty / Kitty / WezTerm** | Same. |
| **tmux inside any of the above** | Same. |

## IDE

No IDE integration. Window Capture in OBS is IDE-agnostic — you tell OBS which window to capture at stream time.

| IDE | Notes |
|---|---|
| **VS Code** | Window name varies by workspace. Capture by process name instead of window title if possible. |
| **Cursor** | Same. |
| **JetBrains (IntelliJ, RubyMine, etc.)** | Each IDE is a separate process/app. Pick the one you're streaming in. |
| **Neovim / Emacs** | Captured via your terminal window. No separate IDE capture needed. |
| **Zed** | Same as VS Code — window title per-workspace. |

## Operating system

The skill is macOS-specific today. Most of the interesting pieces have close analogs on other platforms but require porting:

| Phase | macOS dependency | Linux equivalent | Windows equivalent |
|---|---|---|---|
| 1. Apps quit | `pkill`-style via `osascript` | `pkill` directly | Stop-Process |
| 1. Hide desktop icons | `defaults write com.apple.finder CreateDesktop` | `gsettings` / DE-specific | PowerToys, Registry |
| 1. DnD on | `shortcuts run` + macOS Shortcut | `busctl` to control freedesktop notifications | `powershell` focus assist |
| 1. Clipboard | `pbcopy` | `xclip` / `wl-copy` | `Set-Clipboard` |
| 2. `printenv` | POSIX | POSIX | `$Env:VAR` in PowerShell |
| 3-5. Screenshots | `computer-use` MCP | Same (cross-platform) | Same |
| 6. `networkquality` | macOS Monterey+ only | Use `speedtest-cli` | Use `speedtest-cli` |

Porting PRs welcome. Contain platform-specific code in separate scripts (`lockdown-linux.sh`, etc.) and have the skill detect and dispatch.

## Skill harness

| Swap for Claude Code | Notes |
|---|---|
| **Sandboxed Claude harness** (e.g. a remote/Linux dev container) | Same SKILL.md, but Bash runs in the sandbox — skill detects this and guides you through running the lockdown commands on your local machine instead. |
| **Custom Claude API agent** | Load the SKILL.md content as system prompt, expose Bash + screenshot tools. Mostly-compatible but you'd need to implement `/prestream` invocation yourself. |
| **Other AI agent** | If it can load skill instructions and run bash, works. If it can't: read the `checklist.md` manually. |
