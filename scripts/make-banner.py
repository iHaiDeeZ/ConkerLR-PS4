#!/usr/bin/env python3
"""The README's banner (docs/images/banner.png, 1600x480): a glowing acorn and the title, in Crema's layout.

    python scripts/make-banner.py
"""
import os

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
W, H = 1600, 480
TEXT = (0xF6, 0xEE, 0xE6)
MUTED = (0xC9, 0xA8, 0x8C)


def font(names, size):
    for name in names:
        for d in ("C:/Windows/Fonts", "/usr/share/fonts/truetype/dejavu"):
            path = os.path.join(d, name)
            if os.path.exists(path):
                return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def background():
    """Dark brown, lit warmly behind the acorn"""
    img = Image.new("RGBA", (W, H), (0x0E, 0x09, 0x0C, 255))
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse((150, -80, 750, 560), fill=(0x4A, 0x26, 0x1A, 255))
    return Image.alpha_composite(img, glow.filter(ImageFilter.GaussianBlur(160)))


def acorn():
    """The acorn, drawn 2x and shrunk for smooth edges, with a soft glow"""
    K = 2
    layer = Image.new("RGBA", (W * K, H * K), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    cx = 450 * K
    # the nut
    d.ellipse((cx - 118 * K, 150 * K, cx + 118 * K, 400 * K), fill=(0xFF, 0xD9, 0xB0, 255))
    d.polygon([(cx - 45 * K, 375 * K), (cx + 45 * K, 375 * K), (cx, 412 * K)], fill=(0xFF, 0xD9, 0xB0, 255))
    d.ellipse((cx - 70 * K, 205 * K, cx - 40 * K, 330 * K), fill=(0xFF, 0xEE, 0xD8, 255))  # highlight
    # the cap
    d.ellipse((cx - 150 * K, 105 * K, cx + 150 * K, 255 * K), fill=(0xFF, 0x8A, 0x3D, 255))
    d.rounded_rectangle((cx - 150 * K, 180 * K, cx + 150 * K, 218 * K), radius=19 * K, fill=(0xFF, 0x8A, 0x3D, 255))
    for i in range(-2, 3):  # the cap's scales
        x = cx + i * 52 * K
        d.arc((x - 30 * K, 140 * K, x + 30 * K, 200 * K), 200, 340, fill=(0xFF, 0xB0, 0x6A, 255), width=6 * K)
    # the stem
    d.line([(cx, 112 * K), (cx + 14 * K, 72 * K), (cx + 40 * K, 52 * K)], fill=(0xFF, 0x8A, 0x3D, 255), width=16 * K, joint="curve")
    layer = layer.resize((W, H), Image.LANCZOS)
    glow = layer.filter(ImageFilter.GaussianBlur(28))
    tint = Image.new("RGBA", (W, H), (0xFF, 0x7A, 0x2E, 0))
    tint.putalpha(glow.getchannel("A").point(lambda a: a * 0.85))
    out = Image.alpha_composite(Image.new("RGBA", (W, H), (0, 0, 0, 0)), tint)
    out = Image.alpha_composite(out, layer)
    # the ground line under it, as in Crema's
    d = ImageDraw.Draw(out)
    d.rounded_rectangle((320, 446, 580, 456), radius=6, fill=(0xC9, 0x6A, 0x3A, 200))
    return out


def gradient_text(img, xy_right, y, text, f, left, right):
    """Right-aligned text filled with a left-to-right gradient, like Crema's title"""
    d = ImageDraw.Draw(img)
    bbox = d.textbbox((0, 0), text, font=f)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    x = xy_right - tw
    mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mask).text((x - bbox[0], y - bbox[1]), text, font=f, fill=255)
    grad = Image.new("RGBA", (W, H))
    gd = ImageDraw.Draw(grad)
    for i in range(tw + 1):
        t = i / max(tw, 1)
        c = tuple(round(left[k] + (right[k] - left[k]) * t) for k in range(3)) + (255,)
        gd.line([(x + i, 0), (x + i, H)], fill=c)
    grad.putalpha(ImageChops.multiply(mask, Image.new("L", (W, H), 255)))
    img.alpha_composite(grad)


def right_text(img, x_right, y, text, f, fill):
    d = ImageDraw.Draw(img)
    d.text((x_right - d.textlength(text, font=f), y), text, font=f, fill=fill)


def main():
    img = background()
    img.alpha_composite(acorn())
    bold = font(("segoeuib.ttf", "DejaVuSans-Bold.ttf"), 170)
    light = font(("segoeuil.ttf", "segoeui.ttf", "DejaVuSans.ttf"), 46)
    small = font(("segoeuil.ttf", "segoeui.ttf", "DejaVuSans.ttf"), 36)
    gradient_text(img, 1520, 112, "Conker", bold, (0xFF, 0xC4, 0x6B), (0xFF, 0x6A, 0x3D))
    right_text(img, 1520, 318, "LIVE & RELOADED", light, TEXT)
    right_text(img, 1520, 380, "XBOX RECOMP  ·  PS4", small, MUTED)
    out = os.path.join(ROOT, "docs", "images")
    os.makedirs(out, exist_ok=True)
    img.convert("RGB").save(os.path.join(out, "banner.png"))
    print("wrote docs/images/banner.png")


if __name__ == "__main__":
    main()
