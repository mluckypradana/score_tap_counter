from PIL import Image, ImageDraw, ImageFont
import os

SIZE = 1024
RADIUS = 200

LEFT_COLOR  = (25, 118, 210)      # #1976D2 blue
RIGHT_COLOR = (245, 124, 0)       # #F57C00 orange
WHITE       = (255, 255, 255, 255)

# Rounded rect mask
mask = Image.new('L', (SIZE, SIZE), 0)
mask_draw = ImageDraw.Draw(mask)
mask_draw.rounded_rectangle([0, 0, SIZE - 1, SIZE - 1], radius=RADIUS, fill=255)

# Background: left blue, right orange
img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)
draw.rectangle([0, 0, SIZE // 2, SIZE - 1], fill=LEFT_COLOR)
draw.rectangle([SIZE // 2, 0, SIZE - 1, SIZE - 1], fill=RIGHT_COLOR)

# Apply rounded corners
img.putalpha(mask)
draw = ImageDraw.Draw(img)

# Vertical divider
DIV_X = SIZE // 2
DIV_W = 18
draw.rectangle([DIV_X - DIV_W // 2, 50, DIV_X + DIV_W // 2, SIZE - 50],
               fill=(255, 255, 255, 210))

# Load fonts (macOS system paths)
font_paths_bold = [
    '/System/Library/Fonts/Supplemental/Arial Bold.ttf',
    '/Library/Fonts/Arial Bold.ttf',
    '/System/Library/Fonts/Helvetica.ttc',
]

def load_font(size):
    for fp in font_paths_bold:
        if os.path.exists(fp):
            try:
                return ImageFont.truetype(fp, size)
            except Exception:
                pass
    return ImageFont.load_default()

font_score = load_font(390)
font_label = load_font(68)

def draw_centered_text(draw, text, cx, cy, font, fill):
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    x = cx - tw // 2 - bbox[0]
    y = cy - th // 2 - bbox[1]
    draw.text((x, y), text, font=font, fill=fill)

# Score numbers: "3" left, "2" right
draw_centered_text(draw, '3', SIZE // 4,     SIZE // 2 - 20, font_score, WHITE)
draw_centered_text(draw, '2', 3 * SIZE // 4, SIZE // 2 - 20, font_score, WHITE)

# "ScoreTap" label at bottom
draw_centered_text(draw, 'ScoreTap', SIZE // 2, SIZE - 90,
                   font_label, (255, 255, 255, 170))

# Save 1024×1024 source icon
out_path = os.path.join(os.path.dirname(__file__), 'scoretap_icon.png')
img.save(out_path)
print(f'Icon saved: {out_path}')
