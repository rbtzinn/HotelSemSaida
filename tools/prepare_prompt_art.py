"""Recorta o pacote PROMPTS.md sem alterar fontes nem cenas do jogo.

python tools/prepare_prompt_art.py --analyze  # somente medidas, sem gravar
python tools/prepare_prompt_art.py --build    # processamento local autorizado

Pillow, NumPy e SciPy. Saída: art/processed/. Toda a escala corporal vem de uma
única medida por personagem; quadros de caminhada/uso nunca são ajustados pelo
tamanho individual de sua caixa. layout.json guarda escala, âncoras e hashes.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "art/incoming"
OUT = ROOT / "art/processed"
CELL = (384, 512)
SHEETS = {
    "lia": ["lia_lado_andar", "lia_frente_andar", "lia_costas_andar", "lia_parada"],
    "helena": ["helena_lado_andar", "helena_frente_andar", "helena_costas_andar",
               "helena_parada", "helena_gelo_andar", "helena_fermento_andar", "helena_usar"],
}
OBJECT_NAMES = {
    "1923": ["elevador_cabine", "elevador_vazio", "chaves_cheio", "chaves_vazio",
             "cofre_fechado", "cofre_aberto", "painel_chamada", "porta_servico"],
    "present": ["elevador_bloqueado", "elevador_aberto", "chaves_vazio", "livro_registro",
                "cofre_fechado", "cofre_aberto", "porta_trancada", "porta_aberta"],
}
OBJECT_SIZES = {
    "1923": [(52, 50), (52, 50), (48, 38), (48, 38), (44, 42), (44, 42), (16, 24), (16, 48)],
    "present": [(52, 50), (52, 50), (48, 38), (48, 38), (44, 42), (44, 42), (16, 48), (16, 48)],
}


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def relative(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def write_json(path: Path, data: dict) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def keyed(cell: Image.Image, pixel_art: bool) -> Image.Image:
    """Extrai o chroma; descontamina só a borda, preservando cores internas."""
    a = np.array(cell.convert("RGBA"))
    rgb = a[:, :, :3].astype(np.float32)
    r, g, b = rgb.transpose(2, 0, 1)
    chroma = np.minimum(r, b) - g
    background = (r > 180) & (b > 170) & (g < 100) & (chroma > 110)
    alpha = np.where(background, 0.0, 1.0)
    if not pixel_art:
        edge = ndimage.binary_dilation(background, iterations=2) & ~background
        edge_alpha = np.clip((255.0 - chroma) / 175.0, 0.0, 1.0)
        alpha[edge] = edge_alpha[edge]
        foreground = rgb.copy()
        key = np.array([255.0, 0.0, 255.0])
        foreground[edge] = (rgb[edge] - (1.0 - alpha[edge, None]) * key) / np.maximum(alpha[edge, None], 0.01)
        a[:, :, :3] = np.clip(foreground, 0, 255).astype(np.uint8)
    a[:, :, 3] = np.minimum(a[:, :, 3], np.round(alpha * 255)).astype(np.uint8)
    # Elimina apenas grãos minúsculos; gotas de fermento de 8x8 são preservadas.
    labels, _ = ndimage.label(a[:, :, 3] > 16)
    sizes = np.bincount(labels.ravel())
    tiny = sizes < 6
    tiny[0] = False
    a[:, :, 3][tiny[labels]] = 0
    a[:, :, :3][a[:, :, 3] == 0] = 0
    return Image.fromarray(a)


def read_cells(name: str, pixel_art: bool) -> list[Image.Image]:
    with Image.open(SOURCE / f"{name}.png") as im:
        assert im.size == (1536, 1024), (name, im.size)
        return [keyed(im.crop(((i % 4) * 384, (i // 4) * 512,
                              (i % 4 + 1) * 384, (i // 4 + 1) * 512)), pixel_art)
                for i in range(8)]


def body_mask(im: Image.Image) -> np.ndarray:
    labels, _ = ndimage.label(np.array(im.getchannel("A")) > 128)
    sizes = np.bincount(labels.ravel())
    sizes[0] = 0
    assert sizes.max() > 100, "Célula sem corpo/objeto legível"
    return labels == sizes.argmax()


def measures(im: Image.Image, person: str, direction: str, gesture: bool) -> dict:
    body = body_mask(im)
    ys, xs = np.nonzero(body)
    top, bottom = int(ys.min()), int(ys.max()) + 1
    height = bottom - top
    y0, y1 = top + round(height * 0.28), top + round(height * 0.48)
    band = body[y0:y1].copy()
    if person == "helena" or direction == "side":
        rgb = np.array(im)[y0:y1, :, :3].astype(float)
        r, g, b = rgb.transpose(2, 0, 1)
        clothes = ((r > g * 1.25) & (r > b * 1.2)) if person == "helena" else ((b > r + 5) & (b > g - 8))
        band &= clothes
        coordinates = np.nonzero(band)[1]
        anchor_x = float(np.median(coordinates)) if len(coordinates) else float(np.median(xs))
    else:
        row_centers = []
        for row in band:
            indices = np.flatnonzero(row)
            if len(indices):
                row_centers.append((indices[0] + indices[-1]) / 2)
        anchor_x = float(np.median(row_centers))
    if gesture:
        # Pés fixos durante uso. A janela exclui o gelo pousado à direita.
        foot = body[max(0, bottom - 8):bottom].copy()
        foot[:, :96] = False
        foot[:, 240:] = False
        coordinates = np.nonzero(foot)[1]
        if len(coordinates):
            anchor_x = float(np.median(coordinates))
    return {"top": top, "feet_y": bottom, "anchor_x": anchor_x, "height": height}


def direction_for(sheet: str, index: int) -> str:
    if "frente" in sheet:
        return "front"
    if "costas" in sheet:
        return "back"
    if "parada" in sheet:
        return ["side", "side", "front", "front", "back", "back", "side", "front"][index]
    return "side"


def place(im: Image.Image, scale: float, canvas: tuple[int, int], anchor: tuple[int, int],
          source_anchor: tuple[float, float], nearest: bool) -> tuple[Image.Image, list[int]]:
    box = im.getchannel("A").getbbox()
    assert box
    cropped = im.crop(box)
    size = tuple(max(1, round(n * scale)) for n in cropped.size)
    resized = cropped.resize(size, Image.Resampling.NEAREST if nearest else Image.Resampling.LANCZOS)
    x = round(anchor[0] - (source_anchor[0] - box[0]) * scale)
    y = round(anchor[1] - (source_anchor[1] - box[1]) * scale)
    assert x >= 1 and y >= 1 and x + size[0] < canvas[0] and y + size[1] < canvas[1], (box, size, (x, y), canvas)
    frame = Image.new("RGBA", canvas)
    frame.paste(resized, (x, y))
    return frame, [x, y]


def save_image(im: Image.Image, path: Path, manifest: dict, detail: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path)
    detail.update(file=relative(path), size=list(im.size), sha256=sha(path))
    manifest["outputs"].append(detail)


def contact_sheet(frames: list[Image.Image], label: str, path: Path, zoom: int = 1) -> None:
    w, h = frames[0].size
    cw, ch = w * zoom + 20, h * zoom + 36
    preview = Image.new("RGB", (cw * 4, ch * 2), "#242b34")
    draw = ImageDraw.Draw(preview)
    for i, frame in enumerate(frames):
        x, y = (i % 4) * cw + 10, (i // 4) * ch + 24
        draw.text((x, y - 18), f"{label} / {i+1}", fill="white")
        for yy in range(y, y + h * zoom, 16):
            for xx in range(x, x + w * zoom, 16):
                if ((xx - x) // 16 + (yy - y) // 16) % 2 == 0:
                    draw.rectangle((xx, yy, min(xx + 15, x + w * zoom - 1), min(yy + 15, y + h * zoom - 1)), fill="#333e4b")
        enlarged = frame.resize((w * zoom, h * zoom), Image.Resampling.NEAREST)
        preview.paste(enlarged, (x, y), enlarged)
        draw.line((x, y + h * zoom, x + w * zoom, y + h * zoom), fill="#657384")
    path.parent.mkdir(parents=True, exist_ok=True)
    preview.save(path)


def sprite_frames(path: Path, animations: dict[str, tuple[list[Path], float, bool]]) -> None:
    unique = list(dict.fromkeys(p for frames, _, _ in animations.values() for p in frames))
    ids = {p: f"f{i}" for i, p in enumerate(unique)}
    text = f'[gd_resource type="SpriteFrames" load_steps={len(unique)+1} format=3]\n\n'
    text += "\n".join(f'[ext_resource type="Texture2D" path="res://{relative(p)}" id="{ids[p]}"]' for p in unique)
    text += "\n\n[resource]\nanimations = [\n"
    blocks = []
    for name, (frames, speed, loop) in animations.items():
        textures = ",\n".join(f'{{"duration": 1.0, "texture": ExtResource("{ids[p]}")}}' for p in frames)
        blocks.append(f'{{"frames": [\n{textures}\n], "loop": {str(loop).lower()}, "name": &"{name}", "speed": {speed}}}')
    path.write_text(text + ",\n".join(blocks) + "\n]\n", encoding="utf-8", newline="\n")


def characters(person: str, cells: dict, manifest: dict, build: bool) -> None:
    idle_name = f"{person}_parada"
    standing = [measures(im, person, direction_for(idle_name, i), False)["height"]
                for i, im in enumerate(cells[idle_name][:6])]
    target_height = 288 if person == "lia" else 48
    scale = target_height / float(np.median(standing))
    canvas, anchor = ((256, 320), (128, 304)) if person == "lia" else ((48, 64), (24, 60))
    manifest["characters"][person] = {"scale": scale, "source_standing_height": float(np.median(standing)),
        "body_height": target_height, "canvas": list(canvas), "anchor": list(anchor),
        "game_scale": 48.0 / target_height, "game_body_height": 48}
    print(f"{person}: escala comum={scale:.8f}, corpo={target_height}, ancora={anchor}")
    by_sheet = {}
    for name in SHEETS[person]:
        paths, aligned = [], []
        for i, im in enumerate(cells[name]):
            gesture = ("usar" in name) or ("parada" in name and i >= 6)
            m = measures(im, person, direction_for(name, i), gesture)
            print(f"  {name}:{i:02d} altura={m['height']} x={m['anchor_x']:.1f} pes={m['feet_y']}")
            if not build:
                continue
            frame, shift = place(im, scale, canvas, anchor, (m["anchor_x"], m["feet_y"]), person == "helena")
            path = OUT / "characters" / person / f"{name}_{i:02d}.png"
            save_image(frame, path, manifest, {"kind": "character", "character": person, "source": f"art/incoming/{name}.png",
                "cell": i, "scale": scale, "source_measurements": m, "position": shift,
                "anchor": list(anchor), "bbox": list(frame.getchannel("A").getbbox())})
            aligned.append(frame)
            paths.append(path)
        if build:
            by_sheet[name] = paths
            contact_sheet(aligned, name, OUT / "previews" / f"{name}.png", 4 if person == "helena" else 1)
    if not build:
        return
    animations = {}
    for part, direction in [("lado", "side"), ("frente", "front"), ("costas", "back")]:
        animations[f"walk_{direction}"] = (by_sheet[f"{person}_{part}_andar"], 8.0, True)
    idle = by_sheet[idle_name]
    for direction, start in [("side", 0), ("front", 2), ("back", 4)]:
        animations[f"idle_{direction}"] = (idle[start:start + 2], 2.0, True)
    animations["reach_side"] = ([idle[6]], 1.0, False)
    animations["reach_down"] = ([idle[7]], 1.0, False)
    if person == "helena":
        use = by_sheet["helena_usar"]
        for item, start in [("gelo", 0), ("fermento", 4)]:
            animations[f"{item}_walk"] = (by_sheet[f"helena_{item}_andar"], 8.0, True)
            animations[f"{item}_idle"] = ([use[start]], 1.0, True)
            animations[f"{item}_use"] = (use[start:start + 4], 8.0, False)
    sprite_frames(OUT / "characters" / person / f"{person}_animations.tres", animations)
    manifest["characters"][person]["animations"] = {name: len(frames) for name, (frames, _, _) in animations.items()}


def objects(manifest: dict) -> None:
    for era, filename in [("1923", "objetos_1923"), ("present", "objetos_hoje")]:
        cells = read_cells(filename, era == "1923")
        boxes = [im.getchannel("A").getbbox() for im in cells]
        groups = [(0, 1), (2, 3), (4, 5), (6,), (7,)] if era == "1923" else [(0, 1), (2,), (3,), (4, 5), (6, 7)]
        scales = {}
        # Mesmo fator de escala em cada par de estados; nunca estica a arte.
        for group in groups:
            w = max(boxes[i][2] - boxes[i][0] for i in group)
            h = max(boxes[i][3] - boxes[i][1] for i in group)
            target = OBJECT_SIZES[era][group[0]]
            for i in group:
                scales[i] = min(target[0] / w, target[1] / h)
        previews = []
        for i, im in enumerate(cells):
            box = boxes[i]
            target = OBJECT_SIZES[era][i]
            zoom = 1 if era == "1923" else 4
            size = tuple(n * zoom for n in target)
            cropped = im.crop(box)
            scaled = cropped.resize(tuple(max(1, round(n * scales[i] * zoom)) for n in cropped.size),
                                    Image.Resampling.NEAREST if era == "1923" else Image.Resampling.LANCZOS)
            frame = Image.new("RGBA", size)
            frame.paste(scaled, ((size[0] - scaled.width) // 2, size[1] - scaled.height))
            name = OBJECT_NAMES[era][i]
            save_image(frame, OUT / "objects" / era / f"{name}.png", manifest,
                       {"kind": "object", "era": era, "source": f"art/incoming/{filename}.png", "cell": i,
                        "scale": scales[i] * zoom, "game_size": list(target), "source_bbox": list(box)})
            preview = Image.new("RGBA", (64 * 4, 64 * 4))
            big = frame.resize(tuple(n * (4 if era == "1923" else 1) for n in frame.size), Image.Resampling.NEAREST)
            preview.paste(big, ((preview.width - big.width) // 2, preview.height - big.height))
            previews.append(preview)
        contact_sheet(previews, filename, OUT / "previews" / f"{filename}.png")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build", action="store_true")
    parser.add_argument("--analyze", action="store_true")
    args = parser.parse_args()
    if not args.build and not args.analyze:
        parser.error("Escolha --analyze ou --build")
    manifest = {"version": 1, "sources": {}, "characters": {}, "outputs": [],
                "runtime_integrated": False,
                "notes": ["Uma escala por personagem; apenas translacao por quadro.",
                          "Uma escala uniforme por par de estados dos objetos; sem distorcer proporcoes.",
                          "A integracao precisa usar anchor e game_scale; nao usar a altura do canvas como altura corporal.",
                          "Cenarios sao recortes do enquadramento previsto, ainda sem validacao com colisoes."]}
    for path in sorted(SOURCE.glob("*.png")):
        manifest["sources"][relative(path)] = sha(path)
    if args.build:
        OUT.mkdir(parents=True, exist_ok=True)
        (OUT / "previews").mkdir(exist_ok=True)
        (OUT / "previews/.gdignore").touch()
    for person in SHEETS:
        cells = {name: read_cells(name, person == "helena") for name in SHEETS[person]}
        characters(person, cells, manifest, args.build)
    if args.build:
        objects(manifest)
        for era in ["1923", "present"]:
            path = SOURCE / f"saguao_{era}.png"
            with Image.open(path) as im:
                cropped = im.crop((0, 80, 1536, 944))
                size = (640, 360) if era == "1923" else (1920, 1080)
                frame = cropped.resize(size, Image.Resampling.NEAREST if era == "1923" else Image.Resampling.LANCZOS)
                save_image(frame, OUT / "backgrounds" / path.name, manifest,
                           {"kind": "background", "source": relative(path), "source_crop": [0, 80, 1536, 944], "game_size": [640, 360]})
        for name, digest in manifest["sources"].items():
            assert sha(ROOT / name) == digest, f"Fonte foi alterada: {name}"
        write_json(OUT / "layout.json", manifest)
        print(f"OK: {len(manifest['outputs'])} PNGs, fontes intactas; {relative(OUT / 'layout.json')}")


if __name__ == "__main__":
    main()
