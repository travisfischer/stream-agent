# stream-agent

An AI agent's toolkit for managing livestream workflows — starting with a rigorous pre-flight safety check, growing toward full streaming automation.

> **Status: v0.1** — one skill, `prestream`. Production-tested on macOS + OBS + X Live. More skills planned.

## Why

If you stream AI coding sessions from your main machine, a single slip leaks forever — a notification with a friend's name, an autofill suggesting your home address, an API key echoed in a terminal, a browser tab you forgot about. This toolkit makes "nothing sensitive on screen" a systematic state your agent can verify, not a vibe you hope is true.

Design principle: a 🔴/🟡/🟢 verdict you can trust, delivered in under 2 minutes, with enough detail that a yellow or red tells you exactly what to fix.

## What `prestream` does

Eight phases. Each either automated (agent runs a script) or asks you directly:

1. **Environment detection** — adapts whether the agent runs on your Mac (full automation) or in a sandbox (guides you through the shell commands).
2. **Lockdown** — quits messaging apps (Slack/Messages/Discord), hides desktop icons, turns on Do Not Disturb via a macOS Shortcut, clears clipboard, turns on your smart lights to preset brightness/temp.
3. **Secrets verification** — checks that either (a) expected host env vars are set, or (b) your 1Password `op://` refs resolve, depending on how you manage credentials.
4. **Desktop audit** — screenshot-based: looks for anything identifying in menu bar, Dock, or background windows.
5. **Browser audit** — verifies you're in your dedicated streaming Chrome profile, audits open tabs against an allowlist.
6. **OBS check** — confirms OBS is running, the right scene is active, mic is showing signal.
7. **Bandwidth** — runs `networkquality`, checks upload against a threshold (10+ Mbps → green).
8. **Human judgment** — the four things only you can judge: mic, camera, room, topic.

Then a decisive 🟢 / 🟡 / 🔴 verdict with a punch list of fixes if needed.

## Quick install

```bash
git clone https://github.com/travisfischer/stream-agent.git
cp -r stream-agent/skills/prestream ~/.claude/skills/
chmod +x ~/.claude/skills/prestream/scripts/*.sh
cp ~/.claude/skills/prestream/references/lights.conf.example \
   ~/.claude/skills/prestream/references/lights.conf
# (then edit lights.conf for your lights — or run discover below)
```

Then in [Claude Code](https://code.claude.com): say "run a prestream check" or invoke `/prestream`.

First-time light setup:

```bash
bash ~/.claude/skills/prestream/scripts/lights.sh discover
# follow the output to populate lights.conf
```

See [`docs/setup.md`](docs/setup.md) for the full setup guide including 1Password CLI, macOS Shortcuts, and OBS scene configuration.

## Reference setup

The skill is built and tested against the stack below. Yours can differ — see [`docs/alternatives.md`](docs/alternatives.md) for drop-in swaps for streaming software, lights, secrets managers, platforms, and operating systems.

| Component       | Reference                                     |
|-----------------|-----------------------------------------------|
| Machine         | MacBook Pro, Apple Silicon, macOS 12+         |
| Agent           | Claude Code (daily driver)                    |
| IDE             | Cursor                                        |
| Terminal        | Ghostty                                       |
| Streaming       | OBS Studio → X Live (Twitter/X)               |
| Webcam          | Logitech MX Brio (USB, 4K)                    |
| Microphone      | Blue Yeti (USB condenser)                     |
| Lights          | 2× Elgato Key Light Air                       |
| Secrets         | 1Password 8 + CLI, dedicated "Agents" vault   |
| Browser         | Chrome with dedicated "Stream" profile        |

## Full setup guide

→ [`docs/setup.md`](docs/setup.md) — install the skill, configure lights, set up 1Password, create macOS Shortcuts, install the Claude in Chrome extension.

→ [`docs/obs-scenes.md`](docs/obs-scenes.md) — build the OBS scene collection (Starting Soon / Main / Camera / BRB / Ending) and configure webcam with color crop/scale filters.

→ [`docs/scene-wallpaper.md`](docs/scene-wallpaper.md) — generate a desktop wallpaper that visually marks your OBS stream zone and camera-PiP cutout (streamer-only alignment guide).

→ [`docs/alternatives.md`](docs/alternatives.md) — swap options for hardware, software, streaming platforms, and secrets managers.

## Repo structure

```
stream-agent/
├── README.md                   # you are here
├── LICENSE                     # MIT
├── .gitignore
├── skills/
│   └── prestream/              # the Claude Code skill
│       ├── SKILL.md            # main skill instructions
│       ├── scripts/
│       │   ├── lockdown.sh     # Phase 1: apps, desktop, DnD, clipboard, lights
│       │   ├── unlock.sh       # post-stream reverse
│       │   ├── lights.sh       # Elgato Key Light control (on/off/status/discover)
│       │   └── verify_secrets.sh # Phase 2: env-var + op-ref check
│       └── references/
│           ├── checklist.md             # the human-readable master checklist
│           ├── tab_allowlist.md         # what tabs are OK / yellow / red
│           ├── lights.conf.example      # template for your lights
│           ├── expected_env_vars.txt    # list of env vars to verify set
│           └── op_refs.txt              # list of 1Password refs to verify
├── docs/
│   ├── setup.md                # detailed setup guide
│   ├── alternatives.md         # swap options for different stacks
│   ├── obs-scenes.md           # OBS scene-by-scene walkthrough
│   └── scene-wallpaper.md      # streamer-only alignment wallpaper
└── tools/
    └── generate_scene_wallpaper.py  # build the wallpaper for your setup
```

## Potential future directions

Ideas for additional skills that fit the agent-managed-streaming theme:

- **post-stream**: VOD-review helper, "did-anything-glimpse-a-credential" checker, recording backup
- **guest-join**: VDO.Ninja flow for remote co-hosts
- **chat-moderation**: Twitch/X/YouTube chat unification, moderation prompts
- **scene-automation**: "going to BRB for 5 minutes" with timed return, animated transitions
- **simulcast**: Restream.io / multi-destination ingest
- **alert integration**: subscriber/follower event handling

Nothing here is committed — open an issue if you want to collaborate on one, or PR your own.

## Contributing

Contributions welcome. For bug fixes: PR directly. For new skills or large changes: open an issue first to discuss scope.

When adding new features:
- Keep secrets / personal info out of default configs — use `.example` templates
- Document alternatives when you make a platform-specific choice
- Test on a fresh macOS user or VM to catch implicit environment assumptions

## License

MIT — see [LICENSE](LICENSE). Use, fork, remix freely.
