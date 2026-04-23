# Tab allowlist for streaming browser profile

Only these categories of tabs should be open in the streaming Chrome profile while live. Anything else is a yellow flag — ask the streamer before proceeding.

## ✅ Allowed categories

- **Docs for the library, API, or framework** being worked on (MDN, language docs, npm/crates.io/pkg docs, Stripe docs, AWS docs, etc.)
- **GitHub** — the repo being built in, or adjacent repos being referenced. Personal orgs are OK; watch out for private-org repos with sensitive names.
- **localhost** or preview URLs for the project in progress
- **AI tool interfaces** — claude.ai, chatgpt.com, console.anthropic.com (but NOT the billing/API key pages — those are red)
- **Stack Overflow, GitHub Discussions** and other technical Q&A
- **A blank new-tab page**
- **Stream platform broadcast console** — e.g. `studio.youtube.com` (YouTube Studio), Twitch Dashboard, `studio.x.com/producer/*` (X Producer). These are broadcast-control pages designed to be shown on-stream.

## ⚠️ Yellow flags — ask the streamer

- Personal blogs or Substacks
- Hacker News, Reddit (unless on-topic for the stream)
- News sites
- Any tab opened hours ago and forgotten about

## 🔴 Hard stops — do not proceed

Any of these tabs open = red verdict until closed:

- Gmail, Outlook, Proton Mail, any webmail inbox
- Banking, investment, trading, crypto exchange
- Amazon, Shopify admin, or any shopping cart with payment info
- Personal social: personal FB, Instagram, personal LinkedIn feed
- The main (non-streaming) workspace Slack/Discord in browser
- Any API provider's key management or billing page showing actual keys
- Password manager web vault (1Password.com, Bitwarden vault)
- Health portals, patient records, or anything HIPAA-adjacent
- Personal calendar with real event titles visible
- Internal company dashboards, Notion workspaces, Linear, Jira — unless the streamer explicitly wants them on stream
- Anything in "incognito" that's been forgotten about
- **Social-media main feeds** (home, DMs, notifications pages) for any platform, even if the streaming channel lives on that same platform. Example: if streaming on X, `studio.x.com` is safe but `x.com/home`, `x.com/messages`, `x.com/notifications`, and `x.com/[handle]` (profile page) are RED. Same pattern for YouTube (youtube.com main vs studio.youtube.com), Twitch, etc.

## Profile check

If you can programmatically detect the Chrome profile (e.g., via extension-aware browser MCP), confirm it matches the streamer's dedicated streaming profile. If you can't, ask them to visually confirm the profile avatar in the top-right corner of Chrome matches the Stream profile, not their main one.

Note: Google Workspace accounts often show "Work" as the default profile chip label regardless of what you rename it to. Use the avatar image/color to visually distinguish profiles; the chip label alone may be unreliable.
