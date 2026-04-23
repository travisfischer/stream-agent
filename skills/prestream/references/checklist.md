# Pre-Stream Checklist

A personal, opinionated pre-flight checklist for livestreaming AI coding sessions from a macOS (Apple Silicon) setup. Designed to be skim-able in under 2 minutes once you're used to it, and to be the source of truth for the companion `prestream` Claude skill.

**The core philosophy:** anything visible on your screen while live is effectively public forever. The purpose of this checklist is to make "nothing bad is visible" a systematic state you can verify, not a vibe you hope is true.

---

## T-30 min — Physical / personal

- [ ] Hydrated, fed, bathroom break taken
- [ ] Room lighting good (natural light or key light on your face)
- [ ] Phone on silent or in another room
- [ ] Household knows you'll be live (doors closed, pets settled)
- [ ] Wearing what you want on camera

---

## T-15 min — Environment lockdown

### Notifications & messaging
- [ ] macOS **Focus / Do Not Disturb** is ON (moon icon in menu bar)
- [ ] **Slack** is fully quit (⌘Q, not just closed window)
- [ ] **Messages** is fully quit
- [ ] **Discord** is fully quit
- [ ] Any other comms apps that could pop notifications are quit

### Desktop & filesystem visibility
- [ ] **Desktop icons hidden** (`defaults write com.apple.finder CreateDesktop false && killall Finder`)
- [ ] Dock cleaned of any app that could be embarrassing or identifying
- [ ] No sensitive Finder windows open in the background

### Menu bar hygiene
- [ ] Menu bar doesn't show: Dropbox/Drive sync with identifying filenames, 1Password vault name, personal calendar event titles, any app with your real name or workplace visible

---

## T-10 min — Browser & tabs

- [ ] Frontmost Chrome window is the **Stream profile**, not your main profile
- [ ] Only allowlisted tabs are open. Suggested allowlist:
  - Docs for the library/API you're working with
  - GitHub repo you're building in
  - `localhost` or preview URLs for your project
  - AI tool you're using (Claude, etc.)
- [ ] Bookmarks bar hidden OR curated to show nothing personal
- [ ] No tabs that show: email, personal social, banking, Amazon, analytics dashboards, private Slack workspaces, calendar with names

---

## T-10 min — Secrets & identity

- [ ] API keys are loaded as **env vars**, not visible in any file
- [ ] No `.env` files open in your editor
- [ ] `git config user.email` — confirm you're comfortable with the email that will show on commits
- [ ] Terminal prompt doesn't leak: real username, hostname, workplace, identifying path
- [ ] `~/.zsh_history` reviewed or shell started with `HISTFILE=/dev/null` for this session
- [ ] No credit card numbers, auth codes, or recovery phrases anywhere on the visible desktop

---

## T-5 min — OBS technical

- [ ] OBS is running and showing the **Main** scene
- [ ] Preview window shows: IDE/terminal capture looks right, webcam is framed well, no other apps bleeding through
- [ ] Audio levels: speak normally — mic meter peaks around -12 dB to -6 dB, never hits 0 dB / red
- [ ] Desktop audio muted or intentionally enabled (pick one)
- [ ] RNNoise / noise suppression filter active on mic
- [ ] **BRB scene** is set up and the hotkey (e.g., ⌘F12) switches to it instantly
- [ ] Correct destination(s) configured — YouTube / Twitch / Restream endpoint
- [ ] Stream key is set and not expired
- [ ] Local recording will start alongside stream (belt and suspenders — backup VOD)

---

## T-5 min — Connectivity

- [ ] Internet speed test shows upload ≥ 2× your target bitrate (so: ≥ 10 Mbps up for 1080p at 5000 kbps)
- [ ] Wired ethernet preferred; if on Wi-Fi, confirm you're on 5 GHz band near router
- [ ] VPN off (unless you specifically need it — many VPNs throttle streaming)

---

## T-1 min — Final human judgment (only you can check these)

- [ ] Mic sounds clear and natural when I speak at normal volume
- [ ] Camera framing is flattering and stable
- [ ] Room behind me in shot has nothing private visible
- [ ] I know what I'm streaming about today (not going in cold)
- [ ] I've accepted that anything I say/show is public

---

## Going live

- [ ] Click **Start Streaming** in OBS
- [ ] Wait ~30 seconds, verify the stream appears on the destination platform
- [ ] Watch the first few seconds back on the platform in a separate device (phone) — confirm audio and video are good
- [ ] Start talking, do a quick mic-check with viewers if anyone's already there

---

## Mid-stream: red-flag reflexes

If any of these happen, hit BRB hotkey FIRST, then deal with it off-stream:

- Notification or DM slipped through
- Wrong window came forward (email, messages, personal tab)
- About to paste something you haven't seen the content of
- Need to check an API key, password, or any secret
- Physical interruption (family, delivery, etc.)
- Something feels off and you don't have time to evaluate

The BRB scene is free — use it liberally. Viewers don't mind. Leaked secrets are expensive.

---

## After the stream

- [ ] Click **Stop Streaming** in OBS
- [ ] Verify local recording saved successfully
- [ ] Turn off Focus / Do Not Disturb
- [ ] **Rotate any secret you suspect may have been glimpsed**, even partially — don't rationalize
- [ ] Unhide desktop if you want (`defaults write com.apple.finder CreateDesktop true && killall Finder`)
- [ ] Watch the first 2–3 minutes of the VOD with fresh eyes — catch anything you missed
- [ ] Jot notes: what went well, what to fix for next stream

---

## If something leaked

Don't panic. In order:

1. **Stop the stream** if it's still live
2. **Delete the VOD** on the platform ASAP (YouTube and Twitch both let you do this from the dashboard)
3. **Rotate the leaked credential** (Anthropic key, OpenAI key, GitHub token, etc. — whichever applies)
4. **Check usage logs** on the affected service for anomalies
5. Note what happened in your post-stream journal so you can harden the checklist

---

*This doc pairs with the `prestream` Claude skill, which automates the portions of this checklist that don't require human judgment.*
