# Scene-frame wallpaper

A desktop wallpaper that visually marks the region of your display that ends up on stream, plus a labelled cutout where the camera PiP sits. Off-stream margins around the edge are scratch space — drag windows you don't want streamed (e.g., Slack, password manager, second IDE) into the margins and they stay private even though the display is still being captured.

The wallpaper is a streamer-only alignment guide. Once you apply the matching OBS Crop/Pad filter, the margins (and all the labels) sit outside the captured region, so viewers never see them.

## Why bother

Streaming a region of your display by eye is fragile: you accidentally drag a window into the captured area, you don't notice the camera PiP overlapping a critical UI element, you forget that the bottom-right is "covered" and put your terminal there. A visible frame eliminates all three problems — the captured rectangle is literally drawn on your desktop.

## What you get

```
┌──────────────── DISPLAY ───────────────────┐
│   off-stream  ┌── stream zone ──┐ off-     │
│   (hatched)   │  STREAM ZONE    │ stream   │
│               │  4096 x 2304    │          │
│               │                 │          │
│               │           ┌──┐  │          │
│               │           │CAM  │          │
│               │           └──┘  │          │
│               └─────────────────┘          │
└────────────────────────────────────────────┘
```

- A clean dark rectangle marking the **stream zone** — what OBS actually captures
- Subtle diagonal hatching in the **off-stream margins** so it's obvious those edges are private
- A dashed red rectangle for the **camera PiP cutout**, sized to match your webcam transform
- A center crosshair for window alignment
- Reference text in one margin printing the canvas dimensions and stream zone size

## Generate it

```bash
python3 tools/generate_scene_wallpaper.py \
  --display-width 3840 --display-height 2160 \
  --canvas-width 1920 --canvas-height 1080 \
  --margin-pct 5 \
  --pip-pct 30 --pip-corner bottom-right \
  --output ~/Pictures/scene_wallpaper.png
```

Defaults match the reference Main scene (3840×2160 display, 1920×1080 canvas, 5% margins, 30% PiP bottom-right) — running with no flags produces the same wallpaper used in this repo's reference setup.

After generating, the script prints exact OBS Crop/Pad values that align Display Capture with the wallpaper. Copy those into OBS once and the alignment is permanent.

### Options

| Flag | Default | Notes |
|---|---|---|
| `--display-width`, `--display-height` | 3840, 2160 | Native pixel dimensions of the display you're capturing |
| `--canvas-width`, `--canvas-height` | 1920, 1080 | OBS canvas (output) resolution |
| `--margin-pct` | 5 | Off-stream margin on each side, as a percentage |
| `--pip-pct` | 30 | Camera PiP size as a percentage of the stream zone |
| `--pip-corner` | bottom-right | One of `top-left`, `top-right`, `bottom-left`, `bottom-right` |
| `--no-pip` | — | Skip the cutout (full-screen scene with no overlay) |
| `--output`, `-o` | `./scene_wallpaper.png` | Output path |

The script emits a warning if the display and canvas aspect ratios disagree — the stream zone always matches the canvas aspect to keep OBS scaling clean, so a non-matching display will end up with uneven margins.

## Apply the OBS Crop/Pad filter

The script prints the exact values, but the steps are:

1. **Set the wallpaper** on the display you'll capture. On macOS:
    ```bash
    osascript -e 'tell application "System Events" to set picture of (first desktop whose name is "DELL U2718Q") to "/path/to/scene_wallpaper.png"'
    ```
    (Replace the desktop name with yours — `osascript -e 'tell application "System Events" to get name of every desktop'` lists them.)

2. **Add Display Capture** for that display in the Main scene.

3. **Right-click → Filters → + → Crop/Pad** and enter the printed Left/Right/Top/Bottom values.

4. **Transform → Fit to Screen** so the cropped capture fills the canvas.

5. **Verify**: the OBS preview shows your stream zone (no labels, no margins). Drag a test window into the margin — it should stay outside the OBS preview. Position the camera PiP so it aligns over the dashed cutout.

## When to regenerate

Anytime you change:

- The streamed display (different monitor → different native resolution)
- The OBS canvas size (1920×1080 → 2560×1440 etc.)
- Webcam size or corner (e.g., shrinking from 30% to 25%)
- How much off-stream space you want (more margins = smaller stream zone)

The script is idempotent — re-running with the same args produces a byte-identical PNG.

## Caveats

- **Display Capture vs. Window Capture.** This wallpaper is for Display Capture sources. If your Main scene uses Window Capture instead, the wallpaper underneath the captured window is invisible to the stream — there's nothing to align. Window Capture has its own tradeoffs (see [`obs-scenes.md`](obs-scenes.md)).
- **Notifications still leak.** A wallpaper does nothing about banner notifications appearing inside the stream zone. Keep DND on while streaming (`prestream` handles this).
- **Multi-monitor.** Set the wallpaper only on the display you're capturing. Other displays can have whatever wallpaper you like.
- **Wallpaper "Stage Manager" / Mission Control.** macOS sometimes covers the wallpaper momentarily during these transitions. The captured frame still shows the wallpaper underneath any open window, so this matters only when nothing's on top.
