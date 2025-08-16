"""Generate a complete set of AppIcon PNGs for the WoWCA app.

Creates stylised fantasy item icon artwork (original, non-infringing):
 - Arcane gradient background with vignette
 - Subtle dual gold border
 - Central teal/cyan faceted diamond (implied gem)
 - Light sparkles

Writes PNGs into Assets.xcassets/AppIcon.appiconset matching updated Contents.json.

Usage:
  python scripts/generate_app_icon.py

Requires Pillow:
  pip install pillow
"""
from __future__ import annotations
import math
from pathlib import Path
from typing import Tuple
try:
    from PIL import Image, ImageDraw, ImageFilter
except ImportError as e:  # pragma: no cover
    raise SystemExit("Pillow not installed. Run: pip install pillow") from e
ROOT = Path(__file__).resolve().parents[1]
APPICON_PATH = ROOT / "WoWCA" / "Assets.xcassets" / "AppIcon.appiconset"
IOS_SPECS = [
    ("iphone", 20, 2), ("iphone", 20, 3),
    ("iphone", 29, 2), ("iphone", 29, 3),
    ("iphone", 40, 2), ("iphone", 40, 3),
    ("iphone", 60, 2), ("iphone", 60, 3),
    ("ipad", 20, 1), ("ipad", 20, 2),
    ("ipad", 29, 1), ("ipad", 29, 2),
    ("ipad", 40, 1), ("ipad", 40, 2),
    ("ipad", 76, 1), ("ipad", 76, 2),
    ("ipad", 83.5, 2),
]
MAC_SPECS = [
    ("mac", 16, 1), ("mac", 16, 2),
    ("mac", 32, 1), ("mac", 32, 2),
    ("mac", 128, 1), ("mac", 128, 2),
    ("mac", 256, 1), ("mac", 256, 2),
    ("mac", 512, 1), ("mac", 512, 2),
]
MARKETING = ("ios-marketing", 1024, 1)
BG_TOP = (32, 41, 66)
BG_BOTTOM = (12, 16, 28)
FRAME_OUTER = (205, 168, 90)
FRAME_INNER = (246, 229, 170)
GEM_LIGHT = (123, 255, 255)
GEM_DARK = (8, 143, 168)
SPARKLE = (255, 255, 230, 180)

def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t

def lerp_color(c1: Tuple[int, int, int], c2: Tuple[int, int, int], t: float):
    return tuple(int(lerp(a, b, t)) for a, b in zip(c1, c2))

def build_master(size: int = 1024) -> Image.Image:
    img = Image.new("RGBA", (size, size))
    draw = ImageDraw.Draw(img)
    for y in range(size):
        draw.line([(0, y), (size, y)], fill=lerp_color(BG_TOP, BG_BOTTOM, y / (size - 1)))
    vignette = Image.new("L", (size, size), 0)
    vdraw = ImageDraw.Draw(vignette)
    for r in [1.0, 0.85, 0.7, 0.55]:
        radius = int(size * r / 2)
        alpha = int(255 * (1 - r) * 1.2)
        box = [size//2 - radius, size//2 - radius, size//2 + radius, size//2 + radius]
        vdraw.ellipse(box, fill=alpha)
    vignette = vignette.filter(ImageFilter.GaussianBlur(size // 18))
    img = Image.composite(Image.new("RGBA", (size, size), (0,0,0,255)), img, vignette.point(lambda p: 255 - p))
    corner = size * 0.18
    def frame(inset: int, color, width):
        draw.rounded_rectangle([inset, inset, size-inset, size-inset], radius=corner, outline=color, width=width)
    frame(int(size*0.035), FRAME_OUTER, max(2, size//120))
    frame(int(size*0.085), FRAME_INNER, max(2, size//140))
    gem_size = size * 0.42
    cx = cy = size / 2
    half = gem_size / 2
    gem = Image.new("RGBA", (size, size), (0,0,0,0))
    gdraw = ImageDraw.Draw(gem)
    for i in range(int(gem_size)):
        t = i / (gem_size - 1)
        col = lerp_color(GEM_DARK, GEM_LIGHT, t)
        y = cy - half + i
        dy = abs(y - cy)
        w = (1 - dy / half) * half
        gdraw.line([(cx - w, y), (cx + w, y)], fill=col)
    mask = Image.new("L", (size, size), 0)
    mdraw = ImageDraw.Draw(mask)
    mdraw.polygon([(cx, cy - half), (cx + half, cy), (cx, cy + half), (cx - half, cy)], fill=255)
    gem = Image.composite(gem, Image.new("RGBA", (size, size)), mask)
    highlight = Image.new("L", (size, size), 0)
    hdraw = ImageDraw.Draw(highlight)
    hdraw.ellipse([cx - gem_size*0.28, cy - gem_size*0.5, cx + gem_size*0.28, cy + gem_size*0.1], fill=140)
    highlight = highlight.filter(ImageFilter.GaussianBlur(size//60))
    img = Image.alpha_composite(img, gem)
    img = Image.composite(Image.new("RGBA", (size, size), (255,255,255,70)), img, highlight)
    sdraw = ImageDraw.Draw(img)
    for angle_deg, dist_frac, sz in [(15, 0.62, 0.045), (222, 0.58, 0.035), (300, 0.34, 0.028)]:
        ang = math.radians(angle_deg)
        d = dist_frac * half
        sx = cx + math.cos(ang) * d
        sy = cy + math.sin(ang) * d
        r = sz * half
        sdraw.ellipse([sx-r, sy-r, sx+r, sy+r], fill=SPARKLE)
    return img.filter(ImageFilter.GaussianBlur(size/512)).convert("RGBA")

def save_scaled(master: Image.Image, px: int, filename: str):
    out = master.resize((px, px), Image.LANCZOS)
    out.save(APPICON_PATH / filename, "PNG")

def main():
    APPICON_PATH.mkdir(parents=True, exist_ok=True)
    master = build_master(1024)
    generated = []
    for idiom, pts, scale in IOS_SPECS:
        px = int(round(pts * scale))
        name = f"icon-{idiom}-{str(pts).replace('.5','') }@{scale}x.png".replace('.0','')
        save_scaled(master, px, name)
        generated.append(name)
    for idiom, size_px, scale in MAC_SPECS:
        px = size_px * scale
        name = f"icon-mac-{size_px}@{scale}x.png"
        save_scaled(master, px, name)
        generated.append(name)
    _, marketing_px, _ = MARKETING
    marketing_name = "icon-marketing-1024.png"
    save_scaled(master, marketing_px, marketing_name)
    generated.append(marketing_name)
    print(f"Generated {len(generated)} icons:")
    for g in generated:
        print(" -", g)
if __name__ == "__main__":
    main()
