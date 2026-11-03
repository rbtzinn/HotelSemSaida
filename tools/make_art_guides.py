"""Gera as imagens-guia anexadas aos prompts do ChatGPT (art/prompts/PROMPTS.md).

- Saguão: pega as capturas do jogo (tools/capture_lobby_guides.gd), põe numa tela
  1536x1024 (o jogo ocupa a faixa y 80..944) e cobre de cinza as vagas dos objetos
  que mudam em jogo, que não podem ser pintadas no cenário.
- Personagens: grades 4x2 de células 384x512 com linha do topo da cabeça, linha dos
  pés e eixo central, e as referências de Helena e dos objetos ampliadas 8x.

Rodar da raiz do projeto: python tools/make_art_guides.py
"""

from pathlib import Path

from PIL import Image, ImageDraw

ENV = Path("art/environment/source")
OUT = Path("art/prompts/guides")
CANVAS = (1536, 1024)
GAME_TOP = 80
SCALE = 2.4  # 640x360 -> 1536x864

# Vagas reservadas (coordenadas do jogo): objetos animados por cima da pintura.
RESERVED = {
    "elevador": (494, 14, 546, 64),
    "quadro_chaves": (228, 18, 276, 56),
    "cofre": (368, 20, 412, 62),
    "porta_cozinha": (0, 208, 16, 256),
}
RESERVED_COLOR = (128, 128, 128)

CELL = (384, 512)
GRID = (4, 2)
BASELINE = 480
CENTER_X = 192


def to_image(x: float, y: float) -> tuple[int, int]:
    return round(x * SCALE), round(GAME_TOP + y * SCALE)


def lobby_guide(era: str, top_color: tuple, bottom_color: tuple) -> None:
    game = Image.open(ENV / f"lobby_game_{era}.png").convert("RGB")
    canvas = Image.new("RGB", CANVAS, top_color)
    ImageDraw.Draw(canvas).rectangle((0, GAME_TOP + game.height, CANVAS[0], CANVAS[1]), fill=bottom_color)
    canvas.paste(game, (0, GAME_TOP))
    draw = ImageDraw.Draw(canvas)
    for x0, y0, x1, y1 in RESERVED.values():
        draw.rectangle((*to_image(x0, y0), *to_image(x1, y1)), fill=RESERVED_COLOR)
    canvas.save(OUT / f"saguao_layout_{era}.png")


def grid(name: str, head_top: int) -> None:
    image = Image.new("RGB", CANVAS, (255, 255, 255))
    draw = ImageDraw.Draw(image)
    for row in range(GRID[1]):
        for col in range(GRID[0]):
            x, y = col * CELL[0], row * CELL[1]
            draw.rectangle((x, y, x + CELL[0] - 1, y + CELL[1] - 1), outline=(200, 200, 200), width=2)
            draw.line((x + 8, y + head_top, x + CELL[0] - 8, y + head_top), fill=(120, 170, 230), width=2)
            draw.line((x + 8, y + BASELINE, x + CELL[0] - 8, y + BASELINE), fill=(230, 110, 110), width=3)
            for dash in range(y + 16, y + CELL[1] - 16, 24):
                draw.line((x + CENTER_X, dash, x + CENTER_X, dash + 12), fill=(170, 200, 240), width=1)
    image.save(OUT / name)


def enlarge(source: str, crop: tuple | None, name: str) -> None:
    image = Image.open(source).convert("RGBA")
    if crop:
        image = image.crop(crop)
    image.resize((image.width * 8, image.height * 8), Image.NEAREST).save(OUT / name)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    lobby_guide("1923", (59, 26, 31), (201, 151, 59))
    lobby_guide("present", (28, 38, 48), (58, 74, 88))
    # Lia: 48 px de jogo = 432 px na célula (9x). Helena: 8 px por pixel do jogo (384 px).
    grid("grade_lia.png", BASELINE - 432)
    grid("grade_helena.png", BASELINE - 384)
    enlarge("art/sprites/helena.png", (0, 0, 24, 48), "ref_helena_8x.png")
    enlarge("art/sprites/gelo.png", None, "ref_gelo_8x.png")
    enlarge("art/sprites/fermento.png", None, "ref_fermento_8x.png")
    Image.open("art/future/raw/lia_00.png").save(OUT / "ref_lia.png")
    for path in sorted(OUT.iterdir()):
        print(path, Image.open(path).size)


if __name__ == "__main__":
    main()
