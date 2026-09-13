"""Generate NutriGuide branding assets: launcher icon (1024 + 512),
adaptive-icon foreground, and the Play Store feature graphic.

Run from the repo root with the backend venv's Python:

    backend/.venv/Scripts/python app/tool/generate_assets.py

Outputs to app/assets/branding/:
    icon.png                1024x1024 full-bleed legacy/store icon
    icon-512.png             512x512  Play Console store icon
    adaptive-foreground.png 1024x1024 transparent, content in safe zone
    feature-graphic.png     1024x500  Play Store feature graphic

All shapes are drawn vector-style with 4x supersampling for clean edges.
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

OUT_DIR = Path(__file__).resolve().parents[1] / "assets" / "branding"

# Brand greens (matches AppTheme seed #2E7D32).
GREEN_LIGHT = (67, 160, 71)    # #43A047
GREEN_DEEP = (21, 87, 35)      # #155823
WHITE = (255, 255, 255)

SS = 4  # supersampling factor


def vertical_gradient(size: tuple[int, int], top: tuple, bottom: tuple) -> Image.Image:
    """Vertical linear gradient with a subtle top-left light bias."""
    w, h = size
    base = Image.new("RGB", (1, h))
    for y in range(h):
        f = y / max(h - 1, 1)
        base.putpixel(
            (0, y),
            tuple(int(top[i] + (bottom[i] - top[i]) * f) for i in range(3)),
        )
    img = base.resize((w, h))
    return img


def heart_points(cx: float, cy: float, scale: float, n: int = 240) -> list[tuple[float, float]]:
    """Classic parametric heart curve centered at (cx, cy)."""
    pts = []
    for i in range(n):
        t = 2 * math.pi * i / n
        x = 16 * math.sin(t) ** 3
        y = (
            13 * math.cos(t)
            - 5 * math.cos(2 * t)
            - 2 * math.cos(3 * t)
            - math.cos(4 * t)
        )
        # Curve spans x in [-16,16], y in [-17,12]; recenter y to 0.
        pts.append((cx + x * scale, cy - (y + 2.5) * scale))
    return pts


def leaf_points(cx: float, cy: float, length: float, half_width: float,
                angle_deg: float, n: int = 60) -> list[tuple[float, float]]:
    """A pointed leaf: two quadratic beziers from base to tip, mirrored."""
    a = math.radians(angle_deg)
    cos_a, sin_a = math.cos(a), math.sin(a)

    def rot(px: float, py: float) -> tuple[float, float]:
        return (cx + px * cos_a - py * sin_a, cy + px * sin_a + py * cos_a)

    tip = rot(-length / 2, 0)
    base = rot(length / 2, 0)
    ctrl_l = rot(0, half_width)
    ctrl_r = rot(0, -half_width)

    left = [
        (
            (1 - f) ** 2 * base[0] + 2 * (1 - f) * f * ctrl_l[0] + f**2 * tip[0],
            (1 - f) ** 2 * base[1] + 2 * (1 - f) * f * ctrl_l[1] + f**2 * tip[1],
        )
        for f in (i / n for i in range(n + 1))
    ]
    right = [
        (
            (1 - f) ** 2 * tip[0] + 2 * (1 - f) * f * ctrl_r[0] + f**2 * base[0],
            (1 - f) ** 2 * tip[1] + 2 * (1 - f) * f * ctrl_r[1] + f**2 * base[1],
        )
        for f in (i / n for i in range(n + 1))
    ]
    return left + right


def midrib_line(cx: float, cy: float, length: float, angle_deg: float,
                bow: float, n: int = 40) -> list[tuple[float, float]]:
    """Slightly curved center vein of the leaf."""
    a = math.radians(angle_deg)
    cos_a, sin_a = math.cos(a), math.sin(a)
    pts = []
    for i in range(n + 1):
        f = i / n
        px = -length / 2 + length * f
        py = bow * math.sin(math.pi * f)
        pts.append((cx + px * cos_a - py * sin_a, cy + px * sin_a + py * cos_a))
    return pts


def draw_polyline(draw: ImageDraw.ImageDraw, pts: list[tuple[float, float]], width: int):
    draw.line(pts, fill=WHITE, width=width, joint="curve")


def render_emblem(emblem_px: int, canvas_px: int) -> Image.Image:
    """The heart-with-leaf-cutout emblem, centered on a transparent canvas.

    emblem_px is the heart height in final pixels; canvas_px the output size.
    """
    size = canvas_px * SS
    es = emblem_px * SS  # emblem scale in supersampled px

    # Heart curve: 29.5 units tall (y from -14.5 to +15 after recenter).
    scale = es / 29.5
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)

    heart = heart_points(size / 2, size / 2, scale)
    d.polygon(heart, fill=WHITE + (255,))

    # Leaf cutout: paste the gradient through a leaf-shaped mask so the leaf
    # reads as a cutout revealing the background.
    gradient = vertical_gradient((size, size), GREEN_LIGHT, GREEN_DEEP)
    mask = Image.new("L", (size, size), 0)
    md = ImageDraw.Draw(mask)

    leaf_len = es * 0.62
    leaf = leaf_points(size / 2, size / 2 + es * 0.02, leaf_len,
                       leaf_len * 0.30, angle_deg=32)
    md.polygon(leaf, fill=255)
    layer.paste(gradient, (0, 0), mask)

    # White midrib over the cutout leaf.
    ld = ImageDraw.Draw(layer)
    draw_polyline(ld, midrib_line(size / 2, size / 2 + es * 0.02, leaf_len * 0.86,
                                  32, bow=es * 0.02),
                  width=max(2, int(es * 0.035)))

    return layer.resize((canvas_px, canvas_px), Image.LANCZOS)


def build_full_icon(canvas_px: int) -> Image.Image:
    """Full-bleed square icon: gradient background + emblem."""
    bg = vertical_gradient((canvas_px, canvas_px), GREEN_LIGHT, GREEN_DEEP)
    emblem = render_emblem(int(canvas_px * 0.62), canvas_px)
    icon = bg.convert("RGBA")
    icon.alpha_composite(emblem)
    return icon.convert("RGB")


def build_adaptive_foreground() -> Image.Image:
    """Transparent 1024x1024 with the emblem inside the 66% safe zone."""
    canvas = 1024
    fg = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    emblem = render_emblem(int(canvas * 0.44), canvas)
    fg.alpha_composite(emblem)
    return fg


def _font(candidates: list[str], px: int) -> ImageFont.FreeTypeFont:
    for name in candidates:
        path = Path("C:/Windows/Fonts") / name
        if path.exists():
            return ImageFont.truetype(str(path), px)
    return ImageFont.load_default()


def build_feature_graphic() -> Image.Image:
    w, h = 1024, 500
    bg = vertical_gradient((w, h), GREEN_LIGHT, GREEN_DEEP).convert("RGBA")

    emblem = render_emblem(int(h * 0.62), h)
    bg.alpha_composite(emblem, (60, int(h * 0.14)))

    title_font = _font(["segoeuib.ttf", "arialbd.ttf"], 96)
    tag_font = _font(["segoeuisl.ttf", "segoeui.ttf", "arial.ttf"], 40)

    d = ImageDraw.Draw(bg)
    x = int(h * 0.75)
    d.text((x, 150), "NutriGuide", font=title_font, fill=WHITE)
    d.text((x, 270), "Foods & supplements that support", font=tag_font, fill=(220, 237, 220))
    d.text((x, 322), "every organ of your body", font=tag_font, fill=(220, 237, 220))
    return bg.convert("RGB")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    build_full_icon(1024).save(OUT_DIR / "icon.png")
    build_full_icon(512).save(OUT_DIR / "icon-512.png")
    build_adaptive_foreground().save(OUT_DIR / "adaptive-foreground.png")
    build_feature_graphic().save(OUT_DIR / "feature-graphic.png")
    print(f"Wrote 4 assets to {OUT_DIR}")


if __name__ == "__main__":
    main()
