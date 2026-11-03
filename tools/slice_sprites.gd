extends SceneTree
## Recorta as folhas de art/source/ em sprites individuais em art/sprites/.
## As folhas têm fundo magenta #FF00FF e escala 4x (cada pixel do jogo = 4x4).
##
## Uso (na pasta do projeto):
##   Godot_console.exe --headless --path . -s res://tools/slice_sprites.gd
##   Godot_console.exe --headless --path . -s res://tools/slice_sprites.gd -- --list
## Com --list, só mostra as caixas encontradas em cada folha, sem salvar.

const SCALE: int = 4
const SOURCE_DIR: String = "res://art/source/"
const OUTPUT_DIR: String = "res://art/sprites/"
## Peças separadas por até esta distância (pixels do jogo) contam como um sprite só.
const MERGE_GAP: int = 4

## Nomes dos sprites de cada folha, na ordem em que são encontrados
## (de cima para baixo, da esquerda para a direita, por linha). Nome "" = descartar.
const NAMES: Dictionary = {
	"objetos_1923": ["escada_1923", "porta_despensa_1923", "cabine_1923", "geladeira_1923",
		"painel_alavanca_1923", "painel_freio_1923", "cadeado_1923", "fermento", "gelo",
		"cardapio_1923", "forno_1923", "massa_pao", "prateleira_despensa_1923"],
	"objetos_hoje": ["escombros_porta", "escada_desabada", "forno_desmoronado", "forno_petrificado",
		"cabine_enferrujada", "cabine_no_alto", "cabos", "portinhola", "prateleira_quebrada",
		"geladeira_hoje", "papel_desbotado", "fresta", "prateleira_torta", "buraco"],
	# As paredes desta folha foram trocadas pelas da folha "paredes", mais calmas
	"texturas": ["", "piso_1923", "rodape_1923", "", "piso_hoje", "rodape_hoje"],
	"paredes": ["parede_1923", "parede_hoje"],
}
## Folha de personagens: 5 quadros por personagem (parado + 4 de caminhada),
## salvos como uma tira de 120x48 por personagem.
const CHARACTER_SHEET: String = "personagens"
const CHARACTER_NAMES: Array[String] = ["helena", "lia"]
const FRAME_SIZE: Vector2i = Vector2i(24, 48)
const FRAMES_PER_CHARACTER: int = 5


func _initialize() -> void:
	var list_only := "--list" in OS.get_cmdline_user_args()
	for file in DirAccess.get_files_at(SOURCE_DIR):
		if not file.ends_with(".png"):
			continue
		var sheet := _downscale(Image.load_from_file(SOURCE_DIR + file))
		var boxes := _find_boxes(sheet)
		print("%s: %d sprites" % [file, boxes.size()])
		if file.get_basename() == CHARACTER_SHEET:
			_save_character_strips(sheet, boxes, list_only)
			continue
		var names: Array = NAMES.get(file.get_basename(), [])
		for i in boxes.size():
			var box: Rect2i = boxes[i]
			var sprite_name: String = names[i] if i < names.size() else "%s_%02d" % [file.get_basename(), i]
			print("  %2d  %-28s pos=%s tamanho=%s" % [i, sprite_name, box.position, box.size])
			if not list_only and sprite_name != "":
				DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
				sheet.get_region(box).save_png(OUTPUT_DIR + sprite_name + ".png")
	quit()


## Cada quadro é recortado em 24x48 centrado na cabeça (as pernas da caminhada
## mudam a largura da caixa, a cabeça não), para a personagem não "tremer" na animação.
func _save_character_strips(sheet: Image, boxes: Array[Rect2i], list_only: bool) -> void:
	for c in CHARACTER_NAMES.size():
		var strip := Image.create_empty(FRAME_SIZE.x * FRAMES_PER_CHARACTER, FRAME_SIZE.y, false, Image.FORMAT_RGBA8)
		for f in FRAMES_PER_CHARACTER:
			var box: Rect2i = boxes[c * FRAMES_PER_CHARACTER + f]
			# Centrado na cabeça, mas sem cortar nada do desenho (ex.: a lanterna da Lia)
			var left := clampi(_head_center_x(sheet, box) - FRAME_SIZE.x / 2, box.end.x - FRAME_SIZE.x, box.position.x)
			var frame_rect := Rect2i(left, box.end.y - FRAME_SIZE.y, FRAME_SIZE.x, FRAME_SIZE.y)
			print("  %s quadro %d: caixa=%s recorte=%s" % [CHARACTER_NAMES[c], f, box, frame_rect])
			strip.blit_rect(sheet, frame_rect, Vector2i(f * FRAME_SIZE.x, 0))
		if not list_only:
			DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
			strip.save_png(OUTPUT_DIR + CHARACTER_NAMES[c] + ".png")


func _head_center_x(img: Image, box: Rect2i) -> int:
	var total := 0
	var count := 0
	for y in range(box.position.y, box.position.y + 10):
		for x in range(box.position.x, box.end.x):
			if img.get_pixel(x, y).a > 0.0:
				total += x
				count += 1
	return roundi(float(total) / count) if count > 0 else box.get_center().x


## Reduz a folha para 1 pixel por pixel do jogo e troca o magenta por transparente.
func _downscale(source: Image) -> Image:
	source.convert(Image.FORMAT_RGBA8)
	var w := source.get_width() / SCALE
	var h := source.get_height() / SCALE
	var out := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var c := source.get_pixel(x * SCALE + SCALE / 2, y * SCALE + SCALE / 2)
			if _is_background(c):
				c = Color(0, 0, 0, 0)
			out.set_pixel(x, y, c)
	return out


func _is_background(c: Color) -> bool:
	return c.r > 0.85 and c.b > 0.85 and c.g < 0.2


## Caixas dos grupos de pixels visíveis, juntando peças próximas,
## ordenadas por linha (de cima para baixo) e depois da esquerda para a direita.
func _find_boxes(img: Image) -> Array[Rect2i]:
	var w := img.get_width()
	var h := img.get_height()
	var seen := PackedByteArray()
	seen.resize(w * h)
	var boxes: Array[Rect2i] = []
	for y in h:
		for x in w:
			if seen[y * w + x] == 1 or img.get_pixel(x, y).a == 0.0:
				continue
			var box := Rect2i(x, y, 1, 1)
			var stack: Array[Vector2i] = [Vector2i(x, y)]
			seen[y * w + x] = 1
			while not stack.is_empty():
				var p: Vector2i = stack.pop_back()
				box = box.expand(p).expand(p + Vector2i.ONE)
				for dy in [-1, 0, 1]:
					for dx in [-1, 0, 1]:
						var q := Vector2i(p.x + dx, p.y + dy)
						if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h:
							continue
						if seen[q.y * w + q.x] == 1 or img.get_pixel(q.x, q.y).a == 0.0:
							continue
						seen[q.y * w + q.x] = 1
						stack.append(q)
			boxes.append(box)
	boxes = _merge_close(boxes)
	boxes.sort_custom(_row_order)
	return boxes


func _merge_close(boxes: Array[Rect2i]) -> Array[Rect2i]:
	var merged := true
	while merged:
		merged = false
		for i in boxes.size():
			for j in range(i + 1, boxes.size()):
				if boxes[i].grow(MERGE_GAP).intersects(boxes[j]):
					boxes[i] = boxes[i].merge(boxes[j])
					boxes.remove_at(j)
					merged = true
					break
			if merged:
				break
	return boxes


## Mesma linha = topos a menos de 12 px; aí ordena por x.
func _row_order(a: Rect2i, b: Rect2i) -> bool:
	if absi(a.position.y - b.position.y) > 12:
		return a.position.y < b.position.y
	return a.position.x < b.position.x
