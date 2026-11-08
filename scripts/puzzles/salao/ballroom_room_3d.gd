@tool
class_name BallroomRoom3D
extends HotelBuilder3D
## Salão de baile (3º andar), montado por código nas duas épocas. Ao norte, o vestíbulo com a
## escada principal (oeste) e o poço do elevador (leste), no mesmo lugar dos Quartos. Ao sul, o
## salão alto, com mesas, dois lustres e o palco de 1,2 m no fundo. O que muda com os enigmas
## (escadinha, saco de areia, partitura, cabine) fica com BallroomLevel3D.

const H: float = 3.2
const HALL_H: float = 6.0
const DOOR_TOP: float = 2.3
## Vestíbulo: faixa em z, extensão em x (igual ao corredor dos Quartos).
const NORTH: float = 2.0
const SOUTH: float = 4.6
const WEST: float = 0.0
const EAST: float = 20.0
const STAIR := Vector2(1.5, 4.5)
const SHAFT := Vector2(15.4, 17.1)
const LANDING := Vector2(15.75, 16.75)
const SHAFT_BACK: float = 0.4
## Salão: do vestíbulo até a parede do fundo, atrás do palco.
const HALL_DOOR := Vector2(8.5, 11.5)
const HALL_DOOR_TOP: float = 2.9
const BACK: float = 18.0
## Palco: frente em STAGE_FRONT, de STAGE_X.x a STAGE_X.y, 1,2 m de altura.
const STAGE_FRONT: float = 14.0
const STAGE_X := Vector2(2.0, 18.0)
const STAGE_TOP: float = 1.2
## Escadinha de 1923 (some hoje): seis degraus do piso ao palco.
const STEPS_X := Vector2(4.6, 5.8)
const STEPS_Z: float = 12.2
## Onde o saco de areia do contrapeso cai, na frente do palco.
const SANDBAG := Vector3(9.0, 0, 13.45)
const PULLEY := Vector3(9.0, 5.7, 13.45)
const CLEAT := Vector3(1.7, 1.2, 13.72)
## Piano de palco: o pianista senta a oeste, de frente para leste; a tecla mais grave fica ao norte.
const PIANO := Vector3(14.6, STAGE_TOP, 15.9)
const KEYBOARD_X: float = 13.55
const KEYS_Z: float = 15.3
const KEY_WIDTH: float = 0.17
const BENCH := Vector3(12.95, STAGE_TOP, 15.9)
const MUSIC_STAND := Vector3(10.0, STAGE_TOP, 14.7)
const CHANDELIERS: Array[Vector3] = [Vector3(6.0, 4.9, 9.0), Vector3(14.0, 4.9, 9.0)]
const TABLES: Array[Vector2] = [Vector2(2.8, 6.8), Vector2(2.8, 10.4), Vector2(17.2, 6.8), Vector2(17.2, 10.4),
	Vector2(6.0, 12.0), Vector2(14.0, 12.0)]
## Hoje, o lustre do oeste caiu entre as mesas.
const FALLEN_CHANDELIER := Vector3(6.0, 0, 8.6)
const LAMP_GROUP := &"salao_lustre"

const WARM := Color("#F2D49B")
const MOON := Color("#8FA6BE")


func _build_room() -> void:
	_build_vestibule()
	_build_stairwell()
	_build_shaft()
	_build_hall()
	_build_stage()
	_build_tables()
	_build_chandeliers()
	_build_lights()


# --- Paredes ---------------------------------------------------------------------------------

## Parede ao longo de x, em z, com vãos (x0, x1, altura do vão).
func _wall_x(z: float, x0: float, x1: float, height: float, gaps: Array, role: String = "wallpaper") -> void:
	var x := x0
	for gap: Vector3 in gaps:
		if gap.x > x:
			_part(Vector3(x, 0, z - 0.1), Vector3(gap.x, height, z + 0.1), role)
			_solid(Vector3(x, 0, z - 0.1), Vector3(gap.x, height, z + 0.1), "Wall")
		if gap.z < height:
			_part(Vector3(gap.x, gap.z, z - 0.1), Vector3(gap.y, height, z + 0.1), role)
			_solid(Vector3(gap.x, gap.z, z - 0.1), Vector3(gap.y, height, z + 0.1), "Lintel")
			for side: float in [gap.x - 0.06, gap.y]:
				_part(Vector3(side, 0, z - 0.12), Vector3(side + 0.06, gap.z + 0.06, z + 0.12), "dark_wood")
			_part(Vector3(gap.x - 0.06, gap.z, z - 0.12), Vector3(gap.y + 0.06, gap.z + 0.06, z + 0.12), "dark_wood")
		x = gap.y
	if x < x1:
		_part(Vector3(x, 0, z - 0.1), Vector3(x1, height, z + 0.1), role)
		_solid(Vector3(x, 0, z - 0.1), Vector3(x1, height, z + 0.1), "Wall")


func _wall_z(x: float, z0: float, z1: float, height: float, role: String = "wallpaper") -> void:
	_part(Vector3(x - 0.1, 0, z0), Vector3(x + 0.1, height, z1), role)
	_solid(Vector3(x - 0.1, 0, z0), Vector3(x + 0.1, height, z1), "Wall")


# --- Vestíbulo --------------------------------------------------------------------------------

func _build_vestibule() -> void:
	var a := Vector3(WEST, -0.2, NORTH)
	var b := Vector3(EAST, 0, SOUTH)
	_part(a, b, "floor")
	_solid(a, b, "Floor")
	_part(Vector3(WEST, H, NORTH), Vector3(EAST, H + 0.2, SOUTH), "ceiling")
	_part(Vector3(WEST + 0.4, 0, NORTH + 0.6), Vector3(EAST - 0.4, 0.012, SOUTH - 0.6), "runner")
	_wall_x(NORTH, WEST, EAST, H, [Vector3(STAIR.x, STAIR.y, H), Vector3(LANDING.x, LANDING.y, DOOR_TOP)])
	_wall_z(WEST, NORTH, SOUTH, H)
	_wall_z(EAST, NORTH, SOUTH, H)
	for z: float in [NORTH + 0.11]:
		_part(Vector3(WEST, 0, z - 0.01), Vector3(EAST, 0.18, z + 0.01), "dark_wood")
		_part(Vector3(WEST, 1.0, z - 0.012), Vector3(EAST, 1.04, z + 0.012), "brass")
	var sign_color := Color("#C9973B") if not present else Color("#6E5A34")
	_label("SALÃO DE BAILE", Vector3((HALL_DOOR.x + HALL_DOOR.y) / 2.0, 3.0, SOUTH - 0.13), 0.08, sign_color, 180.0)
	_label("3º ANDAR", Vector3(14.6, 2.0, NORTH + 0.12), 0.06, sign_color)
	# Chapeleira encostada na parede oeste (sólida)
	_solid(Vector3(0.1, 0, 3.0), Vector3(0.6, 1.8, 3.6), "Coat")
	_part(Vector3(0.1, 0, 3.0), Vector3(0.6, 1.0, 3.6), "dark_wood" if not present else "plank")
	_part(Vector3(0.1, 1.7, 3.0), Vector3(0.6, 1.8, 3.6), "dark_wood" if not present else "plank")
	_part(Vector3(0.3, 1.0, 3.25), Vector3(0.4, 1.7, 3.35), "brass" if not present else "iron")


# --- Escada principal (a oeste): só desce ------------------------------------------------------

func _build_stairwell() -> void:
	var z0 := NORTH - 3.2
	_part(Vector3(STAIR.x, H, z0), Vector3(STAIR.y, H + 0.2, NORTH), "ceiling")
	_wall_z(STAIR.x, z0, NORTH, H)
	_wall_z(STAIR.y, z0, NORTH, H)
	_wall_x(z0, STAIR.x, STAIR.y, H, [])
	_solid(Vector3(STAIR.x, 0, z0), Vector3(STAIR.y, H, NORTH - 0.05), "StairWell")
	for i in 6:
		var y := -0.17 * (i + 1)
		var z := NORTH - 0.35 - i * 0.3
		if present and i in [0, 2, 3]:
			continue
		_part(Vector3(STAIR.x + 0.1, y - 0.05, z - 0.3), Vector3(STAIR.y - 0.1, y, z), "mahogany")
	_part(Vector3(STAIR.x, -1.4, z0), Vector3(STAIR.y, -1.3, NORTH), "dark")
	if present:
		for i in 5:
			_block(Vector3(STAIR.x + 0.6 + i * 0.6, -0.4 + _random(i) * 0.3, NORTH - 1.2 - _random(i, 1.0)),
				Vector3(1.3, 0.06, 0.25), "plank", Vector3(_random(i, 2.0) * 40.0, _random(i, 3.0) * 70.0, 25))
	for x in range(0, 13):
		if present and x in [2, 6, 7, 11]:
			continue
		_cylinder(Vector3(STAIR.x + 0.15 + x * 0.225, 0, NORTH - 0.08), 0.022, 0.03, 0.9,
			"brass" if not present else "iron", Vector3.ZERO, 8)
	_part(Vector3(STAIR.x, 0.9, NORTH - 0.12), Vector3(STAIR.y, 0.96, NORTH - 0.02), "mahogany")


# --- Poço do elevador (a leste) ---------------------------------------------------------------

func _build_shaft() -> void:
	_part(Vector3(SHAFT.x, -0.2, SHAFT_BACK), Vector3(SHAFT.y, 0, NORTH), "stone" if present else "iron")
	_solid(Vector3(SHAFT.x, -0.2, SHAFT_BACK), Vector3(SHAFT.y, 0, NORTH), "Ledge")
	_wall_z(SHAFT.x, SHAFT_BACK, NORTH, H, "stone")
	_wall_z(SHAFT.y, SHAFT_BACK, NORTH, H, "stone")
	_wall_x(SHAFT_BACK, SHAFT.x, SHAFT.y, H, [], "stone")
	_part(Vector3(SHAFT.x, H, SHAFT_BACK), Vector3(SHAFT.y, H + 0.2, NORTH), "stone")
	# Escada de marinheiro: hoje, inteira só daqui para cima (o trecho de baixo caiu)
	for y in range(-6, 12):
		if present and y < -1:
			continue
		_part(Vector3(16.2, y * 0.3, SHAFT_BACK + 0.08), Vector3(16.76, y * 0.3 + 0.03, SHAFT_BACK + 0.12), "iron")
	for x: float in [16.2, 16.73]:
		_part(Vector3(x, -0.5 if present else -2.0, SHAFT_BACK + 0.08), Vector3(x + 0.03, H, SHAFT_BACK + 0.14), "iron")
	if present:
		# Pontas tortas dos montantes onde a escada se partiu
		_block(Vector3(16.21, -0.75, SHAFT_BACK + 0.2), Vector3(0.03, 0.5, 0.03), "iron", Vector3(35, 0, 0))
		_block(Vector3(16.74, -0.7, SHAFT_BACK + 0.22), Vector3(0.03, 0.4, 0.03), "iron", Vector3(50, 0, 10))
	# Botoeira do pavimento, no vestíbulo
	_part(Vector3(17.2, 1.0, NORTH + 0.1), Vector3(17.4, 1.4, NORTH + 0.13), "brass" if not present else "iron")


# --- Salão ------------------------------------------------------------------------------------

func _build_hall() -> void:
	var a := Vector3(WEST, -0.2, SOUTH)
	var b := Vector3(EAST, 0, BACK)
	_part(a, b, "floorboards")
	_solid(a, b, "Floor")
	_part(Vector3(WEST, HALL_H, SOUTH), Vector3(EAST, HALL_H + 0.2, BACK), "coffer")
	# Parede entre o vestíbulo e o salão, com a porta dupla aberta
	_wall_x(SOUTH, WEST, EAST, H, [Vector3(HALL_DOOR.x, HALL_DOOR.y, HALL_DOOR_TOP)])
	_part(Vector3(WEST, H, SOUTH - 0.1), Vector3(EAST, HALL_H, SOUTH + 0.1), "wallpaper")
	_wall_z(WEST, SOUTH, BACK, HALL_H)
	_wall_z(EAST, SOUTH, BACK, HALL_H)
	_wall_x(BACK, WEST, EAST, HALL_H, [], "panel")
	# Folhas da porta dupla, abertas contra a parede (do lado do salão)
	for side: int in [-1, 1]:
		var hinge := HALL_DOOR.x if side < 0 else HALL_DOOR.y
		if present and side > 0:
			# Hoje uma folha caiu e ficou deitada rente ao piso
			_part(Vector3(hinge - 1.4, 0, SOUTH + 1.0), Vector3(hinge, 0.06, SOUTH + 2.3), "mahogany")
			continue
		var leaf_x := hinge - 0.08 if side < 0 else hinge + 0.02
		_part(Vector3(leaf_x, 0, SOUTH + 0.1), Vector3(leaf_x + 0.06, HALL_DOOR_TOP - 0.05, SOUTH + 1.5), "mahogany")
	# Espelhos na parede oeste, lambri e rodapé
	for z: float in [6.5, 9.5, 12.5]:
		_part(Vector3(WEST + 0.1, 1.0, z - 0.9), Vector3(WEST + 0.14, 3.8, z + 0.9), "brass")
		_part(Vector3(WEST + 0.14, 1.1, z - 0.8), Vector3(WEST + 0.16, 3.7, z + 0.8), "glass" if not present else "dark")
	for x: float in [WEST + 0.11, EAST - 0.11]:
		_part(Vector3(x - 0.01, 0, SOUTH), Vector3(x + 0.01, 0.2, BACK), "dark_wood")
		_part(Vector3(x - 0.012, 1.0, SOUTH), Vector3(x + 0.012, 1.04, BACK), "brass")
	# Janelões a leste: noite lá fora
	for z: float in [6.5, 9.5, 12.5]:
		_part(Vector3(EAST - 0.12, 1.0, z - 0.7), Vector3(EAST - 0.1, 4.6, z + 0.7), "night")
		_part(Vector3(EAST - 0.14, 1.0, z - 0.75), Vector3(EAST - 0.1, 1.06, z + 0.75), "dark_wood")
		_part(Vector3(EAST - 0.14, 4.6, z - 0.75), Vector3(EAST - 0.1, 4.66, z + 0.75), "dark_wood")
		_part(Vector3(EAST - 0.14, 1.0, z - 0.02), Vector3(EAST - 0.1, 4.6, z + 0.02), "dark_wood")
		_part(Vector3(EAST - 0.16, 3.0, z - 0.7), Vector3(EAST - 0.1, 3.03, z + 0.7), "dark_wood")
		if not present:
			_part(Vector3(EAST - 0.3, 1.0, z - 1.0), Vector3(EAST - 0.15, 5.0, z - 0.75), "velvet")
			_part(Vector3(EAST - 0.3, 1.0, z + 0.75), Vector3(EAST - 0.15, 5.0, z + 1.0), "velvet")
	if present:
		# Reboco caído e manchas de goteira
		for i in 9:
			_block(Vector3(1.5 + _random(i) * 17.0, 0.04, 5.5 + _random(i, 1.0) * 7.5),
				Vector3(0.4 + _random(i, 2.0) * 0.4, 0.08, 0.3), "rubble", Vector3(0, _random(i, 3.0) * 90.0, 0))


# --- Palco ------------------------------------------------------------------------------------

func _build_stage() -> void:
	var a := Vector3(STAGE_X.x, 0, STAGE_FRONT)
	var b := Vector3(STAGE_X.y, STAGE_TOP, BACK)
	_part(Vector3(a.x, STAGE_TOP - 0.06, a.z), b, "floorboards")
	_part(a, Vector3(b.x, STAGE_TOP - 0.06, a.z + 0.06), "dark_wood" if not present else "plank")
	_part(Vector3(a.x, STAGE_TOP - 0.1, a.z - 0.04), Vector3(b.x, STAGE_TOP, a.z + 0.02), "brass" if not present else "iron")
	_solid(a, b, "Stage")
	_build_steps()
	# Boca de cena: pilares nos dois lados e a bambolina em cima
	for x: Vector2 in [Vector2(WEST + 0.1, STAGE_X.x), Vector2(STAGE_X.y, EAST - 0.1)]:
		_part(Vector3(x.x, 0, STAGE_FRONT - 0.3), Vector3(x.y, HALL_H, STAGE_FRONT + 0.2), "panel")
		_solid(Vector3(x.x, 0, STAGE_FRONT - 0.3), Vector3(x.y, HALL_H, STAGE_FRONT + 0.2), "Proscenium")
		_part(Vector3(x.x, 0, BACK - 3.8), Vector3(x.y, HALL_H, BACK), "panel")
		_solid(Vector3(x.x, 0, STAGE_FRONT + 0.2), Vector3(x.y, HALL_H, BACK), "Wing")
	_part(Vector3(STAGE_X.x, HALL_H - 1.0, STAGE_FRONT - 0.2), Vector3(STAGE_X.y, HALL_H, STAGE_FRONT + 0.1), "velvet")
	_label("VALSA DA AURORA", Vector3(10.0, HALL_H - 0.5, STAGE_FRONT - 0.22), 0.1,
		Color("#C9973B") if not present else Color("#6E5A34"), 180.0)
	# Cortinas abertas nos lados do palco (sólidas até o chão)
	for x: Vector2 in [Vector2(STAGE_X.x, STAGE_X.x + 0.8), Vector2(STAGE_X.y - 0.8, STAGE_X.y)]:
		var top := HALL_H - 1.0 if not present else HALL_H - 1.6
		_part(Vector3(x.x, STAGE_TOP, STAGE_FRONT + 0.2), Vector3(x.y, top, STAGE_FRONT + 0.5), "velvet")
		_solid(Vector3(x.x, STAGE_TOP, STAGE_FRONT + 0.2), Vector3(x.y, top, STAGE_FRONT + 0.5), "Curtain")
	# Polia do contrapeso, no alto, e a corda até a malagueta no pilar oeste
	_cylinder(PULLEY + Vector3(-0.1, -0.12, 0), 0.12, 0.12, 0.08, "iron", Vector3(0, 0, 90), 12)
	_part(Vector3(CLEAT.x, PULLEY.y - 0.01, PULLEY.z - 0.01), Vector3(PULLEY.x, PULLEY.y + 0.01, PULLEY.z + 0.01), "leather")
	_part(Vector3(CLEAT.x - 0.01, CLEAT.y, CLEAT.z - 0.01), Vector3(CLEAT.x + 0.01, PULLEY.y, CLEAT.z + 0.01), "leather")
	_part(CLEAT + Vector3(-0.12, -0.03, -0.04), CLEAT + Vector3(0.12, 0.03, 0.0), "iron")
	# Piano de palco (cauda), banqueta e estante do maestro
	var wood := "lacquer" if not present else "dark_wood"
	_part(Vector3(KEYBOARD_X + 0.25, STAGE_TOP + 0.62, PIANO.z - 0.75), Vector3(PIANO.x + 1.4, STAGE_TOP + 0.95, PIANO.z + 0.75), wood)
	_part(Vector3(KEYBOARD_X, STAGE_TOP + 0.6, KEYS_Z - 0.08), Vector3(KEYBOARD_X + 0.25, STAGE_TOP + 0.72, KEYS_Z + 7 * KEY_WIDTH + 0.08), wood)
	_part(Vector3(KEYBOARD_X + 0.18, STAGE_TOP + 0.72, KEYS_Z - 0.08), Vector3(KEYBOARD_X + 0.25, STAGE_TOP + 0.9, KEYS_Z + 7 * KEY_WIDTH + 0.08), wood)
	for leg: Vector2 in [Vector2(KEYBOARD_X + 0.15, PIANO.z - 0.65), Vector2(KEYBOARD_X + 0.15, PIANO.z + 0.65), Vector2(PIANO.x + 1.2, PIANO.z)]:
		_part(Vector3(leg.x - 0.05, STAGE_TOP, leg.y - 0.05), Vector3(leg.x + 0.05, STAGE_TOP + 0.62, leg.y + 0.05), wood)
	if not present:
		# Tampa aberta
		var lid := _part(Vector3(KEYBOARD_X + 0.5, STAGE_TOP + 0.95, PIANO.z + 0.7), Vector3(PIANO.x + 1.4, STAGE_TOP + 0.98, PIANO.z + 0.75), wood)
		lid.rotation_degrees.x = -55.0
	_solid(Vector3(KEYBOARD_X, STAGE_TOP, PIANO.z - 0.75), Vector3(PIANO.x + 1.4, STAGE_TOP + 0.98, PIANO.z + 0.75), "Piano")
	var bench_wood := "mahogany" if not present else "plank"
	_part(BENCH + Vector3(-0.2, 0.42, -0.4), BENCH + Vector3(0.2, 0.5, 0.4), "velvet")
	for corner: Vector2 in [Vector2(-0.17, -0.37), Vector2(0.17, -0.37), Vector2(-0.17, 0.37), Vector2(0.17, 0.37)]:
		_part(BENCH + Vector3(corner.x - 0.025, 0, corner.y - 0.025), BENCH + Vector3(corner.x + 0.025, 0.42, corner.y + 0.025), bench_wood)
	_part(BENCH + Vector3(-0.19, 0.3, -0.39), BENCH + Vector3(0.19, 0.42, 0.39), bench_wood)
	_solid(BENCH + Vector3(-0.2, 0, -0.4), BENCH + Vector3(0.2, 0.5, 0.4), "Bench")
	var stand_metal := "brass" if not present else "iron"
	_cylinder(MUSIC_STAND, 0.02, 0.015, 1.05, stand_metal, Vector3.ZERO, 8)
	_cylinder(MUSIC_STAND, 0.2, 0.2, 0.03, stand_metal, Vector3.ZERO, 10)
	var desk := _part(MUSIC_STAND + Vector3(-0.3, 1.0, -0.02), MUSIC_STAND + Vector3(0.3, 1.38, 0.0), stand_metal)
	desk.rotation_degrees.x = 20.0
	_solid_cylinder(MUSIC_STAND, 0.2, 1.0, "Stand")
	# Cadeiras da orquestra viradas para a plateia
	for i in 5:
		var at := Vector3(5.5 + i * 1.1, STAGE_TOP, 16.2 + (i % 2) * 0.5)
		if at.x > 12.3:
			continue
		var chair := "dark_wood" if not present else "plank"
		_part(at + Vector3(-0.2, 0.42, -0.2), at + Vector3(0.2, 0.46, 0.2), chair)
		_part(at + Vector3(-0.2, 0.46, 0.17), at + Vector3(0.2, 0.95, 0.2), chair)
		for corner: Vector2 in [Vector2(-0.17, -0.17), Vector2(0.17, -0.17), Vector2(-0.17, 0.17), Vector2(0.17, 0.17)]:
			_part(at + Vector3(corner.x - 0.02, 0, corner.y - 0.02), at + Vector3(corner.x + 0.02, 0.42, corner.y + 0.02), chair)
		_solid(at + Vector3(-0.2, 0, -0.2), at + Vector3(0.2, 0.95, 0.2), "Chair")


## 1923: escadinha de seis degraus com rampa invisível. Hoje desabou: só tábuas rentes ao piso.
func _build_steps() -> void:
	var run := (STAGE_FRONT - STEPS_Z) / 6.0
	var rise := STAGE_TOP / 6.0
	if present:
		for i in 5:
			_block(Vector3(STEPS_X.x + 0.2 + _random(i) * 0.9, 0.03, STEPS_Z + 0.2 + _random(i, 1.0) * 1.4),
				Vector3(1.0, 0.05, 0.22), "plank", Vector3(0, _random(i, 2.0) * 120.0 - 60.0, 0))
		_block(Vector3(STEPS_X.y + 0.1, 0.3, STAGE_FRONT - 0.15), Vector3(0.06, 0.6, 0.06), "dark_wood", Vector3(25, 0, 0))
		return
	for i in 6:
		var z := STEPS_Z + i * run
		_part(Vector3(STEPS_X.x, 0, z), Vector3(STEPS_X.y, (i + 1) * rise, z + run + 0.02), "mahogany")
		_part(Vector3(STEPS_X.x + 0.1, (i + 1) * rise, z), Vector3(STEPS_X.y - 0.1, (i + 1) * rise + 0.01, z + run), "runner")
	for x: float in [STEPS_X.x - 0.04, STEPS_X.y + 0.01]:
		for i in 6:
			_part(Vector3(x, (i + 1) * rise, STEPS_Z + (i + 0.5) * run - 0.015), Vector3(x + 0.03, (i + 1) * rise + 0.8, STEPS_Z + (i + 0.5) * run + 0.015), "brass")
	var a := atan2(STAGE_TOP, STAGE_FRONT - STEPS_Z)
	var length := Vector2(STAGE_FRONT - STEPS_Z, STAGE_TOP).length()
	var mid := Vector3((STEPS_X.x + STEPS_X.y) / 2.0, STAGE_TOP / 2.0, (STEPS_Z + STAGE_FRONT) / 2.0)
	var normal := Vector3(0, cos(a), -sin(a))
	var down := Vector3(0, -sin(a), -cos(a))
	var center := mid - normal * 0.1 + down * 0.15
	var size := Vector3(STEPS_X.y - STEPS_X.x, 0.2, length + 0.3)
	var ramp := _solid(center - size / 2.0, center + size / 2.0, "Steps")
	ramp.rotation.x = -a


# --- Mesas (em 1923, cadeiras de pernas para o ar sobre elas) -------------------------------

func _build_tables() -> void:
	for i in TABLES.size():
		var spot: Vector2 = TABLES[i]
		var base := Vector3(spot.x, 0, spot.y)
		var top_y := 0.75
		_cylinder(base, 0.08, 0.06, top_y - 0.04, "dark_wood" if not present else "plank", Vector3.ZERO, 8)
		_cylinder(base, 0.3, 0.3, 0.03, "dark_wood" if not present else "plank", Vector3.ZERO, 10)
		if present and i % 3 == 1:
			# Tampo partido, caído de lado contra o pé
			_block(base + Vector3(0.3, 0.35, 0), Vector3(0.05, 0.9, 1.0), "plank", Vector3(0, 0, 12))
			_solid_cylinder(base, 0.6, 0.75, "Table")
			continue
		_cylinder(base + Vector3(0, top_y - 0.04, 0), 0.55, 0.55, 0.04, "dark_wood" if not present else "plank", Vector3.ZERO, 16)
		if not present:
			_cylinder(base + Vector3(0, top_y - 0.05, 0), 0.6, 0.6, 0.01, "paper", Vector3.ZERO, 16)
			for k in 2:
				var offset := Vector3(-0.22 + k * 0.44, top_y, 0)
				_part(base + offset + Vector3(-0.18, 0.0, -0.18), base + offset + Vector3(0.18, 0.04, 0.18), "mahogany")
				for corner: Vector2 in [Vector2(-0.15, -0.15), Vector2(0.15, -0.15), Vector2(-0.15, 0.15), Vector2(0.15, 0.15)]:
					_part(base + offset + Vector3(corner.x - 0.02, 0.04, corner.y - 0.02),
						base + offset + Vector3(corner.x + 0.02, 0.46, corner.y + 0.02), "mahogany")
			_solid_cylinder(base, 0.6, 1.25, "Table")
		else:
			_solid_cylinder(base, 0.6, 0.75, "Table")


# --- Lustres ----------------------------------------------------------------------------------

func _build_chandeliers() -> void:
	for i in CHANDELIERS.size():
		var at: Vector3 = CHANDELIERS[i]
		if present and i == 0:
			# Caído: aro amassado e cristais espalhados
			var down := FALLEN_CHANDELIER
			_torus(down + Vector3(0, 0.12, 0), 0.6, 0.75, "iron", Vector3(8, 0, 6))
			_cylinder(down, 0.25, 0.1, 0.55, "iron", Vector3(0, 0, 70), 8)
			for k in 10:
				_block(down + Vector3(_random(k) * 2.4 - 1.2, 0.03, _random(k, 1.0) * 2.0 - 1.0), Vector3(0.06, 0.06, 0.06), "glass")
			_solid_cylinder(down, 0.85, 0.55, "Chandelier")
			_part(Vector3(at.x - 0.01, at.y, at.z - 0.01), Vector3(at.x + 0.01, HALL_H, at.z + 0.01), "iron")
			continue
		var metal := "brass" if not present else "iron"
		_part(Vector3(at.x - 0.015, at.y + 0.3, at.z - 0.015), Vector3(at.x + 0.015, HALL_H, at.z + 0.015), metal)
		_torus(at, 0.55, 0.65, metal)
		_torus(at + Vector3(0, -0.35, 0), 0.3, 0.38, metal)
		_cylinder(at + Vector3(0, -0.5, 0), 0.05, 0.12, 0.8, metal, Vector3.ZERO, 8)
		for k in 8:
			var angle := TAU * k / 8.0
			var tip := at + Vector3(cos(angle) * 0.6, 0.05, sin(angle) * 0.6)
			var bulb := _sphere(tip, 0.06, "bulb" if not present else "glass")
			bulb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _build_lights() -> void:
	if not present:
		for at: Vector3 in CHANDELIERS:
			var lamp := _omni(at + Vector3(0, -0.3, 0), WARM, 3.2, 13.0, true)
			lamp.add_to_group(LAMP_GROUP)
		var stage := _spot(Vector3(10.0, 5.2, 11.0), Vector3(12.5, 1.2, 15.5), WARM, 3.0, 12.0, 40.0)
		stage.add_to_group(LAMP_GROUP)
		# Arandelas nas paredes laterais
		for z: float in [5.6, 8.0, 11.0]:
			for x: float in [WEST + 0.35, EAST - 0.35]:
				var sconce := _omni(Vector3(x, 2.6, z), WARM, 0.9, 5.0)
				sconce.add_to_group(LAMP_GROUP)
				var side := 1.0 if x < 10.0 else -1.0
				_part(Vector3(x - side * 0.25 - 0.04, 2.45, z - 0.04), Vector3(x - side * 0.25 + 0.04, 2.7, z + 0.04), "brass")
				_sphere(Vector3(x - side * 0.15, 2.72, z), 0.06, "bulb").cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for x: float in [3.0, 10.0, 17.0]:
			_omni(Vector3(x, H - 0.4, (NORTH + SOUTH) / 2.0), WARM, 0.9, 5.0)
	else:
		for z: float in [6.5, 9.5, 12.5]:
			_spot(Vector3(EAST - 0.3, 4.2, z), Vector3(12.0, 0, z + 1.0), MOON, 1.4, 12.0, 28.0)
		_omni(Vector3(10.0, 2.5, 3.3), MOON, 0.25, 12.0)
		_omni(Vector3(10.0, 3.5, 15.0), MOON, 0.3, 8.0)
