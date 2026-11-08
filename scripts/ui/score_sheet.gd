class_name ScoreSheet
extends RefCounted
## Desenha a pauta da «Valsa da Aurora» para a tela de leitura (NoteUI). As quatro primeiras
## notas são mi, dó, sol e lá (a partir do dó da tecla de latão: 3 · 1 · 5 · 6). Com `pencil`,
## aparecem os números a lápis de Caio (1951) sobre elas.

const SIZE := Vector2i(920, 230)
const PAPER := Color("#E8DCC0")
const INK := Color("#2A1A1A")
const PENCIL := Color("#6A6A70")
const SPACE: float = 20.0
## Linha de baixo da pauta (mi).
const BOTTOM: float = 160.0
const LEFT: float = 30.0
const RIGHT: float = 890.0
## Passos acima do mi da linha de baixo: dó = -2, mi = 0, sol = 2, lá = 3.
const INTRO := [0, -2, 2, 3]
const REST := [4, 2, 0, 1, 2, -1, 0]
const NUMBERS := ["3", "1", "5", "6"]

static var _cache: Dictionary = {}


static func texture(pencil: bool) -> Texture2D:
	if _cache.has(pencil):
		return _cache[pencil]
	var image := Image.create(SIZE.x, SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(PAPER)
	for line in 5:
		_line(image, Vector2(LEFT, BOTTOM - line * SPACE), Vector2(RIGHT, BOTTOM - line * SPACE), 1.3, INK)
	_line(image, Vector2(LEFT, BOTTOM - 4 * SPACE), Vector2(LEFT, BOTTOM), 1.5, INK)
	_line(image, Vector2(RIGHT, BOTTOM - 4 * SPACE), Vector2(RIGHT, BOTTOM), 1.5, INK)
	_clef(image)
	# Compasso 3/4
	_digit(image, "3", Vector2(150, BOTTOM - 3 * SPACE), 15.0, 3.0, INK)
	_digit(image, "4", Vector2(150, BOTTOM - SPACE), 15.0, 3.0, INK)
	var x := 230.0
	for i in INTRO.size():
		_note(image, x, INTRO[i])
		if pencil:
			_digit(image, NUMBERS[i], Vector2(x, 34), 11.0, 2.2, PENCIL)
		x += 95.0
	_line(image, Vector2(x - 40, BOTTOM - 4 * SPACE), Vector2(x - 40, BOTTOM), 1.3, INK)
	x += 20.0
	for step: int in REST:
		_note(image, x, step)
		x += 62.0
	if pencil:
		# Seta curta apontando para a primeira nota, como quem marca onde começar
		_line(image, Vector2(190, 26), Vector2(212, 40), 1.6, PENCIL)
		_line(image, Vector2(212, 40), Vector2(204, 41), 1.6, PENCIL)
		_line(image, Vector2(212, 40), Vector2(209, 32), 1.6, PENCIL)
	var result := ImageTexture.create_from_image(image)
	_cache[pencil] = result
	return result


static func _y(step: int) -> float:
	return BOTTOM - step * SPACE / 2.0


static func _note(image: Image, x: float, step: int) -> void:
	var y := _y(step)
	# Linha suplementar do dó, abaixo da pauta
	if step <= -2:
		_line(image, Vector2(x - 20, _y(-2)), Vector2(x + 20, _y(-2)), 1.3, INK)
	_ellipse(image, Vector2(x, y), Vector2(12.0, 8.5), -0.35, INK)
	var stem_up := step < 4
	if stem_up:
		_line(image, Vector2(x + 11, y - 2), Vector2(x + 11, y - 3.4 * SPACE), 1.5, INK)
	else:
		_line(image, Vector2(x - 11, y + 2), Vector2(x - 11, y + 3.4 * SPACE), 1.5, INK)


## Clave de sol aproximada: espiral em volta da linha do sol, haste e gancho embaixo.
static func _clef(image: Image) -> void:
	var center := Vector2(78, _y(2))
	var points: Array[Vector2] = []
	var turns := 2.1 * PI
	for i in 60:
		var t := turns * i / 59.0
		var radius := 5.0 + 19.0 * t / turns
		points.append(center + Vector2(cos(t + PI) * radius, sin(t + PI) * radius))
	var last := points[-1]
	points.append(Vector2(center.x + 14, center.y - 34))
	points.append(Vector2(center.x + 8, BOTTOM - 4 * SPACE - 22))
	points.append(Vector2(center.x - 2, BOTTOM - 4 * SPACE - 30))
	points.append(Vector2(center.x - 8, BOTTOM - 4 * SPACE - 16))
	points.append(Vector2(center.x - 4, BOTTOM - 4 * SPACE + 6))
	points.append(Vector2(center.x + 6, BOTTOM + 22))
	points.append(Vector2(center.x, BOTTOM + 34))
	points.append(Vector2(center.x - 10, BOTTOM + 30))
	var previous := points[0]
	for point in points.slice(1):
		_line(image, previous, point, 2.4 if previous.distance_to(last) > 1 else 2.0, INK)
		previous = point
	_ellipse(image, Vector2(center.x - 9, BOTTOM + 27), Vector2(5, 5), 0.0, INK)


## Algarismo em traços de sete segmentos, com altura `height`.
static func _digit(image: Image, digit: String, center: Vector2, height: float, width: float, color: Color) -> void:
	var segments := {
		"1": ["b", "c"], "3": ["a", "b", "g", "c", "d"], "4": ["f", "g", "b", "c"],
		"5": ["a", "f", "g", "c", "d"], "6": ["a", "f", "g", "e", "c", "d"],
	}
	var w := height * 0.55
	var h := height
	var corners := {
		"tl": center + Vector2(-w / 2, -h), "tr": center + Vector2(w / 2, -h),
		"ml": center + Vector2(-w / 2, 0), "mr": center + Vector2(w / 2, 0),
		"bl": center + Vector2(-w / 2, h), "br": center + Vector2(w / 2, h),
	}
	var lines := {
		"a": ["tl", "tr"], "b": ["tr", "mr"], "c": ["mr", "br"], "d": ["bl", "br"],
		"e": ["ml", "bl"], "f": ["tl", "ml"], "g": ["ml", "mr"],
	}
	for segment: String in segments.get(digit, []):
		var ends: Array = lines[segment]
		_line(image, corners[ends[0]], corners[ends[1]], width, color)


static func _line(image: Image, a: Vector2, b: Vector2, width: float, color: Color) -> void:
	var low := Vector2i(floori(minf(a.x, b.x) - width - 1), floori(minf(a.y, b.y) - width - 1))
	var high := Vector2i(ceili(maxf(a.x, b.x) + width + 1), ceili(maxf(a.y, b.y) + width + 1))
	var direction := b - a
	var length_sq := maxf(direction.length_squared(), 0.0001)
	for py in range(maxi(low.y, 0), mini(high.y, SIZE.y)):
		for px in range(maxi(low.x, 0), mini(high.x, SIZE.x)):
			var p := Vector2(px + 0.5, py + 0.5)
			var t := clampf((p - a).dot(direction) / length_sq, 0.0, 1.0)
			var distance := p.distance_to(a + direction * t)
			_blend(image, px, py, color, clampf(width / 2.0 + 0.5 - distance, 0.0, 1.0))


static func _ellipse(image: Image, center: Vector2, radius: Vector2, angle: float, color: Color) -> void:
	var reach := int(maxf(radius.x, radius.y)) + 2
	for py in range(maxi(int(center.y) - reach, 0), mini(int(center.y) + reach, SIZE.y)):
		for px in range(maxi(int(center.x) - reach, 0), mini(int(center.x) + reach, SIZE.x)):
			var p := (Vector2(px + 0.5, py + 0.5) - center).rotated(-angle)
			var value := sqrt(pow(p.x / radius.x, 2) + pow(p.y / radius.y, 2))
			_blend(image, px, py, color, clampf((1.0 - value) * radius.y + 0.5, 0.0, 1.0))


static func _blend(image: Image, x: int, y: int, color: Color, amount: float) -> void:
	if amount <= 0.0:
		return
	image.set_pixel(x, y, image.get_pixel(x, y).lerp(color, amount))
