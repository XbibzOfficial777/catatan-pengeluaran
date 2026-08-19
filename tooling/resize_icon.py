from pathlib import Path
from PIL import Image

source = Path('/home/ubuntu/task/assets/catatan_pengeluaran_icon.png')
image = Image.open(source).convert('RGB')
outputs = {
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192,
}
root = Path('/home/ubuntu/task/android/app/src/main/res')
for density, size in outputs.items():
    target = root / f'mipmap-{density}' / 'ic_launcher.png'
    target.parent.mkdir(parents=True, exist_ok=True)
    image.resize((size, size), Image.Resampling.LANCZOS).save(target, optimize=True)
