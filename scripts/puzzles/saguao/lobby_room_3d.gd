@tool
class_name LobbyRoom3D
extends HotelBuilder3D
## Saguão do Grand Hotel Aurora em 3D, montado por código nas duas épocas.
## A planta é a do Saguão 2D (LobbyRoom), a 32 px por metro: mesmas paredes, portas,
## balcão, colunas, escada, elevador, lustre e piano, e as mesmas colisões.
## 1923: hotel em funcionamento à noite, luz quente, latão, veludo e mármore.
## Hoje (`present = true`): o mesmo salão 100 anos depois, em ruínas e no escuro.

const HEIGHT: float = 6.0
const WALL: float = 0.3
const WAINSCOT: float = 1.15
const WEST: float = 0.5
const EAST: float = 19.5
const NORTH: float = 2.0
const SOUTH: float = 10.75
## Porta da Cozinha na parede oeste (z) e entrada principal na parede sul (x).
const KITCHEN_DOOR := Vector2(6.5, 8.0)
const ENTRANCE := Vector2(9.0, 11.0)
## Arco da escada e vão do elevador na parede norte (x).
const STAIR_ARCH := Vector2(1.5, 4.5)
const ELEVATOR := Vector2(15.4, 17.1)
## Porta da Biblioteca na parede norte (x), entre o elevador e o canto leste: a Biblioteca
## ocupa a ala nordeste, longe da Cozinha (ala oeste).
const LIBRARY_DOOR := Vector2(18.05, 19.35)
const PIT_FLOOR := -2.65
const RACK := Vector3(7.85, 1.75, NORTH)
## Cofre da gerência: na parede norte, entre a ponta leste do balcão e o elevador, onde a
## porta (dobradiça à direita) abre inteira sem bater no balcão.
const SAFE := Vector3(14.1, 0.2, NORTH)
## Janelas da parede leste (z).
const WINDOWS: Array[Vector2] = [Vector2(3.0, 4.8), Vector2(8.9, 10.4)]
const WINDOW_SILL: float = 1.2
const WINDOW_TOP: float = 4.6
const CHANDELIER := Vector3(10.0, 0.0, 7.0)
const PIANO := Vector3(17.0, 0.0, 8.0)
const MODELS := "res://art/models/"
const PIANO_MODEL := MODELS + "piano_cauda.glb"
const COLUMNS: Array[Vector2] = [Vector2(5, 5.5), Vector2(15, 5.5), Vector2(5, 9.5), Vector2(15, 9.5)]

## Folhas das palmeiras: comprimento (m) e quantos pares de folíolos.
const FROND_LENGTH: float = 0.95
const FROND_STATIONS: int = 7

const WARM := Color("#F2D49B")
const COLD := Color("#9FB4C8")


func _build_room() -> void:
	_build_shell()
	_build_wall_dressing()
	_build_ceiling()
	_build_floor_coverings()
	_build_stairs()
	_build_elevator()
	_build_reception()
	_build_columns()
	_build_chandelier()
	_build_piano()
	_build_kitchen_door()
	_build_library_door()
	_build_entrance()
	_build_windows()
	_build_furniture()
	_build_wall_art()
	if present:
		_build_ruin_details()
	_build_lights()


# --- Paredes, piso e teto -------------------------------------------------------------

func _build_shell() -> void:
	# A laje termina na soleira. Dentro do vão, o primeiro piso é o fundo do poço.
	for bounds: Rect2 in [Rect2(-1, NORTH, 22, 12.5-NORTH), Rect2(-1, -1, ELEVATOR.x+1, NORTH+1), Rect2(ELEVATOR.y, -1, 21-ELEVATOR.y, NORTH+1)]:
		var a := Vector3(bounds.position.x, -0.2, bounds.position.y)
		var b := Vector3(bounds.end.x, 0, bounds.end.y)
		_part(a, b, "floor")
		_solid(a, b, "Floor")
	_part(Vector3(-0.5, HEIGHT, -3.5), Vector3(20.5, HEIGHT + 0.3, 11.5), "ceiling")

	# Norte: arco da escada e vão do elevador
	var n0 := NORTH - WALL
	_part(Vector3(WEST - WALL, 0, n0), Vector3(STAIR_ARCH.x, HEIGHT, NORTH), "wallpaper")
	_part(Vector3(STAIR_ARCH.x, 0, n0), Vector3(STAIR_ARCH.y, 0.85, NORTH), "wallpaper")
	_part(Vector3(STAIR_ARCH.x, 4.3, n0), Vector3(STAIR_ARCH.y, HEIGHT, NORTH), "wallpaper")
	_part(Vector3(STAIR_ARCH.y, 0, n0), Vector3(ELEVATOR.x, HEIGHT, NORTH), "wallpaper")
	_part(Vector3(ELEVATOR.x, 2.7, n0), Vector3(ELEVATOR.y, HEIGHT, NORTH), "wallpaper")
	_part(Vector3(ELEVATOR.y, 0, n0), Vector3(EAST + WALL, HEIGHT, NORTH), "wallpaper")
	_solid(Vector3(WEST - WALL, 0, n0), Vector3(ELEVATOR.x, HEIGHT, NORTH), "WallNorth")
	_solid(Vector3(ELEVATOR.y, 0, n0), Vector3(EAST + WALL, HEIGHT, NORTH), "WallNorthEast")
	_solid(Vector3(ELEVATOR.x, 2.7, n0), Vector3(ELEVATOR.y, HEIGHT, NORTH), "Lintel")

	# Oeste: porta da Cozinha
	_part(Vector3(WEST - WALL, 0, NORTH), Vector3(WEST, HEIGHT, KITCHEN_DOOR.x), "wallpaper")
	_part(Vector3(WEST - WALL, 0, KITCHEN_DOOR.y), Vector3(WEST, HEIGHT, SOUTH), "wallpaper")
	_part(Vector3(WEST - WALL, 2.4, KITCHEN_DOOR.x), Vector3(WEST, HEIGHT, KITCHEN_DOOR.y), "wallpaper")
	_solid(Vector3(WEST - WALL, 0, NORTH), Vector3(WEST, HEIGHT, SOUTH), "WallWest")

	# Sul: entrada com bandeira (vidro em leque) por cima
	_part(Vector3(WEST - WALL, 0, SOUTH), Vector3(ENTRANCE.x, HEIGHT, SOUTH + WALL), "wallpaper")
	_part(Vector3(ENTRANCE.y, 0, SOUTH), Vector3(EAST + WALL, HEIGHT, SOUTH + WALL), "wallpaper")
	_part(Vector3(ENTRANCE.x, 4.2, SOUTH), Vector3(ENTRANCE.y, HEIGHT, SOUTH + WALL), "wallpaper")
	_solid(Vector3(WEST - WALL, 0, SOUTH), Vector3(EAST + WALL, HEIGHT, SOUTH + WALL), "WallSouth")

	# Leste: duas janelas altas
	var z := NORTH
	for window in WINDOWS:
		_part(Vector3(EAST, 0, z), Vector3(EAST + WALL, HEIGHT, window.x), "wallpaper")
		_part(Vector3(EAST, 0, window.x), Vector3(EAST + WALL, WINDOW_SILL, window.y), "wallpaper")
		_part(Vector3(EAST, WINDOW_TOP, window.x), Vector3(EAST + WALL, HEIGHT, window.y), "wallpaper")
		z = window.y
	_part(Vector3(EAST, 0, z), Vector3(EAST + WALL, HEIGHT, SOUTH), "wallpaper")
	_solid(Vector3(EAST, 0, NORTH), Vector3(EAST + WALL, HEIGHT, SOUTH), "WallEast")


## Uma parede vista de dentro: origem no canto (s = 0), direção ao longo dela e normal para a sala.
class WallLine:
	var origin: Vector3
	var along: Vector3
	var inward: Vector3
	var length: float
	## Vãos: [início, fim, altura da base]. Lambri e rodapé param nos vãos que chegam ao chão.
	var gaps: Array

	func _init(o: Vector3, a: Vector3, n: Vector3, l: float, g: Array) -> void:
		origin = o
		along = a
		inward = n
		length = l
		gaps = g

	func point(s: float, height: float, depth: float) -> Vector3:
		return origin + along * s + Vector3.UP * height + inward * depth


func _walls() -> Array[WallLine]:
	return [
		WallLine.new(Vector3(WEST, 0, NORTH), Vector3.RIGHT, Vector3.BACK, EAST - WEST,
			[[STAIR_ARCH.x - WEST, STAIR_ARCH.y - WEST, 0.0], [ELEVATOR.x - WEST, ELEVATOR.y - WEST, 0.0]]),
		WallLine.new(Vector3(WEST, 0, SOUTH), Vector3.FORWARD, Vector3.RIGHT, SOUTH - NORTH,
			[[SOUTH - KITCHEN_DOOR.y, SOUTH - KITCHEN_DOOR.x, 0.0]]),
		WallLine.new(Vector3(EAST, 0, SOUTH), Vector3.LEFT, Vector3.FORWARD, EAST - WEST,
			[[EAST - ENTRANCE.y, EAST - ENTRANCE.x, 0.0]]),
		WallLine.new(Vector3(EAST, 0, NORTH), Vector3.BACK, Vector3.LEFT, SOUTH - NORTH,
			[[WINDOWS[0].x - NORTH, WINDOWS[0].y - NORTH, WINDOW_SILL], [WINDOWS[1].x - NORTH, WINDOWS[1].y - NORTH, WINDOW_SILL]]),
	]


## Trecho de uma peça ao longo da parede, entre s0 e s1.
func _along(wall: WallLine, s0: float, s1: float, y0: float, y1: float, d0: float, d1: float, role: String) -> void:
	_part(wall.point(s0, y0, d0), wall.point(s1, y1, d1), role)


## Intervalos da parede fora dos vãos que chegam ao chão.
func _solid_spans(wall: WallLine) -> Array[Vector2]:
	var spans: Array[Vector2] = []
	var start := 0.0
	for gap: Array in wall.gaps:
		if gap[2] > 0.0:
			continue
		spans.append(Vector2(start, gap[0]))
		start = gap[1]
	spans.append(Vector2(start, wall.length))
	return spans


## Lambri com almofadas, rodapé, cimalha e sanca em todas as paredes; pilastras ritmando o salão.
func _build_wall_dressing() -> void:
	for wall in _walls():
		for span in _solid_spans(wall):
			if span.y - span.x < 0.05:
				continue
			_along(wall, span.x, span.y, 0, WAINSCOT, 0, 0.05, "wainscot")
			_along(wall, span.x, span.y, 0, 0.2, 0, 0.09, "dark_wood")
			_along(wall, span.x, span.y, WAINSCOT, WAINSCOT + 0.07, 0, 0.1, "mahogany")
			_along(wall, span.x, span.y, WAINSCOT + 0.07, WAINSCOT + 0.09, 0, 0.06, "brass")
			# Almofadas do lambri: um painel saliente a cada 1,2 m
			var count := int((span.y - span.x) / 1.2)
			for i in count:
				var s := span.x + (span.y - span.x) * (i + 0.5) / count
				_along(wall, s - 0.45, s + 0.45, 0.32, WAINSCOT - 0.15, 0.05, 0.08, "panel")
		# Sanca em degraus no alto, contínua
		_along(wall, -0.3, wall.length + 0.3, HEIGHT - 0.5, HEIGHT - 0.38, 0, 0.12, "mahogany")
		_along(wall, -0.3, wall.length + 0.3, HEIGHT - 0.38, HEIGHT - 0.34, 0, 0.16, "brass")
		_along(wall, -0.3, wall.length + 0.3, HEIGHT - 0.34, HEIGHT, 0, 0.26, "coffer")
		# Friso acima das portas e janelas, abaixo da sanca
		_along(wall, -0.3, wall.length + 0.3, 4.7, 4.76, 0, 0.05, "brass")

	# Pilastras com base e capitel
	var north: WallLine = _walls()[0]
	var south: WallLine = _walls()[2]
	for s: float in [5.7, 13.7, 18.0]:
		_pilaster(north, s)
	for s: float in [1.5, 6.5, 12.5, 17.5]:
		_pilaster(south, s)
	_pilaster(_walls()[1], 1.4)
	_pilaster(_walls()[1], 7.3)
	_pilaster(_walls()[3], 4.5)


func _pilaster(wall: WallLine, s: float) -> void:
	_along(wall, s - 0.28, s + 0.28, 0, 0.3, 0, 0.16, "dark_wood")
	_along(wall, s - 0.22, s + 0.22, 0.3, HEIGHT - 0.55, 0, 0.1, "column")
	for k in 4:
		var x := s - 0.15 + k * 0.1
		_along(wall, x - 0.012, x + 0.012, 0.45, HEIGHT - 0.75, 0.1, 0.115, "brass")
	_along(wall, s - 0.3, s + 0.3, HEIGHT - 0.75, HEIGHT - 0.55, 0, 0.18, "brass")


func _build_ceiling() -> void:
	# Caixotões: vigas nas duas direções, com filete de latão por baixo
	var y := HEIGHT - 0.32
	for i in 9:
		var x := WEST + (EAST - WEST) * i / 8.0
		_part(Vector3(x - 0.16, y, NORTH), Vector3(x + 0.16, HEIGHT, SOUTH), "coffer")
		_part(Vector3(x - 0.04, y - 0.015, NORTH), Vector3(x + 0.04, y, SOUTH), "brass")
	for j in 5:
		var z := NORTH + (SOUTH - NORTH) * j / 4.0
		_part(Vector3(WEST, y, z - 0.16), Vector3(EAST, HEIGHT, z + 0.16), "coffer")
		_part(Vector3(WEST, y - 0.015, z - 0.04), Vector3(EAST, y, z + 0.04), "brass")
	# Florão do lustre
	_cylinder(Vector3(CHANDELIER.x, HEIGHT - 0.06, CHANDELIER.z), 0.95, 0.95, 0.06, "coffer", Vector3.ZERO, 32)
	_torus(Vector3(CHANDELIER.x, HEIGHT - 0.06, CHANDELIER.z), 0.82, 0.95, "brass")
	_torus(Vector3(CHANDELIER.x, HEIGHT - 0.06, CHANDELIER.z), 0.38, 0.46, "brass")


func _build_floor_coverings() -> void:
	var rug_center := Vector2(CHANDELIER.x, CHANDELIER.z)
	var rug_half := Vector2(2.2, 1.3)
	var rug := HotelMaterials.rug_material("rug", present, rug_center, rug_half)
	_part(Vector3(rug_center.x - rug_half.x, 0, rug_center.y - rug_half.y), Vector3(rug_center.x + rug_half.x, 0.02, rug_center.y + rug_half.y), "rug", Vector3.ZERO, rug)
	# Passadeira da entrada ao tapete e do tapete ao balcão
	for run: Vector2 in [Vector2(8.3, SOUTH - 0.05), Vector2(4.15, 5.7)]:
		var center := Vector2(10.0, (run.x + run.y) / 2.0)
		var half := Vector2(0.65, (run.y - run.x) / 2.0)
		var runner := HotelMaterials.rug_material("runner", present, center, half)
		_part(Vector3(9.35, 0, run.x), Vector3(10.65, 0.015, run.y), "runner", Vector3.ZERO, runner)


# --- Escada --------------------------------------------------------------------------

## Escada a noroeste: sobe para o norte, entra num arco e continua no escuro.
## A planta só permite chegar até o primeiro degrau: a colisão fecha o vão inteiro.
func _build_stairs() -> void:
	var x0 := STAIR_ARCH.x
	var x1 := STAIR_ARCH.y
	var rise := 0.17
	var run := 0.3
	var front := 3.5
	_solid(Vector3(x0 - 0.1, 0, NORTH - 4.0), Vector3(x1 + 0.1, HEIGHT, front + 0.15), "Stairs")

	# Caixa da escada atrás do arco
	_part(Vector3(x0 - 0.3, 0, NORTH - 4.0), Vector3(x0, 4.6, NORTH), "wallpaper")
	_part(Vector3(x1, 0, NORTH - 4.0), Vector3(x1 + 0.3, 4.6, NORTH), "wallpaper")
	_part(Vector3(x0, 0, NORTH - 4.3), Vector3(x1, 4.6, NORTH - 4.0), "wallpaper")
	_part(Vector3(x0, 4.3, NORTH - 4.0), Vector3(x1, 4.6, NORTH), "coffer")
	# Moldura do arco: ombreiras e um arco de aduelas
	for x: float in [x0 - 0.18, x1]:
		_part(Vector3(x, 0.85, NORTH), Vector3(x + 0.18, 3.6, NORTH + 0.08), "dark_wood")
	for i in 11:
		var angle := -90.0 + 180.0 * i / 10.0
		var direction := Vector3(sin(deg_to_rad(angle)), cos(deg_to_rad(angle)), 0)
		var center := Vector3((x0 + x1) / 2.0, 3.6, NORTH + 0.04) + direction * 1.58
		_block(center, Vector3(0.3, 0.2, 0.09), "dark_wood", Vector3(0, 0, -angle))

	var steps := 15
	for i in steps:
		var z_front := front - i * run
		var height := rise * (i + 1)
		var broken := present and i in [1, 3, 6, 7, 10]
		if broken:
			continue
		var tilt := Vector3(0, 0, 9.0 * (_random(i) - 0.5)) if present else Vector3.ZERO
		_part(Vector3(x0, height - 0.05, z_front - run), Vector3(x1, height, z_front + 0.03), "mahogany", tilt)
		_part(Vector3(x0, height - rise, z_front - 0.03), Vector3(x1, height - 0.05, z_front), "dark_wood", tilt)
		if not present or i % 2 == 0:
			# Passadeira vermelha com varões de latão
			_part(Vector3(x0 + 0.45, height, z_front - run), Vector3(x1 - 0.45, height + 0.012, z_front + 0.035), "velvet", tilt)
			_part(Vector3(x0 + 0.4, height + 0.012, z_front - run + 0.02), Vector3(x1 - 0.4, height + 0.03, z_front - run + 0.04), "brass", tilt)
	# Laterais (longarinas)
	for x: float in [x0 - 0.06, x1]:
		_part(Vector3(x, 0, NORTH - 4.0), Vector3(x + 0.06, rise * steps * 0.5, front + 0.03), "dark_wood")

	# Corrimão com balaústres e pilares de saída com globo
	var rail_angle := rad_to_deg(atan2(rise, run))
	for side_x: float in [x0 + 0.06, x1 - 0.06]:
		var newel := Vector3(side_x, 0, front + 0.15)
		if present and side_x > 2.0:
			# Pilar tombado sobre os escombros
			_block(Vector3(side_x + 0.4, 0.35, front + 0.6), Vector3(0.16, 1.1, 0.16), "dark_wood", Vector3(70, 25, 0))
			_sphere(Vector3(side_x + 0.9, 0.12, front + 0.9), 0.11, "glass")
		else:
			_part(newel + Vector3(-0.09, 0, -0.09), newel + Vector3(0.09, 1.15, 0.09), "dark_wood")
			_part(newel + Vector3(-0.11, 1.15, -0.11), newel + Vector3(0.11, 1.2, 0.11), "brass")
			_cylinder(newel + Vector3(0, 1.2, 0), 0.03, 0.05, 0.12, "brass")
			_sphere(newel + Vector3(0, 1.42, 0), 0.12, "bulb" if not present else "glass")
		for i in 6:
			var z := front - 0.1 - i * run
			if present and (i == 2 or i == 4) and side_x > 2.0:
				continue
			var base_height := rise * (i + 1)
			var lean := Vector3(0, 0, 18.0 * (_random(i, side_x) - 0.5)) if present else Vector3.ZERO
			_cylinder(Vector3(side_x, base_height, z), 0.022, 0.03, 0.85, "brass" if not present else "iron", lean, 8)
		var rail_start := Vector3(side_x, 1.0, front + 0.05)
		var rail_end := Vector3(side_x, 1.0 + rise * 6, front - run * 6)
		var rail_tilt := Vector3(rail_angle, 0, 0)
		if present and side_x > 2.0:
			rail_tilt = Vector3(rail_angle - 25.0, 6, 0)
		_block((rail_start + rail_end) / 2.0, Vector3(0.08, 0.06, rail_start.distance_to(rail_end) + 0.1), "mahogany", rail_tilt)

	if present:
		# Escombros: degraus quebrados e reboco caído na base da escada
		_solid(Vector3(x0, 0, front), Vector3(x1, 0.8, front + 0.7), "Rubble")
		# Em camadas: cada pedaço apoiado no chão ou na camada de baixo (nada fica no ar), mais
		# alto perto da escada, dentro da colisão Rubble.
		for i in 14:
			var layer := 0 if i < 7 else (1 if i < 11 else 2)
			var size := Vector3(0.25 + _random(i, 4.0) * 0.45, 0.16 + _random(i, 5.0) * 0.18, 0.2 + _random(i, 6.0) * 0.2)
			var z_span := 0.4 - layer * 0.1
			var center := Vector3(x0 + 0.25 + _random(i, 1.0) * (x1 - x0 - 0.5),
				[0.0, 0.26, 0.48][layer] + size.y * 0.42, front + 0.1 + _random(i, 3.0) * z_span)
			_block(center, size, "rubble" if i % 3 != 0 else "plank",
				Vector3(_random(i, 7.0) * 16.0 - 8.0, _random(i, 8.0) * 180.0, _random(i, 9.0) * 12.0 - 6.0))
		for i in 3:
			_block(Vector3(x0 + 0.6 + i * 0.9, 2.2 - i * 0.3, NORTH + 0.1), Vector3(0.18, 0.18, 3.2), "plank", Vector3(35 + i * 8, 10 - i * 12, 0))


# --- Elevador --------------------------------------------------------------------------

func _build_elevator() -> void:
	var x0 := ELEVATOR.x
	var x1 := ELEVATOR.y
	var center_x := (x0 + x1) / 2.0
	var face := NORTH
	# Batentes, verga e leque art déco
	_part(Vector3(x0 - 0.22, 0, face), Vector3(x0, 2.9, face + 0.12), "brass")
	_part(Vector3(x1, 0, face), Vector3(x1 + 0.22, 2.9, face + 0.12), "brass")
	_part(Vector3(x0 - 0.22, 2.7, face), Vector3(x1 + 0.22, 2.95, face + 0.12), "brass")
	var pivot := Vector3(center_x, 2.95, face + 0.05)
	for i in 11:
		var angle := -75.0 + 150.0 * i / 10.0
		var direction := Vector3(-sin(deg_to_rad(angle)), cos(deg_to_rad(angle)), 0)
		_block(pivot + direction * 0.42, Vector3(0.035, 0.7, 0.03), "brass", Vector3(0, 0, angle))
	_torus(pivot + Vector3(0, 0, 0.01), 0.74, 0.8, "brass", Vector3(90, 0, 0))
	# Mostrador de andar com ponteiro
	var dial := Vector3(center_x, 3.95, face + 0.04)
	_cylinder(dial - Vector3(0, 0, 0.02), 0.32, 0.32, 0.04, "brass", Vector3(90, 0, 0), 24)
	_cylinder(dial + Vector3(0, 0, 0.0), 0.27, 0.27, 0.03, "ivory" if not present else "paper", Vector3(90, 0, 0), 24)
	var needle_angle := -50.0 if not present else 110.0
	_block(dial + Vector3(0, 0, 0.04) + Vector3(-sin(deg_to_rad(needle_angle)), cos(deg_to_rad(needle_angle)), 0) * 0.11, Vector3(0.015, 0.22, 0.01), "iron", Vector3(0, 0, needle_angle))
	_label("T   1   2   3", dial + Vector3(0, 0.12, 0.05), 0.07, Color("#2A1A10"))

	var car := preload("res://scripts/puzzles/saguao/lobby_lift_car_3d.gd").new()
	car.name = "Cabin"
	car.width = x1-x0
	car.position = Vector3(center_x, 0, face)
	car.present = present
	_add(car)
	_build_lift_pit()
	if not present:
		_solid(Vector3(x0, 0, face), Vector3(x1, 2.65, face+0.06), "Grille")
		# Grade pantográfica: verticais e diagonais cruzadas
		for i in 9:
			var x := x0 + 0.08 + i * (x1 - x0 - 0.16) / 8.0
			_part(Vector3(x - 0.015, 0, face + 0.02), Vector3(x + 0.015, 2.62, face + 0.05), "brass")
		for i in 8:
			var x := x0 + 0.18 + i * (x1 - x0 - 0.36) / 7.0
			for sign: float in [1.0, -1.0]:
				_block(Vector3(x, 1.31, face + 0.06), Vector3(0.02, 2.75, 0.015), "brass", Vector3(0, 0, sign * 9.0))
	else:
		# Portas de ferro forçadas, uma meio aberta e torta
		_part(Vector3(x0, 0, face + 0.02), Vector3(x0 + 0.42, 2.6, face + 0.06), "iron", Vector3(0, 8, 0))
		_block(Vector3(x1 - 0.09, 1.2, face - 0.17), Vector3(0.6, 2.4, 0.04), "iron", Vector3(2, -78, 3))


	# Botoeira à direita
	var panel := Vector3(x1 + 0.45, 1.35, face)
	_part(panel + Vector3(-0.09, -0.16, 0), panel + Vector3(0.09, 0.16, 0.025), "brass")
	_sphere(panel + Vector3(0, 0.05, 0.035), 0.025, "bulb" if not present else "iron")
	_part(panel + Vector3(-0.012, -0.08, 0.025), panel + Vector3(0.012, -0.04, 0.03), "dark")


func _build_lift_pit() -> void:
	var x0 := ELEVATOR.x
	var x1 := ELEVATOR.y
	for corners: Array in [
		[Vector3(x0-0.14, PIT_FLOOR, -0.45), Vector3(x0, HEIGHT, NORTH)],
		[Vector3(x1, PIT_FLOOR, -0.45), Vector3(x1+0.14, HEIGHT, NORTH)],
		[Vector3(x0, PIT_FLOOR, -0.45), Vector3(x1, HEIGHT, -0.3)],
		[Vector3(x0, PIT_FLOOR, NORTH), Vector3(x1, 0, NORTH+0.14)],
		[Vector3(x0, PIT_FLOOR-0.18, -0.45), Vector3(x1, PIT_FLOOR, NORTH)]]:
		_part(corners[0], corners[1], "stone")
		_solid(corners[0], corners[1], "ShaftWall")
	# Guias da cabine e escada de manutenção na parede lateral.
	for x: float in [x0+0.08, x1-0.08]:
		_block(Vector3(x, 1.6, -0.24), Vector3(0.075, 8.5, 0.10), "cast_iron")
	for z: float in [1.21, 1.73]:
		_block(Vector3(x1-0.11, -0.8, z), Vector3(0.045, 3.7, 0.045), "iron")
	for rung in 12:
		_block(Vector3(x1-0.11, PIT_FLOOR+0.22+rung*0.30, 1.47), Vector3(0.055, 0.045, 0.56), "iron")


# --- Recepção -----------------------------------------------------------------------

func _build_reception() -> void:
	var x0 := 7.0
	var x1 := 13.0
	var z0 := 3.05
	var z1 := 4.0
	_solid(Vector3(x0 - 0.1, 0, z0 - 0.1), Vector3(x1 + 0.1, 1.15, z1 + 0.1), "Counter")
	# Corpo com almofadas na frente e rodapé de latão
	_part(Vector3(x0, 0, z0), Vector3(x1, 1.0, z1), "mahogany")
	_part(Vector3(x0 - 0.05, 0, z1 - 0.02), Vector3(x1 + 0.05, 0.12, z1 + 0.04), "brass")
	for i in 6:
		var x := x0 + 0.5 + i * 1.0
		_part(Vector3(x - 0.38, 0.25, z1), Vector3(x + 0.38, 0.85, z1 + 0.04), "panel")
		_part(Vector3(x - 0.3, 0.33, z1 + 0.04), Vector3(x + 0.3, 0.77, z1 + 0.05), "mahogany")
	# Tampo de mármore com friso de latão
	var top_tilt := Vector3.ZERO if not present else Vector3(0, 0, 0)
	_part(Vector3(x0 - 0.1, 1.0, z0 - 0.08), Vector3(x1 + 0.1, 1.06, z1 + 0.1), "brass")
	if present:
		# Tampo partido: um pedaço caiu na frente do balcão
		_part(Vector3(x0 - 0.12, 1.06, z0 - 0.1), Vector3(11.4, 1.12, z1 + 0.12), "marble")
		_block(Vector3(12.3, 0.25, z1 + 0.55), Vector3(1.5, 0.06, 1.1), "marble", Vector3(28, 15, 6))
	else:
		_part(Vector3(x0 - 0.12, 1.06, z0 - 0.1), Vector3(x1 + 0.12, 1.12, z1 + 0.12), "marble", top_tilt)

	# Livro de hóspedes aberto (o Livro interativo da cena fica aqui: 10; 3,5)
	var book := Vector3(10.0, 1.12, 3.5)
	_part(book + Vector3(-0.38, 0, -0.26), book + Vector3(0.38, 0.02, 0.26), "dark_wood")
	_block(book + Vector3(-0.18, 0.03, 0), Vector3(0.34, 0.025, 0.46), "paper", Vector3(0, 0, -4))
	_block(book + Vector3(0.18, 0.03, 0), Vector3(0.34, 0.025, 0.46), "paper", Vector3(0, 0, 4))
	_part(book + Vector3(-0.006, 0.02, -0.24), book + Vector3(0.006, 0.05, 0.24), "dark_wood")
	if not present:
		# Tinteiro, caneta, campainha e luminária de banqueiro
		_cylinder(book + Vector3(0.55, 0, -0.1), 0.05, 0.04, 0.07, "glass")
		_block(book + Vector3(0.5, 0.02, 0.12), Vector3(0.012, 0.012, 0.18), "lacquer", Vector3(0, 30, 0))
		_cylinder(Vector3(11.2, 1.12, 3.6), 0.07, 0.07, 0.02, "dark_wood")
		_sphere(Vector3(11.2, 1.16, 3.6), 0.06, "brass", Vector3(1, 0.7, 1))
		_cylinder(Vector3(8.6, 1.12, 3.4), 0.1, 0.1, 0.03, "brass")
		_cylinder(Vector3(8.6, 1.15, 3.4), 0.015, 0.015, 0.3, "brass")
		_block(Vector3(8.6, 1.47, 3.42), Vector3(0.36, 0.08, 0.16), "green_velvet", Vector3(-12, 0, 0))
		_part(Vector3(8.45, 1.41, 3.36), Vector3(8.75, 1.43, 3.5), "bulb")
		_omni(Vector3(8.6, 1.35, 3.6), WARM, 0.7, 3.0)
	else:
		# Luminária tombada e papéis espalhados
		_cylinder(Vector3(8.9, 1.12, 3.3), 0.015, 0.015, 0.3, "brass", Vector3(0, 0, 80))
		_block(Vector3(8.45, 1.16, 3.35), Vector3(0.36, 0.08, 0.16), "green_velvet", Vector3(0, 40, 75))

	# Cadeira atrás do balcão
	var chair := Vector3(9.3, 0, 2.6)
	var chair_tilt := Vector3.ZERO if not present else Vector3(0, 30, 82)
	_block(chair + Vector3(0, 0.5, 0), Vector3(0.5, 0.08, 0.5), "velvet", chair_tilt)
	_block(chair + Vector3(0, 0.85, -0.22), Vector3(0.5, 0.6, 0.06), "mahogany", chair_tilt)

	# Letreiro de latão acima do balcão; hoje faltam letras
	_part(Vector3(7.4, 3.05, NORTH), Vector3(12.6, 3.6, NORTH + 0.05), "dark_wood")
	_part(Vector3(7.35, 3.0, NORTH), Vector3(12.65, 3.05, NORTH + 0.07), "brass")
	_part(Vector3(7.35, 3.6, NORTH), Vector3(12.65, 3.65, NORTH + 0.07), "brass")
	var sign_text := "GRAND HOTEL AURORA" if not present else "GR ND  HOT L  AUR RA"
	_label(sign_text, Vector3(10, 3.32, NORTH + 0.07), 0.3, Color("#E8C27A") if not present else Color("#6E5A34"))

	_build_key_rack(RACK)
	_build_safe(SAFE)


## Quadro de chaves com 12 ganchos (2 fileiras de 6). Hoje, podre e vazio.
func _build_key_rack(center: Vector3) -> void:
	var board := "dark_wood" if not present else "plank"
	_part(center + Vector3(-0.66, -0.47, 0), center + Vector3(0.66, 0.47, 0.06), board)
	_part(center + Vector3(-0.7, 0.47, 0), center + Vector3(0.7, 0.55, 0.09), "brass" if not present else "iron")
	for row in 2:
		for col in 6:
			var hook := center + Vector3(-0.5 + col * 0.2, 0.22 - row * 0.44, 0.06)
			_part(hook + Vector3(-0.06, 0.06, 0), hook + Vector3(0.06, 0.12, 0.005), "brass" if not present else "paper")
			_cylinder(hook, 0.008, 0.008, 0.05, "brass" if not present else "iron", Vector3(90, 0, 0), 6)


## Cofre da gerência, atrás do balcão. A porta que abre fica com LobbyExitPuzzle3D.
func _build_safe(base: Vector3) -> void:
	_solid(Vector3(base.x - 0.58, 0, base.z), Vector3(base.x + 0.58, base.y + 1.1, base.z + 0.53), "Safe")
	var body := "lacquer" if not present else "iron"
	_part(base + Vector3(-0.58, 0, 0), base + Vector3(0.58, 1.1, 0.5), body)
	_part(base + Vector3(-0.52, 0.06, 0.5), base + Vector3(0.52, 1.04, 0.52), body)
	for y: float in [0.1, 1.0]:
		_part(base + Vector3(-0.5, y, 0.52), base + Vector3(0.5, y + 0.012, 0.53), "brass")
	for x: float in [-0.5, 0.49]:
		_part(base + Vector3(x, 0.1, 0.52), base + Vector3(x + 0.012, 1.0, 0.53), "brass")
	_cylinder(base + Vector3(0, 0.62, 0.52), 0.11, 0.11, 0.04, "brass", Vector3(90, 0, 0), 24)
	_cylinder(base + Vector3(0, 0.62, 0.55), 0.04, 0.04, 0.03, "iron", Vector3(90, 0, 0), 12)
	_block(base + Vector3(0.22, 0.4, 0.56), Vector3(0.2, 0.03, 0.03), "brass", Vector3(0, 0, -20))
	for y: float in [0.2, 0.9]:
		_cylinder(base + Vector3(0.52, y, 0.53), 0.025, 0.025, 0.12, "brass")
	# Segunda fechadura, de chave, abaixo do segredo (a chave do gerente, da torre)
	_part(base + Vector3(-0.255, 0.33, 0.52), base + Vector3(-0.185, 0.47, 0.534), "brass")
	_part(base + Vector3(-0.228, 0.36, 0.534), base + Vector3(-0.212, 0.42, 0.538), "dark")
	if not present:
		# Luz baixa de arandela sobre o cofre: sem ela a laca preta sumia na sombra do canto
		_omni(base + Vector3(0, 1.45, 0.95), WARM, 1.0, 2.8)
		# Frase riscada a lápis na porta: a senha é a data em que o lustre se acendeu
		_label("o dia em que o Aurora se acendeu", base + Vector3(0, 0.88, 0.535), 0.055, Color("#2A2018"))
		_block(base + Vector3(0, 0.885, 0.537), Vector3(0.82, 0.006, 0.002), "dark", Vector3(0, 0, 2))


# --- Colunas, lustre, piano -------------------------------------------------------------

func _build_columns() -> void:
	for index in COLUMNS.size():
		var at := Vector3(COLUMNS[index].x, 0, COLUMNS[index].y)
		_solid_cylinder(at, 0.48, HEIGHT, "Column")
		_part(at + Vector3(-0.46, 0, -0.46), at + Vector3(0.46, 0.28, 0.46), "dark_wood")
		_cylinder(at + Vector3(0, 0.28, 0), 0.42, 0.38, 0.14, "brass", Vector3.ZERO, 24)
		_torus(at + Vector3(0, 0.46, 0), 0.32, 0.4, "brass")
		_cylinder(at + Vector3(0, 0.42, 0), 0.34, 0.31, HEIGHT - 1.25, "column", Vector3.ZERO, 24)
		# Caneluras de latão
		for k in 12:
			var angle := TAU * k / 12.0
			var offset := Vector3(cos(angle), 0, sin(angle)) * 0.315
			_cylinder(at + offset + Vector3(0, 0.6, 0), 0.012, 0.012, HEIGHT - 1.7, "brass", Vector3.ZERO, 4)
		_cylinder(at + Vector3(0, HEIGHT - 0.83, 0), 0.32, 0.52, 0.42, "brass", Vector3.ZERO, 24)
		_part(at + Vector3(-0.56, HEIGHT - 0.41, -0.56), at + Vector3(0.56, HEIGHT - 0.3, 0.56), "dark_wood")
		if present and index == 1:
			# Um pedaço do fuste se soltou
			_block(at + Vector3(0.7, 0.18, 0.3), Vector3(0.45, 0.32, 0.38), "column", Vector3(20, 40, 70))
			_block(at + Vector3(-0.6, 0.08, 0.5), Vector3(0.25, 0.15, 0.2), "rubble", Vector3(10, 10, 30))


func _build_chandelier() -> void:
	if present:
		_build_fallen_chandelier()
		return
	var c := CHANDELIER
	# A luz principal nasce dentro do lustre: as peças dele não fazem sombra no salão
	_cast_shadows = false
	_model(MODELS + "lustre_saguao.glb", Vector3(c.x, HEIGHT, c.z))
	_cast_shadows = true


## Hoje: o lustre está no chão, anéis tortos, cristais espalhados e a coroa à vista.
func _build_fallen_chandelier() -> void:
	var c := CHANDELIER
	_solid(Vector3(c.x - 1.8, 0, c.z - 0.9), Vector3(c.x + 1.8, 0.7, c.z + 0.9), "FallenChandelier")
	_solid_cylinder(Vector3(c.x, 0, c.z + 1.1), 0.6, 0.5, "ChandelierCrown")
	_torus(Vector3(c.x, 0.32, c.z), 0.92, 1.08, "brass", Vector3(14, 0, 18))
	_torus(Vector3(c.x - 0.7, 0.35, c.z - 0.2), 0.68, 0.8, "brass", Vector3(-62, 20, 0))
	_torus(Vector3(c.x + 0.8, 0.22, c.z + 0.25), 0.42, 0.52, "brass", Vector3(25, 40, 74))
	_cylinder(Vector3(c.x - 1.1, 0.12, c.z - 0.3), 0.07, 0.06, 1.0, "brass", Vector3(0, 30, 82), 10)
	_sphere(Vector3(c.x + 0.2, 0.18, c.z - 0.1), 0.26, "brass", Vector3(1, 0.6, 1))
	for i in 10:
		var angle := TAU * i / 10.0 + _random(i) * 0.4
		var at := Vector3(c.x, 0.2, c.z) + Vector3(cos(angle), 0, sin(angle)) * (0.6 + _random(i, 1.0) * 0.8)
		_block(at, Vector3(0.9, 0.025, 0.025), "brass", Vector3(_random(i, 2.0) * 60.0, -rad_to_deg(angle), _random(i, 3.0) * 50.0))
	# Cristais espalhados pelo salão
	for i in 60:
		var angle := _random(i, 4.0) * TAU
		var distance := 0.4 + pow(_random(i, 5.0), 0.7) * 3.2
		var at := Vector3(c.x + cos(angle) * distance * 1.3, 0.03, c.z + sin(angle) * distance)
		_sphere(at, 0.028 + _random(i, 6.0) * 0.02, "glass", Vector3(1, 0.6, 1))
	# A coroa de latão, na frente do monte, com a faixa gravada
	var crown := Vector3(c.x, 0, c.z + 1.1)
	_cylinder(crown, 0.62, 0.55, 0.36, "brass", Vector3(0, 0, 4), 32)
	_torus(crown + Vector3(0, 0.18, 0), 0.6, 0.66, "brass", Vector3(0, 0, 4))
	_cylinder(crown + Vector3(0, 0.36, 0), 0.4, 0.2, 0.18, "brass", Vector3(0, 0, 4), 24)
	_label("ACESO PELA PRIMEIRA VEZ\nEM 14/03/1923", crown + Vector3(0, 0.16, 0.66), 0.07, Color("#C8B07A"))
	# Buraco no teto e corrente pendurada
	_cylinder(Vector3(c.x, HEIGHT - 0.08, c.z), 0.75, 0.75, 0.1, "dark", Vector3.ZERO, 20)
	_cylinder(Vector3(c.x + 0.05, HEIGHT - 1.2, c.z), 0.03, 0.03, 1.2, "iron", Vector3(0, 0, 6), 6)
	for i in 6:
		_block(Vector3(c.x - 1.5 + i * 0.6, 0.06, c.z - 1.3 + _random(i, 7.0) * 2.6), Vector3(0.3, 0.1, 0.22), "rubble", Vector3(0, _random(i, 8.0) * 90.0, 10))


func _build_piano() -> void:
	var p := PIANO
	_solid(Vector3(p.x - 1.25, 0, p.z - 0.75), Vector3(p.x + 1.25, 1.15, p.z + 0.75), "Piano")
	var outline := PackedVector2Array([
		Vector2(-1.25, -0.75), Vector2(1.05, -0.75), Vector2(1.2, -0.62), Vector2(1.25, -0.4),
		Vector2(1.2, -0.1), Vector2(1.0, 0.08), Vector2(0.6, 0.2), Vector2(0.2, 0.42),
		Vector2(-0.2, 0.66), Vector2(-0.5, 0.75), Vector2(-1.25, 0.75),
	])
	if present:
		# Coberto por uma lona: o mesmo contorno, mais largo, caindo até perto do chão
		var cover := PackedVector2Array()
		for point in outline:
			cover.append(point * 1.07)
		_extrude(cover, 0.25, 1.12, p, 0, "tarp")
		for i in 9:
			var t := float(i) / 8.0
			var at := p + Vector3(-1.3 + t * 2.5, 0.6, -0.82)
			_block(at, Vector3(0.32, 0.8, 0.04), "tarp", Vector3(8 * (_random(i) - 0.5), 0, 6 * (_random(i, 1.0) - 0.5)))
		_block(p + Vector3(-1.34, 0.6, 0), Vector3(0.04, 0.85, 1.55), "tarp", Vector3(0, 0, -6))
		# Banco tombado
		_block(Vector3(p.x - 2.1, 0.22, p.z + 0.2), Vector3(0.45, 0.9, 0.4), "velvet", Vector3(0, 20, 90))
		return
	# Piano modelado no Blender (tools/blender/make_props.py), com a mesma planta da colisão
	_model(PIANO_MODEL, p)
	# Tampa aberta, presa no lado reto e apoiada numa vareta: a colisão segue o contorno dela
	# (a cabeça não pode atravessar). A malha só serve para tirar a forma.
	var lid := PackedVector2Array()
	for point in outline:
		lid.append(point + Vector2(0, 0.75))
	var lid_mesh := _extrude(lid, 0.0, 0.025, p + Vector3(0, 1.0, -0.75), 0, "lacquer")
	lid_mesh.rotation_degrees = Vector3(-36, 0, 0)
	var lid_body := StaticBody3D.new()
	lid_body.name = "PianoLid"
	lid_body.transform = lid_mesh.transform
	var lid_collision := CollisionShape3D.new()
	lid_collision.shape = lid_mesh.mesh.create_convex_shape()
	lid_body.add_child(lid_collision)
	_add(lid_body)
	lid_mesh.get_parent().remove_child(lid_mesh)
	lid_mesh.free()
	# Banco
	var bench := Vector3(p.x - 2.0, 0, p.z)
	_part(bench + Vector3(-0.22, 0.42, -0.45), bench + Vector3(0.22, 0.5, 0.45), "velvet")
	_part(bench + Vector3(-0.24, 0.36, -0.47), bench + Vector3(0.24, 0.42, 0.47), "lacquer")
	for leg: Vector2 in [Vector2(-0.18, -0.4), Vector2(0.18, -0.4), Vector2(-0.18, 0.4), Vector2(0.18, 0.4)]:
		_cylinder(bench + Vector3(leg.x, 0, leg.y), 0.025, 0.03, 0.36, "lacquer", Vector3.ZERO, 8)
	_solid(bench + Vector3(-0.25, 0, -0.5), bench + Vector3(0.25, 0.5, 0.5), "PianoBench")


# --- Portas e janelas --------------------------------------------------------------------

func _build_library_door() -> void:
	# A entrada pública de 1923; hoje, trancada até Lia achar a chave na manutenção.
	var x0 := LIBRARY_DOOR.x
	var x1 := LIBRARY_DOOR.y
	_model(MODELS + "porta_130x240.glb", Vector3((x0 + x1) / 2.0, 0, NORTH + 0.04), Vector3(0, 180, 0), 1.0,
		{"mahogany": "plank"} if present else {})
	for x: float in [x0 - 0.1, x1]:
		_part(Vector3(x, 0, NORTH), Vector3(x + 0.1, 2.55, NORTH + 0.13), "brass")
	_part(Vector3(x0 - 0.1, 2.4, NORTH), Vector3(x1 + 0.1, 2.57, NORTH + 0.13), "brass")
	_plaque("BIBLIOTECA", Vector3((x0 + x1) / 2.0, 2.18, NORTH + 0.14), 0.10, Color("#C9973B"))
	_door_light(Vector3((x0 + x1) / 2.0, 2.35, NORTH + 0.1), 0.0)


func _build_kitchen_door() -> void:
	var z0 := KITCHEN_DOOR.x
	var z1 := KITCHEN_DOOR.y
	var face := WEST
	# Guarnição
	_part(Vector3(face, 0, z0 - 0.15), Vector3(face + 0.07, 2.55, z0), "dark_wood")
	_part(Vector3(face, 0, z1), Vector3(face + 0.07, 2.55, z1 + 0.15), "dark_wood")
	_part(Vector3(face, 2.4, z0 - 0.15), Vector3(face + 0.09, 2.6, z1 + 0.15), "dark_wood")
	# Folha almofadada (recuada no vão), com a maçaneta do lado de z0
	_model(MODELS + "porta_150x240.glb", Vector3(face - 0.175, 0, (z0 + z1) / 2.0), Vector3(0, -90, 0), 1.0,
		{"mahogany": "plank"} if present else {})
	_part(Vector3(face - 0.15, 1.95, 7.0), Vector3(face - 0.13, 2.08, 7.5), "brass")
	_label("SERVIÇO", Vector3(face - 0.125, 2.015, 7.25), 0.08, Color("#2A1A10"), 90)
	# A folha fica recuada no vão e sumia no escuro
	_door_light(Vector3(face, 2.35, 7.25), 90.0)
	if present:
		# Cadeado de 1979 na aldrava
		_part(Vector3(face - 0.13, 1.0, z0 + 0.06), Vector3(face - 0.1, 1.1, z0 + 0.32), "iron")
		_block(Vector3(face - 0.08, 0.92, z0 + 0.2), Vector3(0.05, 0.1, 0.09), "brass")
		_torus(Vector3(face - 0.08, 0.99, z0 + 0.2), 0.022, 0.032, "iron", Vector3(0, 0, 90))


func _build_entrance() -> void:
	var x0 := ENTRANCE.x
	var x1 := ENTRANCE.y
	var mid := (x0 + x1) / 2.0
	var face := SOUTH
	_part(Vector3(x0 - 0.25, 0, face - 0.12), Vector3(x0, 4.3, face), "brass")
	_part(Vector3(x1, 0, face - 0.12), Vector3(x1 + 0.25, 4.3, face), "brass")
	_part(Vector3(x0 - 0.25, 3.0, face - 0.12), Vector3(x1 + 0.25, 3.15, face), "brass")
	_part(Vector3(x0 - 0.25, 4.2, face - 0.12), Vector3(x1 + 0.25, 4.35, face), "brass")
	# Bandeira em leque sobre a porta
	_part(Vector3(x0, 3.15, face + 0.1), Vector3(x1, 4.2, face + 0.12), "glass")
	for i in 7:
		var angle := -60.0 + 120.0 * i / 6.0
		var direction := Vector3(-sin(deg_to_rad(angle)), cos(deg_to_rad(angle)), 0)
		_block(Vector3(mid, 3.15, face + 0.08) + direction * 0.5, Vector3(0.03, 1.0, 0.03), "brass", Vector3(0, 0, angle))
	# Rua lá fora, à noite
	_part(Vector3(x0 - 2, -0.2, face + 3.5), Vector3(x1 + 2, 6, face + 3.7), "night")
	if not present:
		for x: float in [x0 - 0.8, x1 + 0.8]:
			_sphere(Vector3(x, 3.0, face + 3.2), 0.18, "street")
		# Porta giratória: tambor de vidro e quatro folhas em cruz
		# Metade do tambor entra no salão; a colisão fica na frente dele
		var center := Vector3(mid, 0, face + 0.45)
		_solid(Vector3(x0 - 0.1, 0, face - 0.55), Vector3(x1 + 0.1, 3.0, face), "RevolvingDoor")
		_cylinder(center + Vector3(0, 2.85, 0), 1.05, 1.05, 0.15, "brass", Vector3.ZERO, 32)
		_cylinder(center, 1.05, 1.05, 0.03, "brass", Vector3.ZERO, 32)
		for i in 12:
			var angle := TAU * i / 12.0
			if abs(cos(angle)) > 0.95:
				continue
			_cylinder(center + Vector3(sin(angle), 0, cos(angle)) * 1.02, 0.02, 0.02, 2.85, "brass", Vector3.ZERO, 6)
		_cylinder(center, 0.06, 0.06, 2.85, "brass", Vector3.ZERO, 10)
		for i in 4:
			var yaw := 45.0 + 90.0 * i
			var direction := Vector3(sin(deg_to_rad(yaw)), 0, cos(deg_to_rad(yaw)))
			_block(center + direction * 0.5 + Vector3(0, 1.4, 0), Vector3(0.02, 2.6, 0.95), "glass", Vector3(0, yaw + 90.0, 0))
			_block(center + direction * 0.5 + Vector3(0, 1.0, 0), Vector3(0.03, 0.04, 0.95), "brass", Vector3(0, yaw + 90.0, 0))
	else:
		# Tábuas pregadas por dentro; a corrente e o cadeado de 1979 ficam com LobbyExitPuzzle3D
		_part(Vector3(x0, 0, face + 0.15), Vector3(x1, 3.0, face + 0.2), "dark")
		for i in 6:
			var y := 0.35 + i * 0.45
			_block(Vector3(mid, y, face - 0.05), Vector3(2.4, 0.2, 0.05), "plank", Vector3(0, 0, 10.0 * (_random(i) - 0.5)))
	# Placa de bronze junto à entrada, nas duas épocas: a data de inauguração é a pista falsa
	_part(Vector3(11.5, 1.45, face - 0.03), Vector3(12.3, 1.85, face), "brass")
	_label("INAUGURADO EM\n06/09/1921", Vector3(11.9, 1.65, face - 0.035), 0.07,
		Color("#3A2A14") if not present else Color("#2E2A22"), 180.0)


func _build_windows() -> void:
	for window in WINDOWS:
		var z0 := window.x
		var z1 := window.y
		var mid := (z0 + z1) / 2.0
		var face := EAST
		# Moldura, peitoril, montante e travessa
		_part(Vector3(face - 0.1, WINDOW_SILL - 0.1, z0 - 0.15), Vector3(face, WINDOW_TOP + 0.15, z0), "dark_wood")
		_part(Vector3(face - 0.1, WINDOW_SILL - 0.1, z1), Vector3(face, WINDOW_TOP + 0.15, z1 + 0.15), "dark_wood")
		_part(Vector3(face - 0.18, WINDOW_SILL - 0.1, z0 - 0.2), Vector3(face, WINDOW_SILL, z1 + 0.2), "marble")
		_part(Vector3(face - 0.1, WINDOW_TOP, z0 - 0.15), Vector3(face, WINDOW_TOP + 0.15, z1 + 0.15), "dark_wood")
		_part(Vector3(face + 0.1, WINDOW_SILL, mid - 0.03), Vector3(face + 0.14, WINDOW_TOP, mid + 0.03), "brass" if not present else "iron")
		_part(Vector3(face + 0.1, 3.6, z0), Vector3(face + 0.14, 3.65, z1), "brass" if not present else "iron")
		for k in 3:
			var y := WINDOW_SILL + 0.6 + k * 0.6
			_part(Vector3(face + 0.1, y, z0), Vector3(face + 0.13, y + 0.02, z1), "brass" if not present else "iron")
		_part(Vector3(face + 0.14, WINDOW_SILL, z0), Vector3(face + 0.15, WINDOW_TOP, z1), "glass")
		# Lá fora: céu da noite e prédios ao longe
		_part(Vector3(face + 6, 0, z0 - 3), Vector3(face + 6.2, 9, z1 + 3), "night")
		if not present:
			# Cortinas de veludo presas nas laterais e bandô
			for z: float in [z0 - 0.35, z1 + 0.05]:
				_part(Vector3(face - 0.2, WINDOW_SILL - 0.6, z), Vector3(face - 0.12, WINDOW_TOP + 0.4, z + 0.3), "velvet")
				_torus(Vector3(face - 0.16, 2.3, z + 0.15), 0.12, 0.16, "brass", Vector3(0, 0, 90))
			_part(Vector3(face - 0.25, WINDOW_TOP + 0.2, z0 - 0.4), Vector3(face - 0.1, WINDOW_TOP + 0.55, z1 + 0.4), "velvet")
			for i in 4:
				var z := z0 - 1.5 + i * 1.2
				var height := 2.0 + _random(i, mid) * 3.0
				_part(Vector3(face + 4.5, 0, z), Vector3(face + 5.3, height, z + 0.9), "dark")
				for k in 3:
					if _random(i * 3 + k, mid) > 0.45:
						_part(Vector3(face + 4.48, 0.6 + k * 0.7, z + 0.2), Vector3(face + 4.5, 0.9 + k * 0.7, z + 0.45), "street")
		else:
			# Tábuas pregadas com frestas e cacos de vidro no chão
			for i in 5:
				var y := WINDOW_SILL + 0.35 + i * 0.68
				_block(Vector3(face - 0.04, y, mid), Vector3(0.05, 0.22, z1 - z0 + 0.4), "plank", Vector3(12.0 * (_random(i, mid) - 0.5), 0, 0))
			for i in 12:
				_block(Vector3(face - 0.4 - _random(i, mid) * 1.2, 0.01, z0 + _random(i, mid + 1.0) * (z1 - z0)), Vector3(0.12, 0.01, 0.07), "glass", Vector3(0, _random(i) * 180.0, 0))
			# Cortina rasgada caída
			_block(Vector3(face - 0.5, 0.05, z1 + 0.3), Vector3(0.8, 0.08, 0.7), "velvet", Vector3(0, 30, 4))


# --- Mobília e paredes decoradas ---------------------------------------------------------------

func _build_furniture() -> void:
	# Sala de estar oeste
	_sofa(Vector3(3.1, 0, 10.2), 180.0)
	_armchair(Vector3(1.25, 0, 9.0), 90.0, 0)
	_coffee_table(Vector3(3.1, 0, 9.15))
	_palm(Vector3(1.05, 0, 10.25), 0)
	# Leste, junto à janela: duas poltronas e mesinha com abajur
	_armchair(Vector3(18.55, 0, 3.4), -90.0, 1)
	_armchair(Vector3(18.55, 0, 5.3), -90.0, 2)
	_side_table(Vector3(18.75, 0, 4.35))
	# Palmeiras na entrada, na escada e no canto
	_palm(Vector3(8.2, 0, 10.2), 1)
	_palm(Vector3(11.8, 0, 10.2), 2)
	_palm(Vector3(5.15, 0, 2.6), 3)
	_palm(Vector3(18.95, 0, 10.2), 4)
	_grandfather_clock(Vector3(12.2, 0, NORTH))
	_luggage_cart(Vector3(13.4, 0, 9.7))


func _sofa(at: Vector3, yaw: float) -> void:
	var holder := _group(at, yaw if not present else yaw + 7.0)
	_model(MODELS + "sofa.glb", Vector3.ZERO, Vector3.ZERO, 1.0, {}, holder)
	_solid(at + Vector3(-1.1, 0, -0.5), at + Vector3(1.1, 0.95, 0.5), "Sofa")


## Poltrona; hoje, uma delas tombada de costas.
func _armchair(at: Vector3, yaw: float, index: int) -> void:
	var fallen := present and index != 2
	var holder := _group(at + (Vector3(0, 0.38, 0) if fallen else Vector3.ZERO), yaw + (25.0 * index if present else 0.0))
	if fallen:
		holder.rotation_degrees.x = -80.0
	var roles := {"velvet": "green_velvet"} if index > 0 else {}
	_model(MODELS + "poltrona.glb", Vector3.ZERO, Vector3.ZERO, 1.0, roles, holder)
	_solid(at + Vector3(-0.45, 0, -0.45), at + Vector3(0.45, 0.95, 0.45), "Armchair")


func _coffee_table(at: Vector3) -> void:
	var tilt := Vector3.ZERO if not present else Vector3(0, 12, 14)
	_block(at + Vector3(0, 0.42, 0), Vector3(1.15, 0.05, 0.6), "mahogany", tilt)
	_block(at + Vector3(0, 0.12, 0), Vector3(1.0, 0.03, 0.48), "mahogany", tilt)
	for x: float in [-0.5, 0.5]:
		for z: float in [-0.24, 0.24]:
			_block(at + Vector3(x, 0.21, z), Vector3(0.045, 0.42, 0.045), "dark_wood", tilt)
	if not present:
		_cylinder(at + Vector3(-0.25, 0.445, 0), 0.08, 0.06, 0.05, "glass")
		_part(at + Vector3(0.1, 0.445, -0.1), at + Vector3(0.38, 0.47, 0.12), "paper")
	_solid(at + Vector3(-0.58, 0, -0.3), at + Vector3(0.58, 0.45, 0.3), "Table")


func _side_table(at: Vector3) -> void:
	_cylinder(at, 0.22, 0.22, 0.03, "dark_wood")
	_cylinder(at, 0.04, 0.05, 0.62, "dark_wood")
	_cylinder(at + Vector3(0, 0.62, 0), 0.28, 0.28, 0.04, "mahogany", Vector3.ZERO, 20)
	if not present:
		_cylinder(at + Vector3(0, 0.66, 0), 0.08, 0.04, 0.3, "brass", Vector3.ZERO, 12)
		_cylinder(at + Vector3(0, 0.94, 0), 0.22, 0.12, 0.22, "velvet", Vector3.ZERO, 16)
		_sphere(at + Vector3(0, 0.98, 0), 0.06, "bulb")
		_omni(at + Vector3(0, 0.95, 0), WARM, 0.6, 3.2)
	else:
		_cylinder(at + Vector3(0.3, 0.02, 0.2), 0.22, 0.12, 0.22, "velvet", Vector3(80, 30, 0), 16)
	_solid_cylinder(at, 0.3, 0.7, "SideTable")


## Palmeira num vaso. Hoje, seca, com folhas pendendo.
func _palm(at: Vector3, index: int) -> void:
	var lean := Vector3.ZERO if not present else Vector3(6 * (_random(index) - 0.5), 0, 10 * (_random(index, 1.0) - 0.5))
	_cylinder(at, 0.24, 0.32, 0.55, "pot", lean, 16)
	_torus(at + Vector3(0, 0.55, 0), 0.28, 0.34, "brass" if not present else "pot", lean)
	_cylinder(at + Vector3(0, 0.5, 0), 0.28, 0.28, 0.03, "dark", lean, 16)
	_cylinder(at + Vector3(0, 0.5, 0), 0.05, 0.035, 1.0, "dark_wood", lean, 8)
	var fronds := 9 if not present else 5
	for i in fronds:
		var yaw := 360.0 * i / fronds + _random(i, index) * 20.0
		var droop := 0.55 + _random(i, index + 1.0) * 0.35 + (0.9 if present else 0.0)
		_frond(at + Vector3(0, 1.45, 0), yaw, droop)
	_solid_cylinder(at, 0.3, 1.2, "Palm")


## Folha de palmeira: nervura em arco (sobe e depois pende) com folíolos dos dois lados,
## menores para a ponta. `droop` é quanto a ponta cai, em metros.
func _frond(crown: Vector3, yaw_deg: float, droop: float) -> void:
	var turn := Basis.from_euler(Vector3(0, deg_to_rad(yaw_deg), 0))
	var previous := crown
	for k in range(1, FROND_STATIONS + 1):
		var t := float(k) / FROND_STATIONS
		var point := crown + turn * Vector3(0, 0.28 * sin(t * PI * 0.8) - droop * t * t, FROND_LENGTH * t)
		var span := point - previous
		var pitch := -rad_to_deg(atan2(span.y, Vector2(span.x, span.z).length()))
		_block((previous + point) / 2.0, Vector3(0.016, 0.012, span.length()), "leaf", Vector3(pitch, yaw_deg, 0))
		var leaflet := 0.3 * (1.0 - 0.6 * t)
		for side: float in [-1.0, 1.0]:
			var center := point + turn * Vector3(side * leaflet * 0.45, -leaflet * 0.22, 0)
			_block(center, Vector3(leaflet, 0.006, 0.07), "leaf", Vector3(pitch, yaw_deg, -side * 26.0))
		previous = point


func _grandfather_clock(wall: Vector3) -> void:
	if not present:
		var holder := _group(wall + Vector3(0, 0, 0.2), 0.0)
		# Em 1923 o relógio anda: marca 11h40, como a torre antes de Helena mexer
		_model(MODELS + "relogio_carrilhao_1923.glb", Vector3.ZERO, Vector3.ZERO, 1.0, {}, holder)
		_solid(wall + Vector3(-0.35, 0, 0), wall + Vector3(0.35, 2.6, 0.5), "Clock")
		return
	# Hoje tombou de lado, ao longo da parede, entre ela e o balcão (o mostrador ainda para o Saguão)
	var fallen := _group(wall + Vector3(0.34, 0.35, 0.25), 0.0)
	fallen.rotation_degrees.z = 88.0
	_model(MODELS + "relogio_carrilhao.glb", Vector3.ZERO, Vector3.ZERO, 1.0, {}, fallen)
	_solid(wall + Vector3(-2.25, 0, 0), wall + Vector3(0.36, 0.72, 0.5), "Clock")


func _luggage_cart(at: Vector3) -> void:
	var holder := _group(at + (Vector3(0, 0.3, 0) if present else Vector3.ZERO), 15.0)
	if present:
		holder.rotation_degrees.z = 72.0
	var metal := "brass"
	_child_box(holder, Vector3(0, 0.25, 0), Vector3(1.2, 0.05, 0.6), "dark_wood")
	for x: float in [-0.55, 0.55]:
		_child_box(holder, Vector3(x, 1.0, 0), Vector3(0.04, 1.5, 0.04), metal)
	_child_box(holder, Vector3(0, 1.75, 0), Vector3(1.15, 0.04, 0.04), metal)
	_child_box(holder, Vector3(0, 1.3, 0), Vector3(1.1, 0.025, 0.025), metal)
	for x: float in [-0.5, 0.5]:
		for z: float in [-0.25, 0.25]:
			var wheel := _child_cylinder(holder, Vector3(x, 0.1, z), 0.1, 0.03, "lacquer")
			wheel.rotation_degrees.x = 90.0
	var cases := [[Vector3(-0.2, 0.42, 0), Vector3(0.75, 0.3, 0.5), "velvet"], [Vector3(0.15, 0.7, 0), Vector3(0.6, 0.26, 0.42), "dark_wood"], [Vector3(-0.05, 0.92, 0), Vector3(0.4, 0.2, 0.35), "green_velvet"]]
	for piece: Array in cases:
		if present:
			continue
		_child_box(holder, piece[0], piece[1], piece[2])
	if present:
		# Malas abertas espalhadas
		_block(Vector3(at.x - 0.8, 0.12, at.z - 0.5), Vector3(0.75, 0.24, 0.5), "velvet", Vector3(0, 40, 0))
		_block(Vector3(at.x - 0.75, 0.38, at.z - 0.75), Vector3(0.75, 0.04, 0.5), "velvet", Vector3(-70, 40, 0))
		_block(Vector3(at.x + 0.6, 0.13, at.z - 0.6), Vector3(0.6, 0.26, 0.42), "dark_wood", Vector3(0, -20, 90))
	_solid(at + Vector3(-0.65, 0, -0.4), at + Vector3(0.65, 1.8, 0.4), "Cart")


func _build_wall_art() -> void:
	var walls := _walls()
	# Quadros: oeste (dois), sul (dois); arandelas entre eles
	_painting(walls[1], 6.7, 2.6, Vector2(1.3, 1.0), 0)
	_painting(walls[1], 1.3, 2.6, Vector2(1.0, 0.8), 1)
	_painting(walls[2], 15.5, 2.6, Vector2(1.4, 1.0), 2)
	_painting(walls[2], 3.8, 2.6, Vector2(1.4, 1.0), 3)
	var sconces := [[walls[0], 6.9], [walls[0], 13.0], [walls[1], 5.2], [walls[1], 1.9], [walls[2], 6.8], [walls[2], 12.2], [walls[3], 6.2]]
	for index in sconces.size():
		_sconce(sconces[index][0], sconces[index][1], index)


func _painting(wall: WallLine, s: float, height: float, size: Vector2, index: int) -> void:
	var fallen := present and index == 1
	if fallen:
		var foot := wall.point(s, 0, 0.35)
		_block(foot + Vector3(0, 0.45, 0), Vector3(size.x, size.y, 0.06), "brass", Vector3(0, 0, 0) + Vector3(-20 if wall.inward.z != 0 else 0, 90 if wall.inward.x != 0 else 0, 0))
		return
	var tilt := 0.0 if not present else 7.0 * (_random(index) - 0.5)
	var center := wall.point(s, height, 0.04)
	var angles := Vector3(0, 90 if wall.inward.x != 0 else 0, tilt)
	var frame_size := Vector3(size.x + 0.16, size.y + 0.16, 0.06)
	var canvas_size := Vector3(size.x, size.y, 0.02)
	_block(center, frame_size, "brass", angles)
	_block(center + wall.inward * 0.035, canvas_size, "painting", angles)
	if not present:
		# Luminária de quadro
		_block(wall.point(s, height + size.y / 2.0 + 0.15, 0.12), Vector3(0.4, 0.04, 0.06), "brass", angles)


func _sconce(wall: WallLine, s: float, index: int) -> void:
	var base := wall.point(s, 2.35, 0)
	_block(base + wall.inward * 0.02, Vector3(0.16, 0.3, 0.16) if wall.inward.x != 0 else Vector3(0.16, 0.3, 0.04), "brass")
	var arm := base + wall.inward * 0.18 + Vector3(0, 0.05, 0)
	_block(base + wall.inward * 0.1 + Vector3(0, 0.05, 0), Vector3(0.03, 0.03, 0.03) + wall.inward.abs() * 0.15, "brass")
	if present and index % 3 == 1:
		# Arandela arrancada: só o espelho e fios
		_block(base + wall.inward * 0.06 - Vector3(0, 0.25, 0), Vector3(0.01, 0.3, 0.01), "iron", Vector3(0, 0, 12))
		return
	_cylinder(arm + Vector3(0, 0.02, 0), 0.05, 0.04, 0.04, "brass", Vector3.ZERO, 10)
	_cylinder(arm + Vector3(0, 0.06, 0), 0.07, 0.11, 0.16, "glass" if present else "bulb", Vector3.ZERO, 12)
	if not present:
		_omni(arm + Vector3(0, 0.15, 0), WARM, 0.9, 5.5)


# --- Ruínas: detalhes que só existem hoje ---------------------------------------------------

func _build_ruin_details() -> void:
	# Trepadeiras descendo da sanca nas paredes norte e leste
	for i in 26:
		var on_north := i < 16
		var along := 0.8 + _random(i, 3.0) * 18.0 if on_north else NORTH + 0.3 + _random(i, 3.0) * 8.2
		var length := 0.8 + _random(i, 4.0) * 2.6
		var at := Vector3(along, HEIGHT - 0.35 - length / 2.0, NORTH + 0.08) if on_north else Vector3(EAST - 0.08, HEIGHT - 0.35 - length / 2.0, along)
		var size := Vector3(0.12 + _random(i, 5.0) * 0.12, length, 0.02) if on_north else Vector3(0.02, length, 0.12 + _random(i, 5.0) * 0.12)
		_block(at, size, "leaf", Vector3(0, 0, 6 * (_random(i, 6.0) - 0.5)))
	# Poças refletindo a pouca luz
	var puddle := StandardMaterial3D.new()
	puddle.albedo_color = Color(0.03, 0.04, 0.05)
	puddle.roughness = 0.02
	puddle.metallic_specular = 1.0
	for spot: Vector4 in [Vector4(7.2, 8.6, 1.4, 0.9), Vector4(13.6, 6.4, 1.1, 0.7), Vector4(3.0, 6.8, 0.9, 1.2), Vector4(17.4, 10.0, 1.0, 0.6)]:
		_part(Vector3(spot.x - spot.z / 2.0, 0.003, spot.y - spot.w / 2.0), Vector3(spot.x + spot.z / 2.0, 0.006, spot.y + spot.w / 2.0), "dark", Vector3(0, 20, 0), puddle)
	# Papéis e folhas do livro espalhados
	for i in 34:
		var at := Vector3(6.0 + _random(i, 9.0) * 8.0, 0.008 + i * 0.0003, 4.2 + _random(i, 10.0) * 5.0)
		_block(at, Vector3(0.21, 0.004, 0.29), "paper", Vector3(0, _random(i, 11.0) * 180.0, 0))
	# Montes de reboco caído junto às paredes
	for pile: Vector3 in [Vector3(0.9, 0, 3.0), Vector3(19.0, 0, 7.0), Vector3(7.5, 0, 10.3), Vector3(6.3, 0, 2.45)]:
		for k in 6:
			# Cacos assentados no chão (um pouco enterrados, sem ponta no ar)
			var size := Vector3(0.15 + _random(k, 2.0) * 0.35, 0.06 + _random(k, 3.0) * 0.12, 0.15 + _random(k, 4.0) * 0.3)
			var at := pile + Vector3((_random(k, pile.x) - 0.5) * 1.0, size.y * 0.4, (_random(k, pile.x + 1.0) - 0.5) * 0.8)
			_block(at, size, "rubble", Vector3(_random(k) * 10.0 - 5.0, _random(k, 5.0) * 180.0, 0))
	# Poeira em suspensão nos fachos de luz
	var dust := CPUParticles3D.new()
	dust.amount = 220
	dust.lifetime = 12.0
	dust.preprocess = 12.0
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	dust.emission_box_extents = Vector3(9.5, 2.8, 4.4)
	dust.position = Vector3(10, 3.0, 6.4)
	dust.gravity = Vector3(0, -0.01, 0)
	dust.initial_velocity_min = 0.02
	dust.initial_velocity_max = 0.06
	dust.direction = Vector3(0.3, 0.2, 0.1)
	dust.spread = 180.0
	var mote := QuadMesh.new()
	mote.size = Vector2(0.012, 0.012)
	var mote_material := StandardMaterial3D.new()
	mote_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	# Iluminada: a poeira só aparece onde bate luz (luar, lanterna)
	mote_material.albedo_color = Color(0.9, 0.92, 0.95, 0.6)
	mote_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mote.material = mote_material
	dust.mesh = mote
	_add(dust)


# --- Luz ------------------------------------------------------------------------------

func _build_lights() -> void:
	if present:
		# Luar entrando pelas frestas das janelas e pelo buraco do teto
		for window in WINDOWS:
			var mid := (window.x + window.y) / 2.0
			_spot(Vector3(EAST + 5.5, 7.5, mid + 1.0), Vector3(EAST - 4.0, 0, mid - 0.5), COLD, 9.0, 20.0, 18.0)
		_spot(Vector3(CHANDELIER.x, HEIGHT + 3.0, CHANDELIER.z), Vector3(CHANDELIER.x, 0, CHANDELIER.z + 0.6), COLD, 7.0, 14.0, 14.0)
		_omni(Vector3(10, 4.5, 6.5), Color("#6A7E96"), 0.6, 16.0)
	else:
		# Lustre: luz principal com sombras e um preenchimento no teto
		_omni(CHANDELIER + Vector3(0, 4.1, 0), WARM, 3.2, 15.0, true)
		_omni(CHANDELIER + Vector3(0, 5.3, 0), WARM, 0.8, 7.0)
		for x: float in [STAIR_ARCH.x + 0.06, STAIR_ARCH.y - 0.06]:
			_omni(Vector3(x, 1.45, 3.65), WARM, 0.5, 2.6)
