"""Generate a scene-frame wallpaper aligned with an OBS Main scene.

The wallpaper is the streamer's hidden alignment guide: corner brackets
mark exactly which region of the display ends up on stream, and a dashed
rectangle marks where the camera PiP will land. Off-stream margins around
the edges are scratch space for windows that should never be visible.

The wallpaper is invisible to viewers — once you apply the printed
Crop/Pad values to the OBS Display Capture source, OBS crops the
margins and labels out of frame.

Usage:
    python3 generate_scene_wallpaper.py [options]

Run with --help to see all options. Defaults are the reference setup
(3840x2160 display, 1920x1080 OBS canvas, 5% margins, 30% PiP bottom-right).
"""
import argparse
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    sys.stderr.write(
        "Pillow is required. Install with:\n  python3 -m pip install --user Pillow\n"
    )
    sys.exit(1)


def parse_args():
    p = argparse.ArgumentParser(
        description=__doc__.split("\n\n")[0],
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p.add_argument("--display-width", type=int, default=3840,
                   help="Native pixel width of the display you'll capture (default: 3840)")
    p.add_argument("--display-height", type=int, default=2160,
                   help="Native pixel height of the display you'll capture (default: 2160)")
    p.add_argument("--canvas-width", type=int, default=1920,
                   help="OBS canvas (output) width (default: 1920)")
    p.add_argument("--canvas-height", type=int, default=1080,
                   help="OBS canvas (output) height (default: 1080)")
    p.add_argument("--margin-pct", type=float, default=5.0,
                   help="Off-stream margin as %% of each dimension (default: 5)")
    p.add_argument("--pip-pct", type=float, default=30.0,
                   help="Camera PiP size as %% of stream zone (default: 30)")
    p.add_argument("--pip-corner", choices=["top-left", "top-right", "bottom-left", "bottom-right"],
                   default="bottom-right", help="PiP placement (default: bottom-right)")
    p.add_argument("--no-pip", action="store_true",
                   help="Skip the PiP cutout (full-screen scene, no camera overlay)")
    p.add_argument("--output", "-o", type=Path,
                   default=Path("scene_wallpaper.png"),
                   help="Output PNG path (default: ./scene_wallpaper.png)")
    return p.parse_args()


def aspect(w, h):
    from math import gcd
    g = gcd(w, h)
    return f"{w // g}:{h // g}"


def validate(args):
    da = args.display_width / args.display_height
    ca = args.canvas_width / args.canvas_height
    if abs(da - ca) > 0.01:
        sys.stderr.write(
            f"Warning: display aspect {aspect(args.display_width, args.display_height)} "
            f"({da:.3f}) differs from canvas aspect {aspect(args.canvas_width, args.canvas_height)} "
            f"({ca:.3f}). The stream zone will match the canvas aspect, "
            "leaving uneven margins.\n"
        )


def load_font(size):
    for path in [
        "/System/Library/Fonts/SFNSMono.ttf",
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/Library/Fonts/Arial.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ]:
        if Path(path).exists():
            try:
                return ImageFont.truetype(path, size)
            except OSError:
                continue
    return ImageFont.load_default()


def compute_layout(args):
    """Return the integer geometry as a dict.

    The stream zone matches the canvas aspect ratio exactly so OBS doesn't
    have to letterbox or stretch. Margins are scaled per-axis to preserve that.
    """
    W, H = args.display_width, args.display_height
    canvas_aspect = args.canvas_width / args.canvas_height

    # Start with proportional margins, then snap one axis so the inner
    # rectangle matches canvas aspect.
    margin_x = round(W * args.margin_pct / 100)
    margin_y = round(H * args.margin_pct / 100)

    sz_w = W - 2 * margin_x
    sz_h = H - 2 * margin_y

    inner_aspect = sz_w / sz_h
    if inner_aspect > canvas_aspect:
        # too wide — increase horizontal margin
        sz_w = round(sz_h * canvas_aspect)
        margin_x = (W - sz_w) // 2
    elif inner_aspect < canvas_aspect:
        # too tall — increase vertical margin
        sz_h = round(sz_w / canvas_aspect)
        margin_y = (H - sz_h) // 2

    sz_x0, sz_y0 = margin_x, margin_y
    sz_x1, sz_y1 = sz_x0 + sz_w, sz_y0 + sz_h

    layout = {
        "display": (W, H),
        "canvas": (args.canvas_width, args.canvas_height),
        "margin_x": margin_x,
        "margin_y": margin_y,
        "stream_zone": (sz_x0, sz_y0, sz_x1, sz_y1),
        "stream_size": (sz_w, sz_h),
        "pip": None,
    }

    if not args.no_pip:
        pip_w = round(sz_w * args.pip_pct / 100)
        pip_h = round(sz_h * args.pip_pct / 100)
        if args.pip_corner == "top-left":
            pip_x0, pip_y0 = sz_x0, sz_y0
        elif args.pip_corner == "top-right":
            pip_x0, pip_y0 = sz_x1 - pip_w, sz_y0
        elif args.pip_corner == "bottom-left":
            pip_x0, pip_y0 = sz_x0, sz_y1 - pip_h
        else:  # bottom-right
            pip_x0, pip_y0 = sz_x1 - pip_w, sz_y1 - pip_h
        layout["pip"] = (pip_x0, pip_y0, pip_x0 + pip_w, pip_y0 + pip_h)
        layout["pip_size"] = (pip_w, pip_h)

    return layout


def draw_wallpaper(layout, args):
    W, H = layout["display"]
    sz_x0, sz_y0, sz_x1, sz_y1 = layout["stream_zone"]
    sz_w, sz_h = layout["stream_size"]

    OFF_BG = (10, 12, 20)
    ON_BG = (18, 22, 34)
    BORDER = (90, 110, 150)
    PIP_LINE = (200, 90, 90)
    LABEL = (140, 160, 200)
    LABEL_DIM = (70, 85, 115)
    HATCH = (255, 255, 255, 8)

    img = Image.new("RGB", (W, H), OFF_BG)
    draw = ImageDraw.Draw(img, "RGBA")

    # Diagonal hatch in the off-stream margins.
    spacing = 36
    for k in range(-H, W + H, spacing):
        draw.line([(k, 0), (k + H, H)], fill=HATCH, width=1)

    # Stream zone — clean panel over the hatch.
    draw.rectangle([sz_x0, sz_y0, sz_x1, sz_y1], fill=ON_BG)

    # Soft border (multi-pass).
    for i, alpha in [(0, 220), (1, 160), (2, 90), (3, 40)]:
        draw.rectangle(
            [sz_x0 - i, sz_y0 - i, sz_x1 + i - 1, sz_y1 + i - 1],
            outline=(*BORDER, alpha), width=1,
        )

    # Corner brackets on stream zone.
    bracket = max(40, min(120, sz_w // 40))
    bw = max(3, sz_w // 700)
    for (cx, cy, dx, dy) in [
        (sz_x0, sz_y0, 1, 1),
        (sz_x1, sz_y0, -1, 1),
        (sz_x0, sz_y1, 1, -1),
        (sz_x1, sz_y1, -1, -1),
    ]:
        draw.line([(cx, cy), (cx + dx * bracket, cy)], fill=BORDER, width=bw)
        draw.line([(cx, cy), (cx, cy + dy * bracket)], fill=BORDER, width=bw)

    # PiP cutout.
    if layout["pip"] is not None:
        px0, py0, px1, py1 = layout["pip"]

        def dashed_rect(x0, y0, x1, y1, color, width=4, dash=24, gap=16):
            for (sa, ea, axis_y) in [(x0, x1, y0), (x0, x1, y1)]:
                x = sa
                while x < ea:
                    draw.line([(x, axis_y), (min(x + dash, ea), axis_y)],
                              fill=color, width=width)
                    x += dash + gap
            for (sa, ea, axis_x) in [(y0, y1, x0), (y0, y1, x1)]:
                y = sa
                while y < ea:
                    draw.line([(axis_x, y), (axis_x, min(y + dash, ea))],
                              fill=color, width=width)
                    y += dash + gap

        dash_w = max(3, sz_w // 800)
        dashed_rect(px0, py0, px1, py1, PIP_LINE,
                    width=dash_w + 1, dash=28, gap=18)

        pb = max(30, min(80, (px1 - px0) // 18))
        for (cx, cy, dx, dy) in [
            (px0, py0, 1, 1),
            (px1, py0, -1, 1),
            (px0, py1, 1, -1),
            (px1, py1, -1, -1),
        ]:
            draw.line([(cx, cy), (cx + dx * pb, cy)], fill=PIP_LINE, width=dash_w + 4)
            draw.line([(cx, cy), (cx, cy + dy * pb)], fill=PIP_LINE, width=dash_w + 4)

    # Fonts scaled to display size.
    base = max(W, H)
    font_md = load_font(max(20, base // 144))
    font_sm = load_font(max(16, base // 192))

    def text_centered(txt, cx, cy, font, fill):
        bbox = draw.textbbox((0, 0), txt, font=font)
        tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
        draw.text((cx - tw // 2, cy - th // 2), txt, font=font, fill=fill)

    margin_y = layout["margin_y"]
    margin_x = layout["margin_x"]
    text_centered("OFF-STREAM", W // 2, margin_y // 2, font_md, LABEL_DIM)
    text_centered("OFF-STREAM", W // 2, H - margin_y // 2, font_md, LABEL_DIM)

    line_h = max(24, base // 240)
    label = "OFF-STREAM"
    label_h = len(label) * line_h
    top = H // 2 - label_h // 2
    for i, ch in enumerate(label):
        text_centered(ch, margin_x // 2, top + i * line_h, font_md, LABEL_DIM)
        text_centered(ch, W - margin_x // 2, top + i * line_h, font_md, LABEL_DIM)

    text_centered(
        f"STREAM ZONE  •  {sz_w} x {sz_h}",
        sz_x0 + sz_w // 2, sz_y0 + 60, font_md, LABEL,
    )

    if layout["pip"] is not None:
        px0, py0, px1, py1 = layout["pip"]
        # Place camera label just outside the PiP, on the side toward the zone center.
        label_y = py0 - 40 if py0 > sz_y0 + 80 else py1 + 40
        text_centered(
            f"CAMERA  •  {args.pip_pct:g}%",
            (px0 + px1) // 2, label_y, font_md, PIP_LINE,
        )

    # Subtle center crosshair.
    cx, cy = sz_x0 + sz_w // 2, sz_y0 + sz_h // 2
    draw.line([(cx - 30, cy), (cx + 30, cy)], fill=(*BORDER, 80), width=2)
    draw.line([(cx, cy - 30), (cx, cy + 30)], fill=(*BORDER, 80), width=2)

    # Reference lines in bottom margin.
    ref = [
        f"OBS canvas  •  {args.canvas_width} x {args.canvas_height}",
        f"Display     •  {W} x {H}",
        f"Stream zone •  {sz_w} x {sz_h}  (capture this region — see Crop/Pad values printed by this script)",
    ]
    for i, line in enumerate(ref):
        draw.text((margin_x + 8, H - margin_y + 18 + i * (line_h - 4)),
                  line, font=font_sm, fill=LABEL_DIM)

    return img


def print_obs_instructions(layout, args):
    """Print the OBS Crop/Pad filter values that align Display Capture with the wallpaper."""
    sz_x0, sz_y0, sz_x1, sz_y1 = layout["stream_zone"]
    sz_w, sz_h = layout["stream_size"]
    margin_x = layout["margin_x"]
    margin_y = layout["margin_y"]
    W, H = layout["display"]

    print()
    print("=" * 64)
    print("  OBS setup — Display Capture for the streamed display")
    print("=" * 64)
    print()
    print("1. Add a Display Capture source for this display in the Main scene.")
    print("2. Right-click → Filters → + → Crop/Pad with these values:")
    print(f"     Left   = {margin_x}")
    print(f"     Right  = {W - sz_x1}")
    print(f"     Top    = {margin_y}")
    print(f"     Bottom = {H - sz_y1}")
    print(f"   (cropped source: {sz_w} x {sz_h})")
    print()
    print("3. Right-click the source → Transform → Edit Transform:")
    print(f"     Position X=0, Y=0; resize to fill the {args.canvas_width} x {args.canvas_height} canvas.")
    print("   (Or right-click → Transform → Fit to Screen.)")
    print()
    if layout["pip"] is not None:
        px0, py0, px1, py1 = layout["pip"]
        pip_w, pip_h = layout["pip_size"]
        # Project the PiP rectangle into canvas coordinates.
        scale_x = args.canvas_width / sz_w
        scale_y = args.canvas_height / sz_h
        cx0 = round((px0 - sz_x0) * scale_x)
        cy0 = round((py0 - sz_y0) * scale_y)
        cw = round(pip_w * scale_x)
        ch = round(pip_h * scale_y)
        print("4. Webcam transform (in canvas pixels) to land over the cutout:")
        print(f"     Position X={cx0}, Y={cy0}")
        print(f"     Size     {cw} x {ch}")
        print()
    print("=" * 64)


def main():
    args = parse_args()
    validate(args)
    layout = compute_layout(args)
    img = draw_wallpaper(layout, args)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    img.save(args.output, "PNG", optimize=True)
    print(f"Wrote {args.output}  ({args.output.stat().st_size // 1024} KB)")
    print_obs_instructions(layout, args)


if __name__ == "__main__":
    main()
