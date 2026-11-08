@tool
class_name KitchenRoom3D
extends HotelBuilder3D
## Cozinha e Despensa em 3D, montadas por código nas duas épocas (mesma planta).
## A Cozinha fica em cima (piso em y = 4,5) e a Despensa embaixo (piso em y = 0).
## Só o cenário fixo mora aqui; o que muda com os enigmas (porta, forno de hoje, cabine,
## fermento, gelo, fresta) são KitchenProp3D na cena, ligados às flags.
## 1923: cozinha de hotel em plena noite de serviço. Hoje: ruína escura, 100 anos depois.

## Piso da Cozinha e fundo da laje (teto da Despensa).
const K: float = 4.5
const SLAB_BOTTOM: float = 4.1
const TOP: float = 8.6
const WIDTH: float = 18.0
const DEPTH: float = 6.0
const WALL: float = 0.3
## Vão da escada na laje (x) e largura dela (z de 0 até STAIR_Z).
const STAIR_X := Vector2(1.4, 7.2)
const STAIR_Z: float = 1.4
const STEPS: int = 15
## Parede da escada (z), porta da despensa (x) e altura do vão.
const PARTITION := Vector2(1.4, 1.55)
const PANTRY_DOOR := Vector2(0.25, 1.25)
const DOOR_HEIGHT: float = 2.3
## Porta para o Saguão, na parede sul (x).
const LOBBY_DOOR := Vector2(3.0, 4.2)
## Portinhola do elevador na parede leste (z) e altura acima do piso da Cozinha: começa
## na altura do tampo da prateleira e cabe uma pessoa em pé. A grade é um KitchenProp3D.
const HATCH_Z := Vector2(0.35, 1.45)
const HATCH_Y := Vector2(1.6, 3.4)
## Poço do elevador, atrás da parede leste.
const SHAFT_X := Vector2(18.3, 20.3)
const SHAFT_Z := Vector2(0.0, 2.0)
const SHAFT_TOP: float = 11.0
const SHAFT_OPENING: float = 2.4
## Janelas altas da parede sul (x), alturas acima do piso da Cozinha.
const WINDOWS: Array[Vector2] = [Vector2(7.0, 9.0), Vector2(11.0, 13.0)]
const WINDOW_Y := Vector2(2.0, 3.2)
## Móveis da Cozinha.
const COUNTER := Vector2(7.6, 13.6)
const COUNTER_BROKEN_FROM: float = 12.6
const STOVE := Vector2(14.0, 16.0)
const DRESSER := Vector2(16.2, 17.8)
const DRESSER_TOP: float = 1.6
const TABLE := Rect2(8.0, 2.6, 3.0, 1.0)
const LAMPS: Array[float] = [4.0, 9.5, 14.0]
const LAMP_Z: float = 3.6
## Despensa: estantes (x), geladeira (x), pilares de madeira (x, z).
const SHELVES := Vector2(7.6, 12.6)
const SHELF_BOARDS: Array[float] = [0.3, 0.72, 1.14, 1.56, 1.98]
const ICEBOX := Vector2(13.0, 14.4)
const POSTS: Array[Vector2] = [Vector2(9.0, 3.2), Vector2(14.5, 3.2)]
const BEAM_Y: float = 3.85

## Modelos do Blender (tools/blender/make_props.py).
const MODELS := "res://art/models/"
## Hoje: madeira velha e ferragens enferrujadas.
const AGED := {"oak": "plank", "brass": "iron", "mahogany": "plank"}

const WARM := Color("#F2D49B")
const FIRE := Color("#FF8A3A")
const COLD := Color("#9FB4C8")


func _build_room() -> void:
	_build_shell()
	_build_partition()
	_build_stairs()
	_build_kitchen_wall_dressing()
	_build_counter()
	_build_stove_hood()
	if not present:
		_build_stove()
	_build_dresser()
	_build_table()
	_build_lobby_door()
	_build_windows()
	_build_hatch_and_controls()
	_build_shaft()
	_build_pantry_ceiling()
	_build_posts()
	_build_shelves()
	_build_icebox()
	_build_pantry_stores()
	if present:
		_build_ruin_details()
	_build_lights()


# --- Paredes, pisos e tetos -------------------------------------------------------------

## Parede que atravessa os dois andares: pedra na despensa, reboco na cozinha.
func _wall(from: Vector3, to: Vector3) -> void:
	if from.y < K:
		_part(from, Vector3(to.x, minf(to.y, K), to.z), "stone")
	if to.y > K:
		_part(Vector3(from.x, maxf(from.y, K), from.z), to, "plaster_cream")


## Laje entre os andares, sem o vão da escada: [x0, z0, x1, z1].
func _slab_rects() -> Array:
	return [
		[0.0, 0.0, STAIR_X.x, STAIR_Z],
		[STAIR_X.y, 0.0, WIDTH, STAIR_Z],
		[0.0, STAIR_Z, WIDTH, DEPTH],
	]


func _build_shell() -> void:
	var east := WIDTH
	# Despensa: piso de tábuas (passa por baixo do poço)
	var floor_rects: Array[Rect2] = [Rect2(-1, -1, SHAFT_X.y+2, DEPTH+2)]
	if present:
		# A fresta e a boca da escada ocupam o mesmo recorte, conforme a época do piso.
		floor_rects = [Rect2(-1, -1, SHAFT_X.y+2, 3.6), Rect2(-1, 3.8, SHAFT_X.y+2, DEPTH+1-3.8),
			Rect2(-1, 2.6, 12.2, 1.2), Rect2(12.3, 2.6, SHAFT_X.y+1-12.3, 1.2)]
	for rect in floor_rects:
		var low := Vector3(rect.position.x, -0.2, rect.position.y)
		var high := Vector3(rect.end.x, 0, rect.end.y)
		_part(low, high, "floorboards")
		_solid(low, high, "Floor")

	for rect: Array in _slab_rects():
		_part(Vector3(rect[0], SLAB_BOTTOM, rect[1]), Vector3(rect[2], K - 0.02, rect[3]), "plaster_cream")
		_part(Vector3(rect[0], K - 0.02, rect[1]), Vector3(rect[2], K, rect[3]), "kitchen_floor")
		_solid(Vector3(rect[0], SLAB_BOTTOM, rect[1]), Vector3(rect[2], K, rect[3]), "KitchenFloor")
	# Borda da laje vista de baixo, em volta do vão da escada
	_part(Vector3(STAIR_X.x, SLAB_BOTTOM - 0.12, STAIR_Z - 0.05), Vector3(STAIR_X.y, SLAB_BOTTOM, STAIR_Z + 0.15), "oak")

	_part(Vector3(-WALL, TOP, -WALL), Vector3(east + WALL, TOP + 0.3, DEPTH + WALL), "ceiling")
	_solid(Vector3(-WALL, TOP, -WALL), Vector3(east + WALL, TOP + 0.3, DEPTH + WALL), "Ceiling")

	# Norte e oeste: inteiras, nos dois andares
	_wall(Vector3(-WALL, 0, -WALL), Vector3(SHAFT_X.y + WALL, TOP, 0))
	_solid(Vector3(-WALL, 0, -WALL), Vector3(SHAFT_X.y + WALL, SHAFT_TOP, 0), "WallNorth")
	_wall(Vector3(-WALL, 0, 0), Vector3(0, TOP, DEPTH))
	_solid(Vector3(-WALL, 0, 0), Vector3(0, TOP, DEPTH), "WallWest")

	# Sul: despensa inteira; na cozinha, a porta do Saguão e duas janelas altas
	var south := DEPTH
	_wall(Vector3(-WALL, 0, south), Vector3(east + WALL, K, south + WALL))
	var x := -WALL
	for gap: Vector2 in [LOBBY_DOOR]:
		_wall(Vector3(x, K, south), Vector3(gap.x, TOP, south + WALL))
		_wall(Vector3(gap.x, K + 2.4, south), Vector3(gap.y, TOP, south + WALL))
		x = gap.y
	for window in WINDOWS:
		_wall(Vector3(x, K, south), Vector3(window.x, TOP, south + WALL))
		_wall(Vector3(window.x, K, south), Vector3(window.y, K + WINDOW_Y.x, south + WALL))
		_wall(Vector3(window.x, K + WINDOW_Y.y, south), Vector3(window.y, TOP, south + WALL))
		x = window.y
	_wall(Vector3(x, K, south), Vector3(east + WALL, TOP, south + WALL))
	_solid(Vector3(-WALL, 0, south), Vector3(east + WALL, K, south + WALL), "WallSouth")
	_solid(Vector3(-WALL, K, south), Vector3(LOBBY_DOOR.x, TOP, south + WALL), "WallSouth")
	_solid(Vector3(LOBBY_DOOR.y, K, south), Vector3(east + WALL, TOP, south + WALL), "WallSouth")
	_solid(Vector3(LOBBY_DOOR.x, K + 2.4, south), Vector3(LOBBY_DOOR.y, TOP, south + WALL), "WallSouth")

	# Leste: na despensa, a boca do poço embaixo; na cozinha, a portinhola
	_wall(Vector3(east, 0, SHAFT_Z.y), Vector3(east + WALL, TOP, DEPTH))
	_wall(Vector3(east, SHAFT_OPENING, 0), Vector3(east + WALL, K, SHAFT_Z.y))
	_wall(Vector3(east, K, 0), Vector3(east + WALL, TOP, HATCH_Z.x))
	_wall(Vector3(east, K, HATCH_Z.y), Vector3(east + WALL, TOP, SHAFT_Z.y))
	_wall(Vector3(east, K, HATCH_Z.x), Vector3(east + WALL, K + HATCH_Y.x, HATCH_Z.y))
	_wall(Vector3(east, K + HATCH_Y.y, HATCH_Z.x), Vector3(east + WALL, TOP, HATCH_Z.y))
	_solid(Vector3(east, 0, SHAFT_Z.y), Vector3(east + WALL, TOP, DEPTH), "WallEast")
	_solid(Vector3(east, SHAFT_OPENING, 0), Vector3(east + WALL, K, SHAFT_Z.y), "WallEast")
	_solid(Vector3(east, K, 0), Vector3(east + WALL, TOP, HATCH_Z.x), "WallEast")
	_solid(Vector3(east, K, HATCH_Z.y), Vector3(east + WALL, TOP, SHAFT_Z.y), "WallEast")
	_solid(Vector3(east, K, HATCH_Z.x), Vector3(east + WALL, K + HATCH_Y.x, HATCH_Z.y), "WallEast")
	_solid(Vector3(east, K + HATCH_Y.y, HATCH_Z.x), Vector3(east + WALL, TOP, HATCH_Z.y), "WallEast")


## Parede da escada: separa a cozinha do vão, com a porta da despensa a oeste.
func _build_partition() -> void:
	var z0 := PARTITION.x
	var z1 := PARTITION.y
	_part(Vector3(0, K, z0), Vector3(PANTRY_DOOR.x, TOP, z1), "plaster_cream")
	_part(Vector3(PANTRY_DOOR.y, K, z0), Vector3(STAIR_X.y, TOP, z1), "plaster_cream")
	_part(Vector3(PANTRY_DOOR.x, K + DOOR_HEIGHT, z0), Vector3(PANTRY_DOOR.y, TOP, z1), "plaster_cream")
	_part(Vector3(STAIR_X.y, K, 0), Vector3(STAIR_X.y + 0.15, TOP, z1), "plaster_cream")
	_solid(Vector3(0, K, z0), Vector3(PANTRY_DOOR.x, TOP, z1), "Partition")
	_solid(Vector3(PANTRY_DOOR.y, K, z0), Vector3(STAIR_X.y + 0.15, TOP, z1), "Partition")
	_solid(Vector3(PANTRY_DOOR.x, K + DOOR_HEIGHT, z0), Vector3(PANTRY_DOOR.y, TOP, z1), "Partition")
	_solid(Vector3(STAIR_X.y, K, 0), Vector3(STAIR_X.y + 0.15, TOP, z1), "Partition")
	# Azulejo do lado da cozinha e guarnição da porta
	_part(Vector3(0, K, z1), Vector3(PANTRY_DOOR.x, K + 1.5, z1 + 0.02), "tile")
	_part(Vector3(PANTRY_DOOR.y, K, z1), Vector3(STAIR_X.y + 0.15, K + 1.5, z1 + 0.02), "tile")
	_part(Vector3(0, K + 1.5, z1), Vector3(PANTRY_DOOR.x, K + 1.56, z1 + 0.04), "dark_wood")
	_part(Vector3(PANTRY_DOOR.y, K + 1.5, z1), Vector3(STAIR_X.y + 0.15, K + 1.56, z1 + 0.04), "dark_wood")
	_part(Vector3(PANTRY_DOOR.x - 0.1, K, z1), Vector3(PANTRY_DOOR.x, K + DOOR_HEIGHT + 0.1, z1 + 0.06), "dark_wood")
	_part(Vector3(PANTRY_DOOR.y, K, z1), Vector3(PANTRY_DOOR.y + 0.1, K + DOOR_HEIGHT + 0.1, z1 + 0.06), "dark_wood")
	_part(Vector3(PANTRY_DOOR.x - 0.1, K + DOOR_HEIGHT, z1), Vector3(PANTRY_DOOR.y + 0.1, K + DOOR_HEIGHT + 0.12, z1 + 0.07), "dark_wood")
	_label("DESPENSA", Vector3((PANTRY_DOOR.x + PANTRY_DOOR.y) / 2.0, K + DOOR_HEIGHT + 0.25, z1 + 0.03), 0.09, Color("#3A2A1A") if not present else Color("#2A2A26"))
	# Corrimão na parede norte, ao longo da escada
	var length := Vector2(STAIR_X.y - STAIR_X.x, K).length()
	var angle := rad_to_deg(atan2(K, STAIR_X.y - STAIR_X.x))
	if not present:
		var mid := Vector3((STAIR_X.x + STAIR_X.y) / 2.0, K / 2.0 + 0.9, 0.08)
		_block(mid, Vector3(length, 0.06, 0.06), "brass", Vector3(0, 0, -angle))


## 1923: escada de madeira descendo para leste, com rampa invisível por baixo dos degraus.
## Hoje: só os degraus de cima resistem; o resto caiu num monte de escombros.
func _build_stairs() -> void:
	var run := (STAIR_X.y - STAIR_X.x) / STEPS
	var rise := K / STEPS
	var kept := STEPS if not present else 5
	for i in STEPS:
		var x0 := STAIR_X.x + i * run
		var top := K - (i + 0.5) * rise
		if i < kept:
			var sag := 0.0 if not present else _random(i) * 4.0
			_part(Vector3(x0, top - 0.05, 0.05), Vector3(x0 + run + 0.03, top, STAIR_Z - 0.02), "oak", Vector3(sag, 0, 0))
			_part(Vector3(x0, top - rise, 0.07), Vector3(x0 + 0.03, top, STAIR_Z - 0.04), "dark_wood")
	# Longarinas inclinadas
	var angle := rad_to_deg(atan2(K, STAIR_X.y - STAIR_X.x))
	var length := Vector2(STAIR_X.y - STAIR_X.x, K).length()
	for z: float in [0.08, STAIR_Z - 0.06]:
		if not present:
			_block(Vector3((STAIR_X.x + STAIR_X.y) / 2.0, K / 2.0 - 0.25, z), Vector3(length, 0.3, 0.06), "dark_wood", Vector3(0, 0, -angle))
		else:
			var short := length * 0.38
			var start := Vector2(STAIR_X.x, K)
			var dir := Vector2(STAIR_X.y - STAIR_X.x, -K).normalized()
			var center := start + dir * short / 2.0
			_block(Vector3(center.x, center.y - 0.25, z), Vector3(short, 0.3, 0.06), "dark_wood", Vector3(0, 0, -angle))

	if not present:
		# Rampa invisível que segue a linha dos degraus
		var a := atan2(K, STAIR_X.y - STAIR_X.x)
		var mid := Vector3((STAIR_X.x + STAIR_X.y) / 2.0, K / 2.0, STAIR_Z / 2.0)
		var up := Vector3(sin(a), cos(a), 0)
		var down := Vector3(cos(a), -sin(a), 0)
		# Só passa da linha embaixo (entra no piso): em cima, uma quina acima do patamar
		# vira parede para a cápsula
		var center := mid - up * 0.1 + down * 0.15
		var size := Vector3(length + 0.3, 0.2, STAIR_Z)
		var ramp := _solid(center - size / 2.0, center + size / 2.0, "Stairs")
		ramp.rotation.z = -a
	else:
		# Escombros da escada, embaixo; e o vão da porta entupido em cima
		for i in 14:
			var at := Vector3(4.2 + _random(i) * 3.2, 0.12 + _random(i, 1.0) * 0.25, 0.2 + _random(i, 2.0) * 1.0)
			_block(at, Vector3(0.9 + _random(i, 3.0) * 0.8, 0.06, 0.22), "plank" if i % 3 else "oak", Vector3(_random(i, 4.0) * 40.0 - 20.0, _random(i, 5.0) * 180.0, _random(i, 6.0) * 50.0 - 25.0))
		for i in 6:
			_block(Vector3(4.6 + _random(i, 7.0) * 2.4, 0.15, 0.3 + _random(i, 8.0) * 0.9), Vector3(0.5, 0.3, 0.4), "rubble", Vector3(0, _random(i, 9.0) * 90.0, 0))
		_solid(Vector3(4.2, 0, 0.1), Vector3(7.6, 0.45, 1.4), "StairsRubble")
		for i in 8:
			var at := Vector3(PANTRY_DOOR.x + 0.1 + _random(i, 10.0) * 0.8, K + 0.15 + _random(i, 11.0) * 1.6, PARTITION.x + _random(i, 12.0) * 0.4)
			_block(at, Vector3(0.4, 0.3 + _random(i, 13.0) * 0.3, 0.35), "rubble" if i % 2 else "plank", Vector3(_random(i, 14.0) * 40.0, _random(i, 15.0) * 90.0, _random(i, 16.0) * 40.0))
		_solid(Vector3(PANTRY_DOOR.x, K, PARTITION.x - 0.2), Vector3(PANTRY_DOOR.y, K + DOOR_HEIGHT, PARTITION.y + 0.3), "DoorRubble")


func _build_kitchen_wall_dressing() -> void:
	# Azulejo até 1,5 m e uma régua de madeira por cima, nas quatro paredes da cozinha
	var tile_top := K + 1.5
	# O trecho do fogão é revestido uma única vez pela coifa. Sobrepor os dois
	# painéis deixava faces coincidentes com a régua de madeira (cintilação).
	for span: Vector2 in [Vector2(STAIR_X.y + 0.15, STOVE.x - 0.1), Vector2(STOVE.y + 0.1, WIDTH)]:
		_part(Vector3(span.x, K, 0), Vector3(span.y, tile_top, 0.02), "tile")
	_part(Vector3(STAIR_X.y + 0.15, tile_top, 0), Vector3(WIDTH, tile_top + 0.06, 0.04), "dark_wood")
	_part(Vector3(0, K, PARTITION.y), Vector3(0.02, tile_top, DEPTH), "tile")
	_part(Vector3(0, tile_top, PARTITION.y), Vector3(0.04, tile_top + 0.06, DEPTH), "dark_wood")
	for span: Vector2 in [Vector2(0, LOBBY_DOOR.x), Vector2(LOBBY_DOOR.y, WIDTH)]:
		_part(Vector3(span.x, K, DEPTH - 0.02), Vector3(span.y, tile_top, DEPTH), "tile")
		_part(Vector3(span.x, tile_top, DEPTH - 0.04), Vector3(span.y, tile_top + 0.06, DEPTH), "dark_wood")
	_part(Vector3(WIDTH - 0.02, K, SHAFT_Z.y), Vector3(WIDTH, tile_top, DEPTH), "tile")
	_part(Vector3(WIDTH - 0.04, tile_top, SHAFT_Z.y), Vector3(WIDTH, tile_top + 0.06, DEPTH), "dark_wood")
	_part(Vector3(WIDTH - 0.02, K, 0), Vector3(WIDTH, tile_top, SHAFT_Z.y), "tile")
	# Rodapé escuro
	_part(Vector3(STAIR_X.y + 0.15, K, 0), Vector3(WIDTH, K + 0.12, 0.03), "cast_iron")
	_part(Vector3(0, K, DEPTH - 0.03), Vector3(LOBBY_DOOR.x, K + 0.12, DEPTH), "cast_iron")
	_part(Vector3(LOBBY_DOOR.y, K, DEPTH - 0.03), Vector3(WIDTH, K + 0.12, DEPTH), "cast_iron")
	# Teto: vigas aparentes
	for i in 7:
		var x := 1.25 + i * 2.6
		_part(Vector3(x, TOP - 0.25, 0), Vector3(x + 0.22, TOP, DEPTH), "dark_wood")

	# Parede oeste: barra de utensílios com panelas de cobre penduradas
	_part(Vector3(0.02, K + 1.85, 2.6), Vector3(0.06, K + 1.88, 5.4), "brass")
	for i in 6:
		var z := 2.85 + i * 0.48
		var radius := 0.1 + _random(i) * 0.08
		var hang := K + 1.62 - radius
		if present and i % 2 == 1:
			# Caídas no chão, amassadas
			# Caiu e ficou de lado, achatada contra o rodapé
			_cylinder(Vector3(0.05 + radius, K, z), radius, radius, 0.05, "copper", Vector3.ZERO, 12)
			continue
		_cylinder(Vector3(0.09, K + 1.86 - 0.2, z), 0.006, 0.006, 0.2, "brass", Vector3.ZERO, 4)
		_cylinder(Vector3(0.12 + radius, hang, z), radius, radius, 0.22, "copper", Vector3(0, 0, 8.0 if present else 0.0), 14)
		_block(Vector3(0.12 + radius * 2.0 + 0.12, hang + 0.15, z), Vector3(0.24, 0.025, 0.035), "copper")

	# Relógio de parede acima da porta do Saguão
	var clock_at := Vector3((LOBBY_DOOR.x + LOBBY_DOOR.y) / 2.0, K + 2.9, DEPTH - 0.04)
	_cylinder(clock_at, 0.22, 0.22, 0.05, "dark_wood", Vector3(90, 0, 0), 20)
	_cylinder(clock_at + Vector3(0, 0, -0.05), 0.19, 0.19, 0.01, "ivory", Vector3(90, 0, 0), 20)
	var hands := 0.0 if not present else 47.0
	_block(clock_at + Vector3(0.04, 0.03, -0.065), Vector3(0.1, 0.012, 0.005), "lacquer", Vector3(0, 0, 35 + hands))
	_block(clock_at + Vector3(0.0, 0.07, -0.068), Vector3(0.01, 0.15, 0.005), "lacquer", Vector3(0, 0, -10 + hands))


# --- Móveis da cozinha --------------------------------------------------------------------

## Bancada com pia ao longo da parede norte (hoje desabou na ponta leste).
func _build_counter() -> void:
	var x1 := COUNTER.y if not present else COUNTER_BROKEN_FROM
	_part(Vector3(COUNTER.x, K, 0), Vector3(x1, K + 0.08, 0.62), "cast_iron")
	_part(Vector3(COUNTER.x, K + 0.08, 0), Vector3(x1, K + 0.82, 0.66), "oak")
	var doors := int((x1 - COUNTER.x) / 0.75)
	for i in doors:
		var dx := COUNTER.x + 0.06 + i * 0.75
		_model(MODELS + "porta_armario.glb", Vector3(dx, K + 0.16, 0.66), Vector3.ZERO, 1.0, AGED if present else {})
	_part(Vector3(COUNTER.x - 0.02, K + 0.82, 0), Vector3(x1 + 0.02, K + 0.9, 0.72), "marble")
	_solid(Vector3(COUNTER.x, K, 0), Vector3(x1, K + 0.9, 0.72), "Counter")
	# Pia de louça com torneiras de latão
	var sink := Vector2(9.6, 10.7)
	_part(Vector3(sink.x, K + 0.9, 0.08), Vector3(sink.y, K + 0.96, 0.62), "enamel")
	_part(Vector3(sink.x + 0.06, K + 0.9, 0.14), Vector3(sink.y - 0.06, K + 0.962, 0.56), "dark")
	for x: float in [sink.x + 0.35, sink.y - 0.35]:
		_cylinder(Vector3(x, K + 0.96, 0.05), 0.018, 0.018, 0.28, "brass", Vector3.ZERO, 8)
		_cylinder(Vector3(x, K + 1.22, 0.05), 0.014, 0.014, 0.16, "brass", Vector3(90, 0, 0), 8)
		_sphere(Vector3(x, K + 1.26, 0.05), 0.03, "brass")
	# Respaldo e prateleira de pratos acima da bancada (a oeste do papel de hoje)
	_part(Vector3(COUNTER.x, K + 1.9, 0), Vector3(10.6, K + 1.94, 0.3), "oak")
	for x: float in [COUNTER.x + 0.05, 10.55]:
		_part(Vector3(x - 0.03, K + 1.7, 0), Vector3(x + 0.03, K + 1.94, 0.28), "oak")
	var plates := 9 if not present else 4
	for i in plates:
		var px := COUNTER.x + 0.3 + i * 0.3
		_cylinder(Vector3(px, K + 1.94 + 0.12, 0.08), 0.12, 0.12, 0.015, "enamel", Vector3(-80, 0, 0), 16)
	# Panelas e tábuas sobre a bancada
	if not present:
		_cylinder(Vector3(8.2, K + 0.9, 0.35), 0.18, 0.18, 0.2, "copper", Vector3.ZERO, 16)
		_cylinder(Vector3(8.75, K + 0.9, 0.3), 0.12, 0.1, 0.26, "enamel", Vector3.ZERO, 12)
		_part(Vector3(11.2, K + 0.9, 0.15), Vector3(11.8, K + 0.93, 0.5), "oak")
		_sphere(Vector3(11.5, K + 0.98, 0.32), 0.07, "ham", Vector3(1.6, 0.6, 1))
		_cylinder(Vector3(12.4, K + 0.9, 0.3), 0.09, 0.08, 0.3, "glass", Vector3.ZERO, 12)
		_cylinder(Vector3(13.0, K + 0.9, 0.35), 0.15, 0.15, 0.12, "copper", Vector3.ZERO, 14)
	else:
		# A ponta leste ruiu: tampo partido, gavetas e louça no chão
		_part(Vector3(COUNTER_BROKEN_FROM, K, 0.05), Vector3(COUNTER.y, K + 0.08, 0.6), "rubble", Vector3(0, 0, 4))
		_part(Vector3(COUNTER_BROKEN_FROM - 0.05, K + 0.05, 0.0), Vector3(COUNTER.y - 0.2, K + 0.12, 0.7), "marble", Vector3(8, 6, -14))
		for i in 6:
			_block(Vector3(COUNTER_BROKEN_FROM + _random(i) * 1.0, K + 0.1, 0.2 + _random(i, 1.0) * 0.6), Vector3(0.3, 0.12, 0.25), "oak" if i % 2 else "rubble", Vector3(_random(i, 2.0) * 30.0, _random(i, 3.0) * 90.0, _random(i, 4.0) * 30.0))
		_solid(Vector3(COUNTER_BROKEN_FROM, K, 0), Vector3(COUNTER.y, K + 0.28, 0.72), "CounterRubble")
		_cylinder(Vector3(9.0, K + 0.9, 0.35), 0.12, 0.1, 0.22, "enamel", Vector3(0, 0, 70), 12)


## Coifa de cobre e chaminé sobre o fogão (resistem nas duas épocas, fora do alcance).
func _build_stove_hood() -> void:
	var y0 := K + 3.4
	_part(Vector3(STOVE.x - 0.15, y0, 0), Vector3(STOVE.y + 0.15, y0 + 0.12, 1.1), "copper")
	_part(Vector3(STOVE.x + 0.1, y0 + 0.12, 0), Vector3(STOVE.y - 0.1, y0 + 0.45, 0.8), "copper")
	_part(Vector3(STOVE.x + 0.5, y0 + 0.45, 0), Vector3(STOVE.y - 0.5, y0 + 0.62, 0.5), "copper")
	_cylinder(Vector3((STOVE.x + STOVE.y) / 2.0, y0 + 0.62, 0.25), 0.16, 0.16, TOP - y0 - 0.62, "cast_iron", Vector3.ZERO, 12)
	_part(Vector3(STOVE.x - 0.15, y0 - 0.03, 1.06), Vector3(STOVE.y + 0.15, y0, 1.1), "brass")
	_solid(Vector3(STOVE.x - 0.15, y0, 0), Vector3(STOVE.y + 0.15, y0 + 0.12, 1.1), "HoodRim")
	_solid(Vector3(STOVE.x + 0.1, y0 + 0.12, 0), Vector3(STOVE.y - 0.1, y0 + 0.45, 0.8), "HoodBody")
	# Azulejo atrás do fogão
	# Mesmo plano dos demais azulejos; a régua fica 2 cm à frente, sem disputar profundidade.
	_part(Vector3(STOVE.x - 0.1, K, 0), Vector3(STOVE.y + 0.1, y0, 0.02), "tile")


## Fogão a lenha de ferro (1923, modelo do Blender): forno aberto à esquerda, chapas e panelas em cima.
## Hoje o fogão é um KitchenProp3D (desabado ou selado pela massa), na cena.
func _build_stove() -> void:
	var x0 := STOVE.x
	var x1 := STOVE.y
	var h := 0.85
	_model(MODELS + "fogao_lenha.glb", Vector3(x0, K, 0))
	_solid(Vector3(x0, K, 0), Vector3(x1, K + h, 1.0), "Stove")


## Aparador alto no canto (1923, com louça) que hoje é a prateleira quebrada.
func _build_dresser() -> void:
	var x0 := DRESSER.x
	var x1 := DRESSER.y
	var top := K + DRESSER_TOP
	_solid(Vector3(x0, K, 0), Vector3(x1, top, 0.6), "Dresser")
	if not present:
		_part(Vector3(x0, K, 0), Vector3(x1, K + 0.85, 0.58), "oak")
		for i in 2:
			var dx := x0 + 0.06 + i * 0.78
			_part(Vector3(dx, K + 0.1, 0.58), Vector3(dx + 0.7, K + 0.78, 0.6), "panel")
			_sphere(Vector3(dx + 0.35, K + 0.62, 0.62), 0.02, "brass")
		_part(Vector3(x0, K + 0.85, 0), Vector3(x1, K + 0.88, 0.4), "oak")
		for x: float in [x0, x1 - 0.05]:
			_part(Vector3(x, K + 0.88, 0), Vector3(x + 0.05, top, 0.4), "oak")
		for y: float in [K + 1.22, top - 0.04]:
			_part(Vector3(x0, y, 0), Vector3(x1, y + 0.04, 0.4), "oak")
		for i in 5:
			_cylinder(Vector3(x0 + 0.25 + i * 0.28, K + 1.26 + 0.13, 0.12), 0.13, 0.13, 0.015, "enamel", Vector3(-75, 0, 0), 16)
		for i in 4:
			_cylinder(Vector3(x0 + 0.25 + i * 0.36, K + 0.88, 0.22), 0.07, 0.06, 0.14, "enamel", Vector3.ZERO, 12)
	else:
		# Corpo apodrecido, portas caídas, tábua de cima torta mas firme
		_part(Vector3(x0, K, 0), Vector3(x1, K + 0.8, 0.58), "plank")
		_part(Vector3(x0 + 0.1, K, 0.62), Vector3(x0 + 0.8, K + 0.04, 1.3), "plank", Vector3(0, 12, 0))
		for x: float in [x0, x1 - 0.06]:
			_part(Vector3(x, K + 0.8, 0), Vector3(x + 0.06, top, 0.55), "plank", Vector3(0, 0, 3))
		_part(Vector3(x0 - 0.05, top - 0.06, 0), Vector3(x1 + 0.05, top, 0.6), "plank", Vector3(0, 0, -2))
		_part(Vector3(x0, K + 1.12, 0), Vector3(x1 - 0.4, K + 1.16, 0.4), "plank", Vector3(0, 0, -18))
		for i in 6:
			_block(Vector3(x0 + _random(i) * 1.6, K + 0.02, 0.8 + _random(i, 1.0) * 0.6), Vector3(0.12, 0.01, 0.08), "enamel", Vector3(0, _random(i, 2.0) * 180.0, 0))


func _build_table() -> void:
	var x0 := TABLE.position.x
	var z0 := TABLE.position.y
	var x1 := TABLE.end.x
	var z1 := TABLE.end.y
	if not present:
		_part(Vector3(x0, K + 0.84, z0), Vector3(x1, K + 0.9, z1), "oak")
		for x: float in [x0 + 0.08, x1 - 0.08]:
			for z: float in [z0 + 0.08, z1 - 0.08]:
				_part(Vector3(x - 0.05, K, z - 0.05), Vector3(x + 0.05, K + 0.84, z + 0.05), "dark_wood")
		_part(Vector3(x0 + 0.1, K + 0.15, z0 + 0.1), Vector3(x1 - 0.1, K + 0.19, z1 - 0.1), "dark_wood")
		# Preparo do pão: farinha, tigelas, rolo e pães
		_sphere(Vector3(x0 + 0.5, K + 0.92, z0 + 0.5), 0.3, "flour", Vector3(1, 0.08, 1))
		_cylinder(Vector3(x0 + 1.1, K + 0.9, z0 + 0.45), 0.2, 0.14, 0.14, "enamel", Vector3.ZERO, 16)
		_sphere(Vector3(x0 + 1.1, K + 1.02, z0 + 0.45), 0.13, "dough", Vector3(1, 0.5, 1))
		_cylinder(Vector3(x0 + 1.6, K + 0.93, z0 + 0.3), 0.03, 0.03, 0.45, "oak", Vector3(0, 30, 90), 10)
		for i in 3:
			_sphere(Vector3(x0 + 2.1 + i * 0.25, K + 0.95, z0 + 0.6), 0.1, "dough", Vector3(1.6, 0.6, 0.9))
		_cylinder(Vector3(x0 + 2.6, K + 0.9, z0 + 0.25), 0.07, 0.06, 0.2, "copper", Vector3.ZERO, 12)
		_sphere(Vector3(x0 + 0.4, K + 0.25, z0 + 0.5), 0.22, "flour", Vector3(1, 1.3, 0.9))
		_solid(Vector3(x0, K, z0), Vector3(x1, K + 0.9, z1), "Table")
	else:
		# Uma perna cedeu: o tampo desceu até o chão de um lado
		_part(Vector3(x0, K + 0.3, z0), Vector3(x1, K + 0.36, z1), "plank", Vector3(0, 0, 14))
		for x: float in [x1 - 0.08]:
			for z: float in [z0 + 0.08, z1 - 0.08]:
				_part(Vector3(x - 0.05, K, z - 0.05), Vector3(x + 0.05, K + 0.66, z + 0.05), "plank")
		_part(Vector3(x0 + 0.2, K, z0 - 0.3), Vector3(x0 + 1.0, K + 0.08, z0 - 0.2), "plank", Vector3(0, 30, 0))
		_cylinder(Vector3(x0 + 1.2, K, z1 + 0.3), 0.2, 0.14, 0.14, "enamel", Vector3(90, 20, 0), 16)
		_solid_cylinder(Vector3(x0 + 1.2, K, z1 + 0.25), 0.22, 0.3, "Bowl")
		# A colisão segue o tampo inclinado, do chão até a perna que restou
		var top := _solid(Vector3(x0, K + 0.3, z0), Vector3(x1, K + 0.36, z1), "Table")
		top.rotation_degrees.z = 14.0
		_solid(Vector3(x1 - 0.3, K, z0), Vector3(x1, K + 0.66, z1), "Table")


func _build_lobby_door() -> void:
	var x0 := LOBBY_DOOR.x
	var x1 := LOBBY_DOOR.y
	var face := DEPTH
	_part(Vector3(x0 - 0.12, K, face - 0.06), Vector3(x0, K + 2.5, face), "dark_wood")
	_part(Vector3(x1, K, face - 0.06), Vector3(x1 + 0.12, K + 2.5, face), "dark_wood")
	_part(Vector3(x0 - 0.12, K + 2.4, face - 0.08), Vector3(x1 + 0.12, K + 2.55, face), "dark_wood")
	# Porta vaivém de serviço, com visor redondo
	_model(MODELS + "porta_vaivem_120x238.glb", Vector3((x0 + x1) / 2.0, K, face + 0.145), Vector3.ZERO, 1.0,
		{"mahogany": "plank"} if present else {})
	_label("SAGUÃO", Vector3((x0 + x1) / 2.0, K + 2.68, face - 0.01), 0.09, Color("#3A2A1A") if not present else Color("#2A2A26"), 180)
	_solid(Vector3(x0, K, face + 0.1), Vector3(x1, K + 2.4, face + 0.2), "LobbyDoor")


func _build_windows() -> void:
	for window in WINDOWS:
		var y0 := K + WINDOW_Y.x
		var y1 := K + WINDOW_Y.y
		_part(Vector3(window.x, y0 - 0.05, DEPTH - 0.08), Vector3(window.y, y0, DEPTH + 0.05), "dark_wood")
		_part(Vector3(window.x - 0.06, y0, DEPTH - 0.04), Vector3(window.x, y1, DEPTH + 0.05), "dark_wood")
		_part(Vector3(window.y, y0, DEPTH - 0.04), Vector3(window.y + 0.06, y1, DEPTH + 0.05), "dark_wood")
		_part(Vector3(window.x - 0.06, y1, DEPTH - 0.04), Vector3(window.y + 0.06, y1 + 0.06, DEPTH + 0.05), "dark_wood")
		var mid := (window.x + window.y) / 2.0
		_part(Vector3(mid - 0.025, y0, DEPTH + 0.1), Vector3(mid + 0.025, y1, DEPTH + 0.14), "dark_wood")
		_part(Vector3(window.x, (y0 + y1) / 2.0 - 0.02, DEPTH + 0.1), Vector3(window.y, (y0 + y1) / 2.0 + 0.02, DEPTH + 0.14), "dark_wood")
		if not present:
			_part(Vector3(window.x, y0, DEPTH + 0.14), Vector3(window.y, y1, DEPTH + 0.15), "glass")
		else:
			# Vidro partido: só cacos presos no caixilho
			_part(Vector3(window.x, y0, DEPTH + 0.14), Vector3(mid, (y0 + y1) / 2.0, DEPTH + 0.15), "glass")
			_extrude(PackedVector2Array([Vector2(0, 0), Vector2(0.8, 0), Vector2(0, 0.5)]), 0, 0.01, Vector3(mid + 0.02, y1 - 0.02, DEPTH + 0.14), 0, "glass").rotation_degrees = Vector3(90, 0, 0)
		_part(Vector3(window.x - 1.0, K + 0.5, DEPTH + 2.0), Vector3(window.y + 1.0, TOP + 2.0, DEPTH + 2.05), "night")


## Portinhola do elevador de serviço e o painel com alavanca e freio, na parede leste.
func _build_hatch_and_controls() -> void:
	var face := WIDTH
	var y0 := K + HATCH_Y.x
	var y1 := K + HATCH_Y.y
	var frame := "brass" if not present else "iron"
	_part(Vector3(face - 0.05, y0 - 0.06, HATCH_Z.x - 0.06), Vector3(face, y0, HATCH_Z.y + 0.06), frame)
	_part(Vector3(face - 0.05, y1, HATCH_Z.x - 0.06), Vector3(face, y1 + 0.06, HATCH_Z.y + 0.06), frame)
	_part(Vector3(face - 0.05, y0, HATCH_Z.x - 0.06), Vector3(face, y1, HATCH_Z.x), frame)
	_part(Vector3(face - 0.05, y0, HATCH_Z.y), Vector3(face, y1, HATCH_Z.y + 0.06), frame)
	# Peitoril no nível do tampo da prateleira (o vão atravessa a parede inteira)
	_part(Vector3(face - 0.04, y0 - 0.04, HATCH_Z.x), Vector3(face + WALL, y0, HATCH_Z.y), frame)
	for z: float in [HATCH_Z.x, HATCH_Z.y]:
		_part(Vector3(face, y0, z - 0.01), Vector3(face + WALL, y1, z + 0.01), "stone")
	_part(Vector3(face, y1 - 0.01, HATCH_Z.x), Vector3(face + WALL, y1, HATCH_Z.y), "stone")
	# Placa sobre o painel de controle
	var plate := Vector3(face - 0.06, K + 1.85, 2.675)
	_part(plate - Vector3(0, 0.08, 0.6), plate + Vector3(0.04, 0.08, 0.6), frame)
	_label("ELEVADOR DE SERVIÇO", plate + Vector3(-0.005, 0, 0), 0.05, Color("#2A1A10"), -90)

	# Painel de controle: a alavanca (z = 2,4) e o freio (z = 2,95)
	var panel_y := K + 1.2
	_part(Vector3(face - 0.04, panel_y - 0.35, 2.1), Vector3(face, panel_y + 0.4, 3.25), frame)
	_part(Vector3(face - 0.045, panel_y - 0.3, 2.15), Vector3(face - 0.04, panel_y + 0.35, 3.2), "dark_wood")
	for z: float in [2.4, 2.95]:
		_part(Vector3(face - 0.1, panel_y - 0.06, z - 0.06), Vector3(face - 0.045, panel_y + 0.06, z + 0.06), "iron")
		_part(Vector3(face - 0.05, panel_y - 0.2, z - 0.015), Vector3(face - 0.045, panel_y + 0.2, z + 0.015), "dark")
	_label("CABINE", Vector3(face - 0.05, panel_y + 0.28, 2.4), 0.05, Color("#E8D8B0") if not present else Color("#6A665C"), -90)
	_label("FREIO", Vector3(face - 0.05, panel_y + 0.28, 2.95), 0.05, Color("#E8D8B0") if not present else Color("#6A665C"), -90)
	if present:
		# Os punhos se perderam; só os tocos de ferro, presos onde ficaram
		for z: float in [2.4, 2.95]:
			_cylinder(Vector3(face - 0.08, panel_y, z), 0.02, 0.018, 0.12, "iron", Vector3(0, 0, 70), 6)


## O poço atrás da parede leste, do piso da despensa até acima do teto da cozinha.
func _build_shaft() -> void:
	var x0 := SHAFT_X.x
	var x1 := SHAFT_X.y
	_wall(Vector3(x1, 0, SHAFT_Z.x), Vector3(x1 + WALL, SHAFT_TOP, SHAFT_Z.y))
	_wall(Vector3(WIDTH, 0, SHAFT_Z.y), Vector3(x1 + WALL, SHAFT_TOP, SHAFT_Z.y + WALL))
	_wall(Vector3(WIDTH, TOP, -WALL), Vector3(x1 + WALL, SHAFT_TOP, 0))
	_part(Vector3(WIDTH, SHAFT_TOP, -WALL), Vector3(x1 + WALL, SHAFT_TOP + 0.3, SHAFT_Z.y + WALL), "stone")
	_solid(Vector3(x1, 0, SHAFT_Z.x), Vector3(x1 + WALL, SHAFT_TOP, SHAFT_Z.y), "Shaft")
	_solid(Vector3(WIDTH, 0, SHAFT_Z.y), Vector3(x1 + WALL, SHAFT_TOP, SHAFT_Z.y + WALL), "Shaft")
	# Trilhos de ferro nas paredes do poço
	for z: float in [SHAFT_Z.x + 0.08, SHAFT_Z.y - 0.08]:
		_part(Vector3(x1 - 0.12, 0, z - 0.04), Vector3(x1 - 0.04, SHAFT_TOP, z + 0.04), "iron")
	# Boca do poço na despensa, com batente e um amortecedor no fundo
	_part(Vector3(WIDTH - 0.06, 0, SHAFT_Z.y - 0.1), Vector3(WIDTH, SHAFT_OPENING + 0.1, SHAFT_Z.y), "oak")
	_part(Vector3(WIDTH - 0.06, SHAFT_OPENING, 0), Vector3(WIDTH, SHAFT_OPENING + 0.12, SHAFT_Z.y), "oak")
	_part(Vector3(x0 + 0.4, 0, 0.5), Vector3(x1 - 0.4, 0.15, 1.5), "cast_iron")
	_part(Vector3(x0, -0.01, 0), Vector3(x1, 0.0, SHAFT_Z.y), "stone")


# --- Despensa ---------------------------------------------------------------------------

func _build_pantry_ceiling() -> void:
	var x := 1.5
	while x < WIDTH:
		var z0 := 0.0 if x < STAIR_X.x or x > STAIR_X.y else STAIR_Z
		var sag := 0.0 if not present else _random(int(x * 10.0)) * 0.05
		_part(Vector3(x - 0.1, BEAM_Y - sag, z0), Vector3(x + 0.1, SLAB_BOTTOM, DEPTH), "oak")
		x += 1.5
	# Ganchos com presuntos e cebolas entre as vigas, longe do caminho
	for i in 4:
		var at := Vector3(15.6 + (i % 2) * 0.6, BEAM_Y, 4.4 + int(i / 2) * 0.7)
		_cylinder(at - Vector3(0, 0.35, 0), 0.005, 0.005, 0.35, "dark_wood", Vector3.ZERO, 4)
		if not present:
			_sphere(at - Vector3(0, 0.6, 0), 0.14, "ham", Vector3(0.9, 1.6, 0.9))
		elif i == 1:
			_sphere(at - Vector3(0, 0.5, 0), 0.08, "dark", Vector3(0.8, 1.4, 0.8))


func _build_posts() -> void:
	for post in POSTS:
		_part(Vector3(post.x - 0.13, 0, post.y - 0.13), Vector3(post.x + 0.13, BEAM_Y, post.y + 0.13), "oak")
		_part(Vector3(post.x - 0.16, 0, post.y - 0.16), Vector3(post.x + 0.16, 0.12, post.y + 0.16), "stone")
		# Mão-francesa ligando o pilar à viga mestra
		for side: float in [-1.0, 1.0]:
			_block(Vector3(post.x + side * 0.35, BEAM_Y - 0.3, post.y), Vector3(0.75, 0.1, 0.1), "oak", Vector3(0, 0, side * 40.0))
		_solid_cylinder(Vector3(post.x, 0, post.y), 0.16, BEAM_Y, "Post")
	_part(Vector3(0, BEAM_Y - 0.22, POSTS[0].y - 0.12), Vector3(WIDTH, BEAM_Y, POSTS[0].y + 0.12), "oak")


## Estantes de mantimentos na parede norte. O fermento fica na prateleira do meio (y = 1,14).
func _build_shelves() -> void:
	var x0 := SHELVES.x
	var x1 := SHELVES.y
	var depth := 0.5
	_solid(Vector3(x0, 0, 0), Vector3(x1, SHELF_BOARDS[-1] + 0.04, depth), "Shelves")
	# Montantes, tábuas e mãos-francesas (hoje a quarta tábua cedeu numa ponta)
	_model(MODELS + ("estante_despensa_hoje.glb" if present else "estante_despensa.glb"), Vector3(x0, 0, 0),
		Vector3.ZERO, 1.0, AGED if present else {})
	# Mantimentos: potes de conserva, latas e caixas (hoje, poucos e quebrados)
	for b in [0, 1, 2, 3]:
		var y: float = SHELF_BOARDS[b]
		var count := 12 if not present else 4
		for i in count:
			var px := x0 + 0.25 + i * ((x1 - x0 - 0.5) / count) + _random(i, b) * 0.05
			# Deixa o lugar do fermento livre
			if b == 2 and absf(px - 9.2) < 0.25:
				continue
			var kind := int(_random(i, b + 10.0) * 3.0)
			if kind == 0:
				_cylinder(Vector3(px, y, 0.25), 0.06, 0.06, 0.18, "glass", Vector3.ZERO, 10)
				_cylinder(Vector3(px, y + 0.01, 0.25), 0.05, 0.05, 0.14, "ham" if i % 2 else "leaf", Vector3.ZERO, 10)
			elif kind == 1:
				_cylinder(Vector3(px, y, 0.25), 0.07, 0.07, 0.12, "copper" if not present else "iron", Vector3.ZERO, 12)
			else:
				_part(Vector3(px - 0.12, y, 0.08), Vector3(px + 0.12, y + 0.2, 0.42), "plank")
	if present:
		for i in 7:
			_block(Vector3(x0 + 0.4 + _random(i, 20.0) * 4.0, 0.02, 0.7 + _random(i, 21.0) * 0.4), Vector3(0.08, 0.02, 0.06), "glass", Vector3(0, _random(i, 22.0) * 180.0, 0))


func _build_icebox() -> void:
	var x0 := ICEBOX.x
	var x1 := ICEBOX.y
	var depth := 0.9
	var icebox := _model(MODELS + "geladeira.glb", Vector3(x0, 0, 0), Vector3.ZERO, 1.0, AGED if present else {})
	if present:
		# A bandeja de cobre (que recolhia a água do gelo) não está mais lá
		var tray := icebox.find_child("copper", true, false)
		if tray:
			tray.free()
	_label("GELO", Vector3((x0 + x1) / 2.0, 1.4, depth + 0.05), 0.06, Color("#C9973B") if not present else Color("#4A463E"))
	_solid(Vector3(x0, 0, 0), Vector3(x1, 1.66, depth + 0.05), "Icebox")


## Sacos de farinha, barris e caixotes, encostados nas paredes (o centro fica livre).
func _build_pantry_stores() -> void:
	for i in 7:
		var at := Vector3(2.0 + i * 0.6, 0.0, 5.55 - _random(i) * 0.15)
		var tall := 0.35 + _random(i, 1.0) * 0.15
		var role := "flour"
		if present and i % 3 == 0:
			_sphere(at + Vector3(0, 0.08, 0), 0.32, "flour", Vector3(1.1, 0.3, 1))
			continue
		_sphere(at + Vector3(0, tall, 0), 0.28, role, Vector3(1, tall / 0.28, 0.8))
		_cylinder(at + Vector3(0, tall * 2.0 - 0.06, 0), 0.06, 0.03, 0.12, role, Vector3.ZERO, 8)
	_solid(Vector3(1.6, 0, 5.2), Vector3(6.2, 0.8, DEPTH), "Sacks")
	for i in 3:
		var at := Vector3(0.5, 0, 2.6 + i * 0.95)
		_cylinder(at, 0.38, 0.38, 0.95, "oak" if not present else "plank", Vector3.ZERO, 14)
		for y: float in [0.12, 0.8]:
			_cylinder(at + Vector3(0, y, 0), 0.395, 0.395, 0.05, "iron", Vector3.ZERO, 14)
		_solid_cylinder(at, 0.38, 0.95, "Barrel")
	if present:
		_part(Vector3(0.2, 0, 4.9), Vector3(1.0, 0.25, 5.7), "plank", Vector3(0, 30, 70))
	for i in 4:
		var at := Vector3(16.3 + (i % 2) * 0.8, (i / 2) * 0.5, 5.4)
		var tilt := 0.0 if not present else _random(i, 3.0) * 12.0
		_part(at, at + Vector3(0.7, 0.48, 0.55), "plank", Vector3(0, tilt, 0))
	_solid(Vector3(16.3, 0, 5.3), Vector3(17.9, 1.0, DEPTH), "Crates")


func _build_ruin_details() -> void:
	# Cozinha: escombros, papel de parede caído, fiação solta
	for i in 18:
		var at := Vector3(5.0 + _random(i) * 12.0, K + 0.04, 2.0 + _random(i, 1.0) * 3.6)
		if at.x > TABLE.position.x - 0.3 and at.x < TABLE.end.x + 0.3 and at.z > TABLE.position.y - 0.3 and at.z < TABLE.end.y + 0.3:
			continue
		_block(at, Vector3(0.1 + _random(i, 2.0) * 0.3, 0.06, 0.1 + _random(i, 3.0) * 0.25), "rubble" if i % 3 else "tile", Vector3(_random(i, 4.0) * 20.0, _random(i, 5.0) * 180.0, 0))
	for lamp in LAMPS:
		_cylinder(Vector3(lamp, TOP - 1.2 - _random(int(lamp)) * 0.6, LAMP_Z), 0.006, 0.006, 1.2, "dark", Vector3(0, 0, 6), 4)
	var fallen := Vector3(LAMPS[1] + 0.6, K, LAMP_Z + 0.9)
	_cylinder(fallen, 0.22, 0.05, 0.25, "copper", Vector3(70, 30, 0), 12)
	_solid_cylinder(fallen, 0.25, 0.3, "FallenLamp")
	_part(Vector3(0.03, K + 2.2, 3.2), Vector3(0.05, K + 3.4, 4.0), "plaster_cream", Vector3(0, 0, 6))
	# Despensa: tábuas soltas, pó e uma lona velha
	for i in 10:
		var at := Vector3(2.0 + _random(i, 30.0) * 13.0, 0.02, 1.8 + _random(i, 31.0) * 3.0)
		if at.distance_to(Vector3(11.75, 0.02, 3.2)) < 1.2:
			continue
		_block(at, Vector3(0.6 + _random(i, 32.0) * 0.6, 0.03, 0.12), "plank", Vector3(0, _random(i, 33.0) * 180.0, 0))
	_part(Vector3(15.4, 0.0, 2.2), Vector3(17.0, 0.04, 3.4), "tarp", Vector3(0, 15, 0))


# --- Luz -------------------------------------------------------------------------------

func _build_lights() -> void:
	if not present:
		_cast_shadows = false
		for i in LAMPS.size():
			var at := Vector3(LAMPS[i], K + 2.55, LAMP_Z)
			_cylinder(at + Vector3(0, 0.25, 0), 0.006, 0.006, TOP - K - 2.8, "dark", Vector3.ZERO, 4)
			_cylinder(at + Vector3(0, 0.05, 0), 0.28, 0.06, 0.2, "enamel", Vector3.ZERO, 16)
			_sphere(at + Vector3(0, 0.02, 0), 0.07, "bulb")
			_omni(at - Vector3(0, 0.1, 0), WARM, 1.5, 8.0, i == 1)
		# Brasa do fogão e uma luz quente na despensa
		_omni(Vector3(STOVE.x + 0.5, K + 0.4, 1.3), FIRE, 0.8, 2.5)
		for at: Vector3 in [Vector3(4.5, 3.6, 3.4), Vector3(11.0, 3.6, 2.2), Vector3(16.0, 3.6, 3.4)]:
			_cylinder(at + Vector3(0, 0.1, 0), 0.006, 0.006, 0.4, "dark", Vector3.ZERO, 4)
			_sphere(at, 0.06, "bulb")
			_omni(at - Vector3(0, 0.1, 0), WARM, 1.2, 7.0, at.x == 11.0)
		_cast_shadows = true
	else:
		# Luar pelas janelas altas; a despensa só tem o que a lanterna mostra
		for window in WINDOWS:
			var mid := (window.x + window.y) / 2.0
			_spot(Vector3(mid + 0.5, K + 6.0, DEPTH + 4.5), Vector3(mid - 0.3, K, 3.0), COLD, 7.0, 14.0, 16.0)
		_omni(Vector3(9.0, K + 2.5, 3.0), Color("#6A7E96"), 0.35, 12.0)
		_omni(Vector3(9.0, 2.5, 3.0), Color("#4A5A6E"), 0.2, 10.0)
