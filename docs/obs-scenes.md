# OBS scenes — the reference setup

The scene collection used by the reference setup. Five scenes. Copy the structure, tune sources to what you use.

## Scene 1: Starting Soon

**Purpose:** show this before you go live. Lets viewers see something's about to happen while you do final prep.

**Sources:**
- Text (FreeType 2): `Starting Soon...`
  - Font: Helvetica (or any system font), 256pt, white
  - Center on canvas via right-click → Transform → Center to Screen

Optional add-ons:
- Audio source playing background music (muted at start, unmute before going live)
- A static image or color source behind the text

## Scene 2: Main

**Purpose:** your working scene during a coding stream. IDE, terminal, webcam overlay.

**Sources** (top-to-bottom in the source list = front-to-back in the render order — top renders on top):
1. **Webcam overlay** (Video Capture Device) — your webcam, usually bottom-right corner
2. **Terminal window** (macOS Screen Capture → Window mode → pick your terminal)
3. **IDE window** (macOS Screen Capture → Window mode → pick your IDE)

Optionally, a fourth bottom source of a solid color or a wallpaper-style image fills any background gaps.

**Webcam setup details:**

1. Add a **Video Capture Device** source, pick your webcam from the dropdown
2. The webcam fills the canvas by default — you want it in a corner
3. Right-click the source → **Filters** → add an **Effect Filter → Crop/Pad**
   - Crop to remove empty background and tighten on your face. Typical starting values (for 1920x1080 source, window on your left): Left=450, Right=100, Top=155, Bottom=155. Tune via preview.
4. Close the filter dialog
5. Right-click the source → **Transform → Edit Transform**
   - Set Width: 576, Height: 324 (30% of canvas) — or 480x270 (25%) for smaller
   - Set X: 1344, Y: 756 — bottom-right corner flush (if canvas is 1920x1080 and size is 576x324)

If you tweak crop values, the Transform Size fields auto-adjust to reflect the post-filter dimensions. Re-enter your desired display size after each crop change.

**Optional polish — scene-frame wallpaper.** If you use Display Capture (not Window Capture) and want a visible-only-to-you guide showing exactly where the stream zone and camera PiP land, see [`scene-wallpaper.md`](scene-wallpaper.md). The generator produces a wallpaper aligned to the values above and prints the matching OBS Crop/Pad filter to apply.

**Window Capture caveat:** macOS Screen Capture sources target a specific window by title. If you quit and reopen that app, OBS will re-find it by name — usually OK, but double-check before going live. For safety, prefer **Window** mode over **Display** mode; Display mode captures everything on that monitor including notifications.

## Scene 3: Camera

**Purpose:** full-screen webcam for "just talking" moments — explaining a concept, answering chat, transitioning between topics.

**Sources:**
- The SAME Webcam source as Main (use **Add Existing** when adding, not **Create New**). This way both scenes share one underlying source, including the Crop/Pad filter — edit one, both update.

After adding, transform to fill the canvas: right-click → Transform → **Fit to Screen**. The cropped webcam fills the 1920x1080 canvas maintaining 16:9.

## Scene 4: BRB

**Purpose:** "Be Right Back" — for bathroom breaks, interruptions, or when you need to handle something off-stream.

**Sources:**
- Text (FreeType 2): `Be Right Back`
- Center on canvas

Optional:
- Background music
- Animated GIF / video loop

**Wire a hotkey:** Settings → Hotkeys → search for "switch to scene" → find the BRB row → click in the field → press the key combo (e.g., ⌘F12 on macOS). Now anywhere in OBS, that combo snaps to BRB instantly. Useful when something unexpected happens on-screen and you need to hide fast.

Also consider adding hotkeys for Main and Camera if you switch scenes often. Note: OBS hotkeys only fire when OBS is the frontmost app. For global hotkeys that work while your IDE is focused, use a tool like BetterTouchTool or Karabiner to map a key combo to send the OBS shortcut.

## Scene 5: Ending

**Purpose:** show this right before you click Stop Streaming.

**Sources:**
- Text (FreeType 2): `Thanks for watching!`
- Use **Fit to Screen** if the text overflows at large sizes (longer phrases at 256pt won't fit horizontally).

## Global audio setup (not scene-specific)

**Mic input (Mic/Aux in Audio Mixer):**
- Target peak level: **−12 dB to −6 dB** during normal speech
- Hard cap at 0 dB (red = clipping = distortion)
- Add filters on the mic source (click the gear icon → Filters):
  - **Noise Suppression** → method: RNNoise (best quality)
  - **Noise Gate** → below -30 dB = silence (cuts room tone)
  - **Compressor** → ratio 2:1, threshold -18, attack 10ms, release 100ms (evens out levels)
  - **Limiter** → threshold -1 dB (prevents clipping)
  - Order matters: gate → compressor → limiter → noise suppression

**Desktop audio** — usually **mute** unless you intentionally want OS sounds / app audio on stream. It's a common leak path (Discord ping, Slack, any notification sound).

## Scene collection export

Once your scenes are set up, save the Scene Collection via **Scene Collection → Rename...** to a meaningful name (e.g., "AI Coding Stream"). This lets you switch between scene collections if you build multiple (e.g., one for coding streams, one for guest interviews).

To version-control your OBS configuration, export the scene collection JSON: **Scene Collection → Export...** → save the JSON somewhere in-repo. Others can import it as a starting point.

## Going live

From the scene flow perspective:

1. Start on **Starting Soon** — pre-stream prep window
2. Click **Start Streaming**
3. Wait ~30 seconds for the stream to establish on the platform
4. Switch to **Main** when you're ready to start talking
5. Switch to **Camera** for talking-head moments
6. **BRB** for breaks
7. **Ending** before hitting Stop Streaming
8. Click **Stop Streaming**
9. Verify the local recording saved (if you had **Start Recording** enabled too)

Consider setting **Scene Transitions** to **Fade** (300ms) in the Controls panel — smoother than the default cut transition and more forgiving if you briefly flash a wrong scene.
