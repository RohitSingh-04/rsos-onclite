#!/usr/bin/env python3
"""
RSOS Boot Animation Generator for Redmi Y3 (onclite)
Resolution: 720 x 1520 @ 30 FPS
Theme: Cyber/Neon Minimalist Vibe with Audio Waveform and Neon Glow
Output: bootanimation.zip (Uncompressed ZIP_STORED) with desc.txt
"""

import os
import math
import shutil
import zipfile
from PIL import Image, ImageDraw, ImageFont, ImageFilter

WIDTH = 720
HEIGHT = 1520
FPS = 30
OUT_DIR = os.path.abspath("device_overlay/bootanimation")
PART0_DIR = os.path.join(OUT_DIR, "part0")
PART1_DIR = os.path.join(OUT_DIR, "part1")
ZIP_PATH = os.path.join(OUT_DIR, "bootanimation.zip")

# Load fonts
FONT_PATH_BOLD = "C:/Windows/Fonts/bahnschrift.ttf"
if not os.path.exists(FONT_PATH_BOLD):
    FONT_PATH_BOLD = "C:/Windows/Fonts/segoeuib.ttf"

FONT_RSOS = ImageFont.truetype(FONT_PATH_BOLD, 108)
FONT_SUB = ImageFont.truetype(FONT_PATH_BOLD, 22)
FONT_SUB_SMALL = ImageFont.truetype(FONT_PATH_BOLD, 14)

def lerp_color(c1, c2, t):
    t = max(0.0, min(1.0, t))
    return tuple(int(a + (b - a) * t) for a, b in zip(c1, c2))

def create_glow(image, radius=8):
    return image.filter(ImageFilter.GaussianBlur(radius))

def draw_vibe_wave(draw, center_y, progress, amplitude, width, phase=0.0):
    """Draws multi-harmonic aesthetic waveform with neon gradient."""
    points_top = []
    points_bot = []
    step = 4
    
    # Harmonics
    for x in range(0, width, step):
        # Envelope window (Hanning window so wave tapers smoothly at screen edges)
        env = math.sin(math.pi * x / width) ** 2
        
        # Superposition of 3 harmonious sine frequencies
        w1 = math.sin(2 * math.pi * (x / 240) + phase)
        w2 = 0.5 * math.sin(2 * math.pi * (x / 130) - 2 * phase)
        w3 = 0.25 * math.cos(2 * math.pi * (x / 75) + 3 * phase)
        
        offset = (w1 + w2 + w3) * amplitude * env * progress
        points_top.append((x, center_y + offset))
        points_bot.append((x, center_y - offset * 0.7))

    # Draw glow ribbons
    for i in range(len(points_top) - 1):
        t = i / len(points_top)
        # Gradient from Cyan (0, 240, 255) -> Violet (168, 85, 247) -> Magenta (236, 72, 153) -> Cyan
        if t < 0.5:
            color = lerp_color((0, 240, 255), (168, 85, 247), t * 2)
        else:
            color = lerp_color((168, 85, 247), (236, 72, 153), (t - 0.5) * 2)
            
        draw.line([points_top[i], points_top[i+1]], fill=color, width=3)
        # Secondary counter-wave
        draw.line([points_bot[i], points_bot[i+1]], fill=(*color[:2], int(color[2] * 0.6)), width=1)

def render_frame(frame_num, total_frames, is_loop=False):
    img = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 255))
    
    # Center coordinates
    cx = WIDTH // 2
    cy_logo = 680
    cy_sub = 790
    cy_wave = 890
    
    # Progress factor
    if not is_loop:
        # Part 0 intro: 0 -> 1 with smooth cubic ease
        raw_p = frame_num / (total_frames - 1)
        p = raw_p * raw_p * (3 - 2 * raw_p) # smoothstep
        phase = raw_p * 4 * math.pi
        pulse = 1.0
        text_alpha = min(1.0, raw_p * 1.5)
        sub_alpha = max(0.0, min(1.0, (raw_p - 0.35) * 2.0))
        wave_amp = 38 * min(1.0, raw_p * 1.3)
    else:
        # Part 1 loop: continuous seamless loop
        p = 1.0
        raw_p = frame_num / total_frames
        phase = raw_p * 2 * math.pi
        # Breathing pulse
        pulse = 0.92 + 0.08 * math.sin(phase)
        text_alpha = 1.0
        sub_alpha = 1.0
        wave_amp = 36 + 6 * math.sin(phase * 2)

    # 1. Background Vibe Aura (Soft deep radial glow)
    aura_layer = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    aura_draw = ImageDraw.Draw(aura_layer)
    if text_alpha > 0.05:
        aura_radius = int(220 * pulse)
        aura_color = (15, 25, 45, int(120 * text_alpha * pulse))
        aura_draw.ellipse([cx - aura_radius, cy_logo - aura_radius, cx + aura_radius, cy_logo + aura_radius], fill=aura_color)
        aura_layer = aura_layer.filter(ImageFilter.GaussianBlur(50))
        img = Image.alpha_composite(img, aura_layer)

    # 2. Render Vibe Waveform
    wave_layer = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    wave_draw = ImageDraw.Draw(wave_layer)
    draw_vibe_wave(wave_draw, cy_wave, p, wave_amp, WIDTH, phase)
    
    # Wave glow
    wave_glow = wave_layer.filter(ImageFilter.GaussianBlur(12))
    img = Image.alpha_composite(img, wave_glow)
    img = Image.alpha_composite(img, wave_layer)

    # 3. RSOS Logo Layer with Multi-layered Glow
    text = "RSOS"
    bbox = FONT_RSOS.getbbox(text)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    tx = cx - tw // 2
    ty = cy_logo - th // 2

    if text_alpha > 0.02:
        logo_glow_layer = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
        logo_glow_draw = ImageDraw.Draw(logo_glow_layer)
        
        # Glow color (Cyan/Violet neon)
        glow_alpha = int(180 * text_alpha * pulse)
        glow_color = (0, 220, 255, glow_alpha)
        logo_glow_draw.text((tx, ty), text, font=FONT_RSOS, fill=glow_color)
        
        # Multi-stage bloom
        glow1 = logo_glow_layer.filter(ImageFilter.GaussianBlur(18))
        glow2 = logo_glow_layer.filter(ImageFilter.GaussianBlur(6))
        img = Image.alpha_composite(img, glow1)
        img = Image.alpha_composite(img, glow2)

        # Core crisp text
        core_layer = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
        core_draw = ImageDraw.Draw(core_layer)
        core_alpha = int(255 * text_alpha)
        core_draw.text((tx, ty), text, font=FONT_RSOS, fill=(245, 250, 255, core_alpha))
        img = Image.alpha_composite(img, core_layer)

    # 4. Tagline: "AN OPERATING SYSTEM WITH VIBE"
    if sub_alpha > 0.02:
        sub_text = "AN OPERATING SYSTEM WITH VIBE"
        # Spaced letter tracking for aesthetic feel
        spaced_text = "  ".join(sub_text.split())
        s_bbox = FONT_SUB.getbbox(spaced_text)
        stw = s_bbox[2] - s_bbox[0]
        sth = s_bbox[3] - s_bbox[1]
        stx = cx - stw // 2
        sty = cy_sub - sth // 2

        sub_layer = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
        sub_draw = ImageDraw.Draw(sub_layer)
        
        s_alpha = int(230 * sub_alpha)
        sub_draw.text((stx, sty), spaced_text, font=FONT_SUB, fill=(160, 230, 255, s_alpha))
        
        sub_glow = sub_layer.filter(ImageFilter.GaussianBlur(4))
        img = Image.alpha_composite(img, sub_glow)
        img = Image.alpha_composite(img, sub_layer)

    # 5. Accent Dot / Particle Orbit
    accent_layer = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    accent_draw = ImageDraw.Draw(accent_layer)
    dot_r = 3
    # Two satellite aesthetic points
    orbit_x1 = cx + int(190 * math.cos(phase * 0.7))
    orbit_y1 = cy_logo + int(25 * math.sin(phase * 0.7))
    orbit_x2 = cx - int(190 * math.cos(phase * 0.7))
    orbit_y2 = cy_logo - int(25 * math.sin(phase * 0.7))
    
    dot_alpha = int(180 * text_alpha)
    accent_draw.ellipse([orbit_x1-dot_r, orbit_y1-dot_r, orbit_x1+dot_r, orbit_y1+dot_r], fill=(0, 240, 255, dot_alpha))
    accent_draw.ellipse([orbit_x2-dot_r, orbit_y2-dot_r, orbit_x2+dot_r, orbit_y2+dot_r], fill=(236, 72, 153, dot_alpha))
    accent_glow = accent_layer.filter(ImageFilter.GaussianBlur(4))
    img = Image.alpha_composite(img, accent_glow)
    img = Image.alpha_composite(img, accent_layer)

    return img.convert("RGB")

def build_animation():
    os.makedirs(PART0_DIR, exist_ok=True)
    os.makedirs(PART1_DIR, exist_ok=True)
    
    print("[+] Rendering Part 0 (Intro: 45 frames)...")
    total_p0 = 45
    for i in range(total_p0):
        frame = render_frame(i, total_p0, is_loop=False)
        frame.save(os.path.join(PART0_DIR, f"{i:05d}.png"), "PNG", optimize=True)
        if i % 15 == 0 or i == total_p0 - 1:
            print(f"    Part 0: {i+1}/{total_p0}")

    print("[+] Rendering Part 1 (Loop: 30 frames)...")
    total_p1 = 30
    for i in range(total_p1):
        frame = render_frame(i, total_p1, is_loop=True)
        frame.save(os.path.join(PART1_DIR, f"{i:05d}.png"), "PNG", optimize=True)
        if i % 10 == 0 or i == total_p1 - 1:
            print(f"    Part 1: {i+1}/{total_p1}")

    # Write desc.txt (CRITICAL: trailing newline required by Android)
    desc_content = f"{WIDTH} {HEIGHT} {FPS}\np 1 0 part0\np 0 0 part1\n"
    desc_path = os.path.join(OUT_DIR, "desc.txt")
    with open(desc_path, "w", newline="\n") as f:
        f.write(desc_content)
    print("[+] desc.txt created successfully.")

    # Create bootanimation.zip with ZIP_STORED (Zero compression)
    print(f"[+] Creating uncompressed bootanimation.zip at: {ZIP_PATH} ...")
    if os.path.exists(ZIP_PATH):
        os.remove(ZIP_PATH)

    with zipfile.ZipFile(ZIP_PATH, "w", compression=zipfile.ZIP_STORED) as zf:
        zf.write(desc_path, "desc.txt")
        for root, _, files in os.walk(PART0_DIR):
            for file in sorted(files):
                full_path = os.path.join(root, file)
                rel_path = os.path.join("part0", file).replace("\\", "/")
                zf.write(full_path, rel_path)
        for root, _, files in os.walk(PART1_DIR):
            for file in sorted(files):
                full_path = os.path.join(root, file)
                rel_path = os.path.join("part1", file).replace("\\", "/")
                zf.write(full_path, rel_path)

    zip_size_mb = os.path.getsize(ZIP_PATH) / (1024 * 1024)
    print(f"[SUCCESS] bootanimation.zip generated! File size: {zip_size_mb:.2f} MB")

if __name__ == "__main__":
    build_animation()
