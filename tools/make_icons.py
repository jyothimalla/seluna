#!/usr/bin/env python3
"""Generate 4 candidate 1024x1024 app icons for Period Tracker."""
import math
from PIL import Image, ImageDraw, ImageFont
import os

SIZE = 1024
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'icon')
os.makedirs(OUT, exist_ok=True)


def lerp_color(c1, c2, t):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))


def gradient_bg(draw, size, top, bottom, radius=120):
    """Rounded-rect gradient background."""
    img_tmp = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img_tmp)
    for y in range(size):
        t = y / size
        c = lerp_color(top, bottom, t) + (255,)
        d.line([(0, y), (size, y)], fill=c)
    # Rounded mask
    mask = Image.new('L', (size, size), 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle([0, 0, size, size], radius=radius, fill=255)
    img_tmp.putalpha(mask)
    draw._image.paste(img_tmp, (0, 0), img_tmp)


# ── Option A: Hot-pink gradient + white water-drop ─────────────────────────
def make_option_a():
    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    gradient_bg(draw, SIZE, (233, 30, 140), (255, 64, 129))   # #E91E8C → #FF4081

    # Water drop shape (teardrop)
    cx, cy = SIZE // 2, SIZE // 2 + 30
    r = 200
    # Circle bottom
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 255, 255, 230))
    # Triangle top (pointed up)
    tip_y = cy - r - 200
    draw.polygon([
        (cx, tip_y),
        (cx - r, cy - 20),
        (cx + r, cy - 20),
    ], fill=(255, 255, 255, 230))
    # Shine spot
    draw.ellipse([cx - 60, cy - r + 40, cx, cy - r + 120],
                 fill=(255, 255, 255, 120))
    img.save(os.path.join(OUT, 'option_a.png'))
    print('✓ option_a.png — Hot-pink + water drop')


# ── Option B: Deep rose gradient + white flower ─────────────────────────────
def make_option_b():
    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    gradient_bg(draw, SIZE, (198, 40, 100), (240, 98, 146))   # deep rose

    cx, cy = SIZE // 2, SIZE // 2
    petal_r = 160
    petal_len = 220
    # 6 petals
    for i in range(6):
        angle = math.radians(i * 60)
        px = cx + int(petal_len * 0.45 * math.cos(angle))
        py = cy + int(petal_len * 0.45 * math.sin(angle))
        draw.ellipse([px - petal_r // 2, py - petal_r // 2,
                      px + petal_r // 2, py + petal_r // 2],
                     fill=(255, 255, 255, 210))
    # Centre circle
    draw.ellipse([cx - 110, cy - 110, cx + 110, cy + 110],
                 fill=(255, 255, 255, 240))
    # Inner accent
    draw.ellipse([cx - 60, cy - 60, cx + 60, cy + 60],
                 fill=(233, 30, 140, 200))
    img.save(os.path.join(OUT, 'option_b.png'))
    print('✓ option_b.png — Deep rose + flower')


# ── Option C: Soft blush gradient + heart + dots ───────────────────────────
def make_option_c():
    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    gradient_bg(draw, SIZE, (252, 228, 236), (248, 187, 208))  # soft blush

    cx, cy = SIZE // 2, SIZE // 2 - 20
    # Heart using two circles + rotated square
    hr = 170
    # Left lobe
    draw.ellipse([cx - hr - 30, cy - hr, cx + 30, cy + 30],
                 fill=(233, 30, 140, 230))
    # Right lobe
    draw.ellipse([cx - 30, cy - hr, cx + hr + 30, cy + 30],
                 fill=(233, 30, 140, 230))
    # Bottom triangle
    draw.polygon([
        (cx, cy + 220),
        (cx - hr - 60, cy + 20),
        (cx + hr + 60, cy + 20),
    ], fill=(233, 30, 140, 230))
    # Small dots (calendar feel)
    dot_r = 28
    for col in range(3):
        for row in range(2):
            dx = cx - 100 + col * 100
            dy = cy + 290 + row * 70
            draw.ellipse([dx - dot_r, dy - dot_r, dx + dot_r, dy + dot_r],
                         fill=(233, 30, 140, 180))
    img.save(os.path.join(OUT, 'option_c.png'))
    print('✓ option_c.png — Soft blush + heart')


# ── Option D: Magenta-to-violet gradient + crescent moon + stars ────────────
def make_option_d():
    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    gradient_bg(draw, SIZE, (156, 39, 176), (233, 30, 140))   # purple → pink

    cx, cy = SIZE // 2, SIZE // 2
    r = 240
    # Full moon
    draw.ellipse([cx - r, cy - r, cx + r, cy + r],
                 fill=(255, 255, 255, 240))
    # Bite-out circle to form crescent
    draw.ellipse([cx - 10, cy - r + 30, cx + r + 50, cy + r - 30],
                 fill=(156, 39, 176, 255))
    # Stars
    star_positions = [(cx - 180, cy - 280), (cx + 220, cy - 200),
                      (cx + 280, cy + 60),  (cx - 240, cy + 180)]
    for sx, sy in star_positions:
        sr = 28
        for angle in range(0, 360, 72):
            a = math.radians(angle - 90)
            a2 = math.radians(angle - 90 + 36)
            outer = (sx + sr * math.cos(a), sy + sr * math.sin(a))
            inner = (sx + sr * 0.4 * math.cos(a2), sy + sr * 0.4 * math.sin(a2))
            draw.polygon([
                (sx, sy), outer, (sx + sr * math.cos(a2) * 0.1,
                                  sy + sr * math.sin(a2) * 0.1), inner
            ], fill=(255, 255, 255, 220))
    img.save(os.path.join(OUT, 'option_d.png'))
    print('✓ option_d.png — Purple/pink + crescent moon')


make_option_a()
make_option_b()
make_option_c()
make_option_d()


# ── Option E: Purple-to-pink gradient (D) + large flower (B) ───────────────
def make_option_e():
    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    gradient_bg(draw, SIZE, (156, 39, 176), (233, 30, 140))   # purple → hot-pink

    cx, cy = SIZE // 2, SIZE // 2
    petal_r = 210
    petal_len = 290

    # 6 large petals
    for i in range(6):
        angle = math.radians(i * 60)
        px = cx + int(petal_len * 0.45 * math.cos(angle))
        py = cy + int(petal_len * 0.45 * math.sin(angle))
        draw.ellipse([px - petal_r // 2, py - petal_r // 2,
                      px + petal_r // 2, py + petal_r // 2],
                     fill=(255, 255, 255, 220))

    # Centre circle (white)
    draw.ellipse([cx - 140, cy - 140, cx + 140, cy + 140],
                 fill=(255, 255, 255, 255))

    # Inner pink dot
    draw.ellipse([cx - 80, cy - 80, cx + 80, cy + 80],
                 fill=(233, 30, 140, 230))

    # Tiny shine on inner dot
    draw.ellipse([cx - 50, cy - 65, cx - 10, cy - 30],
                 fill=(255, 255, 255, 140))

    img.save(os.path.join(OUT, 'option_e.png'))
    print('✓ option_e.png — Purple-pink gradient + flower (B+D combined)')


make_option_e()
print('\nAll icons saved to assets/icon/')


# ── Option F: Hibiscus flower on purple-to-pink gradient ───────────────────
def make_option_f():
    import math
    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    gradient_bg(draw, SIZE, (156, 39, 176), (233, 30, 140))   # purple → hot-pink

    cx, cy = SIZE // 2, SIZE // 2

    # Draw 5 hibiscus petals (large, overlapping, slightly transparent)
    petal_colors = [
        (255, 182, 193, 210),  # light pink
        (255, 160, 180, 210),
        (255, 140, 170, 210),
        (255, 182, 193, 210),
        (255, 160, 180, 210),
    ]
    petal_w = 300
    petal_h = 380

    for i in range(5):
        angle = math.radians(i * 72 - 90)
        # Each petal is an ellipse offset from center
        px = cx + int(180 * math.cos(angle))
        py = cy + int(180 * math.sin(angle))
        # Rotate petal along angle (approximate with bounding box)
        # Draw elongated ellipse pointing from center outward
        # Use a separate layer per petal for proper alpha
        petal_img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
        pd = ImageDraw.Draw(petal_img)
        # Petal bounding box centered at (cx, cy-petal_h//2) before rotation
        pb = [cx - petal_w // 2, cy - petal_h, cx + petal_w // 2, cy]
        pd.ellipse(pb, fill=petal_colors[i])
        # Rotate petal
        rot_angle = i * 72
        petal_img = petal_img.rotate(-rot_angle, center=(cx, cy), resample=Image.BICUBIC)
        img.alpha_composite(petal_img)

    draw2 = ImageDraw.Draw(img)

    # Dark pink base of petals (inner circle)
    draw2.ellipse([cx - 90, cy - 90, cx + 90, cy + 90],
                  fill=(180, 0, 80, 240))

    # Yellow stamen tube
    draw2.ellipse([cx - 40, cy - 110, cx + 40, cy + 40],
                  fill=(255, 220, 50, 230))
    draw2.ellipse([cx - 40, cy - 110, cx + 40, cy - 30],
                  fill=(255, 200, 30, 230))

    # Stamen tip dots
    for k in range(6):
        sa = math.radians(k * 60)
        sx = cx + int(55 * math.cos(sa))
        sy = (cy - 100) + int(55 * math.sin(sa))
        draw2.ellipse([sx - 14, sy - 14, sx + 14, sy + 14],
                      fill=(255, 80, 100, 240))

    # Centre gold circle
    draw2.ellipse([cx - 28, cy - 128, cx + 28, cy - 72],
                  fill=(255, 180, 20, 255))

    img.save(os.path.join(OUT, 'option_f.png'))
    print('✓ option_f.png — Hibiscus on purple-pink gradient')


make_option_f()
