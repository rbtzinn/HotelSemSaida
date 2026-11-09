"""Gera o ícone do jogo a partir da imagem feita no ChatGPT (art/incoming/icone/icone_chatgpt.webp).

O original é RGB com cantos pretos: aqui os cantos viram transparentes (quadrado arredondado medido na
imagem: borda 3 px, raio 330 px em 1254 px). Saem art/icon/icone.png (512, janela e Godot) e
art/icon/icone.ico (16 a 256, o .exe). Rodar: python tools/make_icon.py
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "art/incoming/icone/icone_chatgpt.webp"
OUT = ROOT / "art/icon"
EDGE = 3
RADIUS = 330
SUPER = 4  # máscara desenhada em 4x para a borda sair suave

image = Image.open(SOURCE).convert("RGB")
size = image.width
mask = Image.new("L", (size * SUPER, size * SUPER), 0)
ImageDraw.Draw(mask).rounded_rectangle(
    (EDGE * SUPER, EDGE * SUPER, (size - EDGE) * SUPER - 1, (size - EDGE) * SUPER - 1), RADIUS * SUPER, fill=255)
icon = image.convert("RGBA")
icon.putalpha(mask.resize((size, size), Image.LANCZOS))
OUT.mkdir(parents=True, exist_ok=True)
icon.resize((512, 512), Image.LANCZOS).save(OUT / "icone.png")
sizes = [256, 128, 64, 48, 32, 24, 16]
frames = []
for side in sizes:
    frame = icon.resize((side, side), Image.LANCZOS)
    if side <= 48:
        frame = frame.filter(ImageFilter.UnsharpMask(radius=1, percent=60, threshold=2))
    frames.append(frame)
frames[0].save(OUT / "icone.ico", sizes=[(s, s) for s in sizes], append_images=frames[1:])
print("icone.png e icone.ico em", OUT)
