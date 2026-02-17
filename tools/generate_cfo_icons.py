from PIL import Image, ImageDraw, ImageFont
import os

# Paths
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
mobile_root = os.path.join(project_root, 'mobile')
android_res = os.path.join(mobile_root, 'android', 'app', 'src', 'main', 'res')
assets_images = os.path.join(project_root, 'assets', 'images')

# Ensure assets dir
os.makedirs(assets_images, exist_ok=True)

# Icon sizes for Android mipmap
sizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

foreground_name = 'ic_launcher_foreground.png'
asset_name = 'cfo_icon.png'

# Text settings
text = 'CFO'
text_color = (5, 35, 75)  # dark navy
bg_color = (255, 255, 255)  # white

# Try to load a TTF font; fallback to default
def get_font(size):
    try:
        # Common fonts - try Arial then DejaVu
        for path in [
            'C:/Windows/Fonts/arialbd.ttf',
            'C:/Windows/Fonts/arial.ttf',
            '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
        ]:
            if os.path.exists(path):
                return ImageFont.truetype(path, size)
    except Exception:
        pass
    return ImageFont.load_default()

# Create icons
for folder, px in sizes.items():
    target_dir = os.path.join(android_res, folder)
    os.makedirs(target_dir, exist_ok=True)
    img = Image.new('RGBA', (px, px), bg_color)
    draw = ImageDraw.Draw(img)

    # determine max font size to fit text
    fontsize = px
    font = get_font(fontsize)
    try:
        bbox = draw.textbbox((0, 0), text, font=font)
        w = bbox[2] - bbox[0]
        h = bbox[3] - bbox[1]
    except Exception:
        w, h = font.getsize(text)
    # reduce fontsize until it fits with padding
    while (w > px * 0.8 or h > px * 0.8) and fontsize > 8:
        fontsize -= 2
        font = get_font(fontsize)
        try:
            bbox = draw.textbbox((0, 0), text, font=font)
            w = bbox[2] - bbox[0]
            h = bbox[3] - bbox[1]
        except Exception:
            w, h = font.getsize(text)

    # center
    x = (px - w) // 2
    y = (px - h) // 2
    draw.text((x, y), text, font=font, fill=text_color)

    out_path = os.path.join(target_dir, foreground_name)
    img.save(out_path)
    print('Wrote', out_path)

# Also save a large asset (1024x1024)
large_px = 1024
img = Image.new('RGBA', (large_px, large_px), bg_color)
draw = ImageDraw.Draw(img)
fontsize = large_px // 2
font = get_font(fontsize)
try:
    bbox = draw.textbbox((0, 0), text, font=font)
    w = bbox[2] - bbox[0]
    h = bbox[3] - bbox[1]
except Exception:
    w, h = font.getsize(text)
while (w > large_px * 0.85 or h > large_px * 0.85) and fontsize > 8:
    fontsize -= 8
    font = get_font(fontsize)
    try:
        bbox = draw.textbbox((0, 0), text, font=font)
        w = bbox[2] - bbox[0]
        h = bbox[3] - bbox[1]
    except Exception:
        w, h = font.getsize(text)

x = (large_px - w) // 2
y = (large_px - h) // 2
draw.text((x, y), text, font=font, fill=text_color)

asset_out = os.path.join(assets_images, asset_name)
img.save(asset_out)
print('Wrote', asset_out)
