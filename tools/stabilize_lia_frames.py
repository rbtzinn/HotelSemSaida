"""Alinha os quadros desenhados da Lia (art/future/lia_XX.png) pelo centro do tronco.

Os quadros gerados por IA têm o corpo deslocado alguns pixels de um quadro para
outro; em jogo isso vira uma tremedeira. O script guarda os originais em
art/future/raw/ (só na primeira vez) e regrava cada quadro deslocado na
horizontal para o tronco ficar sempre na mesma coluna. Altura, escala e pés não
mudam.

Rodar da raiz do projeto: python tools/stabilize_lia_frames.py
"""

from pathlib import Path
import shutil

import numpy as np
from PIL import Image

FRAMES = Path("art/future")
RAW = FRAMES / "raw"
COUNT = 20
# Faixa do tronco (linhas do quadro de 288 px): abaixo da cabeça, acima do quadril.
TORSO_ROWS = slice(70, 140)


def torso_center(alpha: np.ndarray) -> float:
    rows = alpha[TORSO_ROWS] > 128
    xs = np.nonzero(rows)[1]
    return float(xs.mean())


def main() -> None:
    RAW.mkdir(exist_ok=True)
    images = []
    for i in range(COUNT):
        name = f"lia_{i:02d}.png"
        raw = RAW / name
        if not raw.exists():
            shutil.copy2(FRAMES / name, raw)
        images.append(np.array(Image.open(raw).convert("RGBA")))

    centers = [torso_center(image[:, :, 3]) for image in images]
    target = round(float(np.median(centers)))
    for i, (image, center) in enumerate(zip(images, centers)):
        shift = target - round(center)
        moved = np.zeros_like(image)
        if shift >= 0:
            moved[:, shift:] = image[:, : image.shape[1] - shift]
        else:
            moved[:, :shift] = image[:, -shift:]
        Image.fromarray(moved).save(FRAMES / f"lia_{i:02d}.png")
        print(f"lia_{i:02d}: tronco {center:.1f} -> {target} (desloca {shift:+d})")


if __name__ == "__main__":
    main()
