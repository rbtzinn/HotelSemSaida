@tool
class_name GuestFloorRoom3D
extends HotelBuilder3D
## 2º andar (Quartos), montado por código nas duas épocas. Corredor leste-oeste com a escada
## principal a oeste e o poço do elevador a leste, no mesmo lugar do Saguão. Ao norte: rouparia e
## quarto 214 (Caio, 1951). Ao sul: quarto 207 (Helena) e portas de outros quartos.
## Portas que abrem, bandeira, alavanca, espelho e objetos dos enigmas ficam com 

const H: float = 3.2
const DOOR_TOP: float = 2.3
## Corredor: faixa em z, extensão em x.
const NORTH: float = 2.0
const SOUTH: float = 4.6
const WEST: float = 0.0
const EAST: float = 20.0
## Vãos na parede norte (x).
const STAIR := Vector2(1.5, 4.5)
const LINEN := Vector2(7.0, 8.0)
const ROOM_214 := Vector2(12.0, 13.0)
const SHAFT := Vector2(15.4, 17.1)
const LANDING := Vector2(15.75, 16.75)
## Portas na parede sul (x): só a do 207 abre.
const ROOM_207 := Vector2(7.0, 8.0)
const DECOR_DOORS: Array[Vector2] = [Vector2(2.5, 3.5), Vector2(12.0, 13.0), Vector2(17.0, 18.0)]
const DECOR_NUMBERS := ["203", "211", "215"]
## Cômodos (x0, z0, x1, z1).
const LINEN_ROOM := Rect2(6.0, -0.5, 3.0, 2.5)
const ROOM_214_RECT := Rect2(10.5, -2.5, 4.0, 4.5)
const ROOM_207_RECT := Rect2(5.5, 4.6, 4.5, 4.9)
const SHAFT_BACK: float = 0.4
const MIRROR := Vector3(10.9, 1.6, SOUTH - 0.13)
## Móveis do 207 usados pelo diário (GuestFloorLevel3D).
const DESK := Vector3(5.95, 0.78, 7.0)
const WARDROBE := Vector3(6.8, 0, 9.0)
const TRUNK := Vector3(9.0, 0, 6.2)

const MODELS := "res://art/models/"
## Hoje, os móveis dos modelos ficam com madeira velha e panos cobertos de pó.
const AGED := {"mahogany": "plank", "dark_wood": "plank", "velvet": "tarp", "paper": "tarp", "brass": "iron"}

const WARM := Color("#F2D49B")
const MOON := Color("#8FA6BE")


func _build_room() -> void:
	_build_corridor()
	_build_stairwell()
	_build_linen_room()
	_build_room_214()
	_build_room_207()
	_build_shaft()
	_build_lights()


# --- Paredes ---------------------------------------------------------------------------------

## Parede ao longo de x, em z, com vãos de porta (altura DOOR_TOP) ou abertos até o teto.
func _wall_x(z: float, x0: float, x1: float, doors: Array, open_gaps: Array = [], role: String = "wallpaper") -> void:
	var cuts: Array = []
	for gap: Vector2 in doors:
		cuts.append([gap, DOOR_TOP])
	for gap: Vector2 in open_gaps:
		cuts.append([gap, H])
	cuts.sort_custom(func(a: Array, b: Array) -> bool: return a[0].x < b[0].x)
	var x := x0
	for cut: Array in cuts:
		var gap: Vector2 = cut[0]
		if gap.x > x:
			_part(Vector3(x, 0, z - 0.1), Vector3(gap.x, H, z + 0.1), role)
			_solid(Vector3(x, 0, z - 0.1), Vector3(gap.x, H, z + 0.1), "Wall")
		if float(cut[1]) < H:
			_part(Vector3(gap.x, cut[1], z - 0.1), Vector3(gap.y, H, z + 0.1), role)
			_solid(Vector3(gap.x, cut[1], z - 0.1), Vector3(gap.y, H, z + 0.1), "Lintel")
			# Batente de madeira
			for side: float in [gap.x - 0.06, gap.y]:
				_part(Vector3(side, 0, z - 0.12), Vector3(side + 0.06, cut[1] + 0.06, z + 0.12), "dark_wood")
			_part(Vector3(gap.x - 0.06, cut[1], z - 0.12), Vector3(gap.y + 0.06, cut[1] + 0.06, z + 0.12), "dark_wood")
		x = gap.y
	if x < x1:
		_part(Vector3(x, 0, z - 0.1), Vector3(x1, H, z + 0.1), role)
		_solid(Vector3(x, 0, z - 0.1), Vector3(x1, H, z + 0.1), "Wall")


## Parede ao longo de z, em x, sem vãos.
func _wall_z(x: float, z0: float, z1: float, role: String = "wallpaper") -> void:
	_part(Vector3(x - 0.1, 0, z0), Vector3(x + 0.1, H, z1), role)
	_solid(Vector3(x - 0.1, 0, z0), Vector3(x + 0.1, H, z1), "Wall")


func _floor_and_ceiling(rect: Rect2, floor_role: String) -> void:
	var a := Vector3(rect.position.x, -0.2, rect.position.y)
	var b := Vector3(rect.end.x, 0, rect.end.y)
	_part(a, b, floor_role)
	_solid(a, b, "Floor")
	_part(Vector3(a.x, H, a.z), Vector3(b.x, H + 0.2, b.z), "ceiling")


# --- Corredor ---------------------------------------------------------------------------------

func _build_corridor() -> void:
	_floor_and_ceiling(Rect2(WEST, NORTH, EAST - WEST, SOUTH - NORTH), "floorboards")
	# Passadeira no meio do corredor
	_part(Vector3(WEST + 0.4, 0, NORTH + 0.6), Vector3(EAST - 0.4, 0.012, SOUTH - 0.6), "runner")
	_wall_x(NORTH, WEST, EAST, [LINEN, ROOM_214, LANDING], [STAIR])
	_wall_x(SOUTH, WEST, EAST, [ROOM_207] + DECOR_DOORS)
	_wall_z(WEST, NORTH, SOUTH)
	_wall_z(EAST, NORTH, SOUTH)
	# Rodapé e lambri dos dois lados
	for z: float in [NORTH + 0.11, SOUTH - 0.11]:
		_part(Vector3(WEST, 0, z - 0.01), Vector3(EAST, 0.18, z + 0.01), "dark_wood")
		_part(Vector3(WEST, 1.0, z - 0.012), Vector3(EAST, 1.04, z + 0.012), "brass")
	# Portas de outros quartos, fechadas nas duas épocas (sólidas)
	for i in DECOR_DOORS.size():
		var gap: Vector2 = DECOR_DOORS[i]
		_part(Vector3(gap.x, 0, SOUTH - 0.05), Vector3(gap.y, DOOR_TOP, SOUTH + 0.05), "mahogany")
		_solid(Vector3(gap.x, 0, SOUTH - 0.1), Vector3(gap.y, DOOR_TOP, SOUTH + 0.1), "ClosedDoor")
		_cylinder(Vector3(gap.y - 0.15, 1.0, SOUTH - 0.07), 0.035, 0.035, 0.05, "brass", Vector3(90, 0, 0), 10)
		_label(DECOR_NUMBERS[i], Vector3((gap.x + gap.y) / 2.0, 1.75, SOUTH - 0.06), 0.09,
			Color("#C9973B") if not present else Color("#6E5A34"), 180.0)
	_label("207", Vector3(ROOM_207.y + 0.35, 1.6, SOUTH - 0.12), 0.09,
		Color("#C9973B") if not present else Color("#6E5A34"), 180.0)
	_label("214", Vector3(ROOM_214.y + 0.35, 1.6, NORTH + 0.12), 0.09,
		Color("#C9973B") if not present else Color("#6E5A34"))
	_label("ROUPARIA", Vector3((LINEN.x + LINEN.y) / 2.0, 2.6, NORTH + 0.12), 0.06,
		Color("#C9973B") if not present else Color("#6E5A34"))
	# Moldura do espelho (o espelho em si é do nível)
	_part(MIRROR + Vector3(-0.55, -0.7, -0.03), MIRROR + Vector3(0.55, 0.7, 0.0), "brass")
	# Carrinho de serviço perto da escada (sólido)
	var cart := Vector3(5.2, 0, 4.0)
	_solid(cart + Vector3(-0.45, 0, -0.3), cart + Vector3(0.45, 0.95, 0.3), "Cart")
	_part(cart + Vector3(-0.45, 0.85, -0.3), cart + Vector3(0.45, 0.9, 0.3), "dark_wood" if not present else "plank")
	_part(cart + Vector3(-0.45, 0.25, -0.3), cart + Vector3(0.45, 0.3, 0.3), "dark_wood" if not present else "plank")
	for corner: Vector2 in [Vector2(-0.42, -0.27), Vector2(0.42, -0.27), Vector2(-0.42, 0.27), Vector2(0.42, 0.27)]:
		_part(cart + Vector3(corner.x - 0.02, 0, corner.y - 0.02), cart + Vector3(corner.x + 0.02, 0.88, corner.y + 0.02), "brass" if not present else "iron")
	if not present:
		_part(cart + Vector3(-0.35, 0.9, -0.2), cart + Vector3(0.1, 1.05, 0.2), "paper")
	else:
		for i in 7:
			_block(Vector3(1.0 + i * 2.7, 0.06, NORTH + 0.4 + _random(i) * 1.8), Vector3(0.3, 0.1, 0.22), "rubble", Vector3(0, _random(i, 2.0) * 90.0, 8))


# --- Escada principal (a oeste) --------------------------------------------------------------

func _build_stairwell() -> void:
	var z0 := NORTH - 3.2
	# Sem piso: os degraus descem para o Saguão
	_part(Vector3(STAIR.x, H, z0), Vector3(STAIR.y, H + 0.2, NORTH), "ceiling")
	_wall_z(STAIR.x, z0, NORTH)
	_wall_z(STAIR.y, z0, NORTH)
	_wall_x(z0, STAIR.x, STAIR.y, [])
	# A oeste, degraus descendo para o Saguão; a leste, o lance que sobe ao Salão de baile.
	# Os dois só se veem por cima do balaústre que fecha o vão.
	var middle := (STAIR.x + STAIR.y) / 2.0
	_solid(Vector3(STAIR.x, 0, z0), Vector3(STAIR.y, H, NORTH - 0.05), "StairWell")
	for i in 6:
		var y := -0.17 * (i + 1)
		var z := NORTH - 0.35 - i * 0.3
		if present and i in [1, 2, 4]:
			continue
		_part(Vector3(STAIR.x + 0.1, y - 0.05, z - 0.3), Vector3(middle - 0.05, y, z), "mahogany")
	for i in 9:
		var y := 0.2 * (i + 1)
		var z := NORTH - 0.35 - i * 0.3
		if present and i not in [0, 1, 6]:
			continue
		_part(Vector3(middle + 0.05, y - 0.05, z - 0.3), Vector3(STAIR.y - 0.1, y, z), "mahogany")
	_part(Vector3(middle - 0.05, -1.3, z0), Vector3(middle + 0.05, 2.0, NORTH - 0.2), "dark_wood")
	# O lance de cima continua por um vão escuro na parede do fundo
	_part(Vector3(middle + 0.1, 1.8, z0 + 0.11), Vector3(STAIR.y - 0.15, H - 0.1, z0 + 0.13), "dark")
	_part(Vector3(STAIR.x, -1.4, z0), Vector3(middle, -1.3, NORTH), "dark")
	if present:
		# A escada desabou: tábuas tortas e escombros no vão
		for i in 5:
			_block(Vector3(STAIR.x + 0.6 + i * 0.6, -0.3 + _random(i) * 0.3, NORTH - 1.0 - _random(i, 1.0)),
				Vector3(1.4, 0.06, 0.25), "plank", Vector3(_random(i, 2.0) * 40.0, _random(i, 3.0) * 70.0, 25))
	for x in range(0, 13):
		var bx := STAIR.x + 0.15 + x * 0.225
		if present and x in [3, 4, 9]:
			continue
		_cylinder(Vector3(bx, 0, NORTH - 0.08), 0.022, 0.03, 0.9, "brass" if not present else "iron", Vector3.ZERO, 8)
	_part(Vector3(STAIR.x, 0.9, NORTH - 0.12), Vector3(STAIR.y, 0.96, NORTH - 0.02), "mahogany")


# --- Rouparia ---------------------------------------------------------------------------------

func _build_linen_room() -> void:
	var r := LINEN_ROOM
	_floor_and_ceiling(r, "floorboards")
	_wall_z(r.position.x, r.position.y, NORTH)
	_wall_z(r.end.x, r.position.y, NORTH)
	_wall_x(r.position.y, r.position.x, r.end.x, [])
	# Prateleiras de lençóis na parede oeste
	var shelf_x := r.position.x + 0.1
	_solid(Vector3(shelf_x, 0, r.position.y + 0.3), Vector3(shelf_x + 0.5, 2.2, r.position.y + 2.0), "Shelves")
	for y: float in [0.4, 1.0, 1.6, 2.15]:
		_part(Vector3(shelf_x, y, r.position.y + 0.3), Vector3(shelf_x + 0.5, y + 0.04, r.position.y + 2.0), "oak" if not present else "plank")
		if not present and y < 2.0:
			for k in 3:
				_part(Vector3(shelf_x + 0.05, y + 0.04, r.position.y + 0.4 + k * 0.5), Vector3(shelf_x + 0.45, y + 0.2, r.position.y + 0.8 + k * 0.5), "paper")
	# Armário da governanta na parede do fundo (a chave mestra é do nível)
	var cab := Vector3(r.position.x + 1.9, 0, r.position.y + 0.1)
	_solid(cab + Vector3(-0.5, 0, 0), cab + Vector3(0.5, 2.0, 0.45), "Cabinet")
	_part(cab + Vector3(-0.5, 0, 0), cab + Vector3(0.5, 2.0, 0.45), "mahogany" if not present else "plank")
	_part(cab + Vector3(-0.45, 0.1, 0.45), cab + Vector3(-0.02, 1.9, 0.47), "dark_wood")
	_part(cab + Vector3(0.02, 0.1, 0.45), cab + Vector3(0.45, 1.9, 0.47), "dark_wood")


# --- Quarto 214 (Caio, 1951) ------------------------------------------------------------------

func _build_room_214() -> void:
	var r := ROOM_214_RECT
	_floor_and_ceiling(r, "floorboards")
	_wall_z(r.position.x, r.position.y, NORTH)
	_wall_z(r.end.x, r.position.y, NORTH)
	_wall_x(r.position.y, r.position.x, r.end.x, [])
	# Cama contra a parede do fundo, mesa com cadeira à direita
	var bed := Vector3(r.position.x + 1.2, 0, r.position.y + 1.1)
	# A cabeceira fica contra a parede do fundo (norte)
	_model(MODELS + "cama.glb", bed + Vector3(0, 0, 0.2), Vector3(0, 180, 0), 1.0, AGED if present else {})
	_solid(bed + Vector3(-0.82, 0, -1.0), bed + Vector3(0.82, 0.6, 1.32), "Bed")
	var desk := Vector3(r.end.x - 0.6, 0, r.position.y + 2.2)
	_model(MODELS + "escrivaninha.glb", desk, Vector3(0, 180, 0), 1.0,
		{"mahogany": "oak", "dark_wood": "oak"} if not present else AGED)
	_solid(desk + Vector3(-0.45, 0, -0.62), desk + Vector3(0.45, 0.78, 0.62), "Desk")
	if present:
		_part(desk + Vector3(-0.3, 0.78, -0.25), desk + Vector3(0.2, 0.8, 0.15), "paper")
		# Maleta de médico no chão, junto da cama (sólida)
		var bag := Vector3(r.position.x + 2.5, 0, r.position.y + 1.0)
		_solid(bag + Vector3(-0.25, 0, -0.15), bag + Vector3(0.25, 0.3, 0.15), "DoctorBag")
		_part(bag + Vector3(-0.25, 0, -0.15), bag + Vector3(0.25, 0.28, 0.15), "leather")
		_cylinder(bag + Vector3(0, 0.28, 0), 0.06, 0.06, 0.04, "brass", Vector3(0, 0, 90), 8)


# --- Quarto 207 (Helena) ----------------------------------------------------------------------

func _build_room_207() -> void:
	var r := ROOM_207_RECT
	_floor_and_ceiling(r, "floorboards")
	_wall_z(r.position.x, SOUTH, r.end.y)
	_wall_z(r.end.x, SOUTH, r.end.y)
	_wall_x(r.end.y, r.position.x, r.end.x, [])
	var rug_from := Vector3(r.position.x + 0.3, 0.005, r.position.y + 0.8)
	var rug_to := Vector3(r.end.x - 0.6, 0.015, r.end.y - 0.6)
	var rug_center := Vector2((rug_from.x + rug_to.x) / 2.0, (rug_from.z + rug_to.z) / 2.0)
	var rug_half := Vector2(rug_to.x - rug_from.x, rug_to.z - rug_from.z) / 2.0
	_part(rug_from, rug_to, "rug", Vector3.ZERO, HotelMaterials.rug_material("rug", present, rug_center, rug_half))
	# Janela na parede do fundo: vidro em 1923, tábuas hoje
	var window := Vector3(r.position.x + 2.6, 1.6, r.end.y - 0.11)
	_part(window + Vector3(-0.6, -0.7, -0.02), window + Vector3(0.6, 0.7, 0.0), "glass" if not present else "plank")
	_part(window + Vector3(-0.7, -0.78, -0.05), window + Vector3(0.7, -0.7, 0.0), "dark_wood")
	# Cama (leste), escrivaninha (oeste), guarda-roupa (fundo) e mala (pé da cama)
	var bed := Vector3(r.end.x - 1.0, 0, r.position.y + 3.2)
	_model(MODELS + "cama.glb", bed, Vector3.ZERO, 1.0, AGED if present else {})
	_solid(bed + Vector3(-0.82, 0, -1.15), bed + Vector3(0.82, 0.6, 1.2), "Bed")
	var desk := DESK
	_model(MODELS + "escrivaninha.glb", Vector3(r.position.x + 0.47, 0, desk.z), Vector3.ZERO, 1.0, AGED if present else {})
	_solid(Vector3(r.position.x + 0.1, 0, desk.z - 0.62), Vector3(r.position.x + 0.83, 0.78, desk.z + 0.62), "Desk")
	if not present:
		_cylinder(Vector3(r.position.x + 0.45, 0.78, desk.z - 0.4), 0.07, 0.05, 0.3, "brass")
		_omni(Vector3(r.position.x + 0.45, 1.2, desk.z - 0.4), WARM, 0.6, 3.5)
	var wardrobe := WARDROBE
	_model(MODELS + "guarda_roupa.glb", wardrobe, Vector3.ZERO, 1.0, AGED if present else {})
	_solid(wardrobe + Vector3(-0.63, 0, -0.37), wardrobe + Vector3(0.63, 2.2, 0.36), "Wardrobe")
	if present:
		# Cupins: furos e serragem no pé do guarda-roupa
		for i in 8:
			_sphere(wardrobe + Vector3(-0.5 + _random(i) * 1.0, 0.03, -0.45 - _random(i, 1.0) * 0.2), 0.05, "flour", Vector3(1, 0.3, 1))
	var trunk := TRUNK
	_model(MODELS + "bau.glb", trunk, Vector3.ZERO, 1.0, {"brass": "iron"} if present else {})
	_solid(trunk + Vector3(-0.42, 0, -0.26), trunk + Vector3(0.42, 0.42, 0.26), "Trunk")
	if present:
		# O forro descosturado aparece num canto
		_part(trunk + Vector3(0.15, 0.4, -0.2), trunk + Vector3(0.38, 0.41, 0.0), "velvet")


# --- Poço do elevador (leste) ----------------------------------------------------------------

func _build_shaft() -> void:
	# Patamar estreito dentro do poço, onde Lia chega pela escada de marinheiro
	_part(Vector3(SHAFT.x, -0.2, SHAFT_BACK), Vector3(SHAFT.y, 0, NORTH), "stone" if present else "iron")
	_solid(Vector3(SHAFT.x, -0.2, SHAFT_BACK), Vector3(SHAFT.y, 0, NORTH), "Ledge")
	_wall_z(SHAFT.x, SHAFT_BACK, NORTH, "stone")
	_wall_z(SHAFT.y, SHAFT_BACK, NORTH, "stone")
	_wall_x(SHAFT_BACK, SHAFT.x, SHAFT.y, [], [], "stone")
	_part(Vector3(SHAFT.x, H, SHAFT_BACK), Vector3(SHAFT.y, H + 0.2, NORTH), "stone")
	# Escada de marinheiro no fundo do poço
	for y in range(-6, 12):
		_part(Vector3(16.2, y * 0.3, SHAFT_BACK + 0.08), Vector3(16.76, y * 0.3 + 0.03, SHAFT_BACK + 0.12), "iron")
	for x: float in [16.2, 16.73]:
		_part(Vector3(x, -2.0, SHAFT_BACK + 0.08), Vector3(x + 0.03, H, SHAFT_BACK + 0.14), "iron")
	# Cabos da cabine, que está lá em cima
	for x: float in [15.95, 16.55]:
		_part(Vector3(x, -2.0, 1.2), Vector3(x + 0.02, H, 1.22), "iron")
	# Botoeira do pavimento, no corredor
	_part(Vector3(17.2, 1.0, NORTH + 0.1), Vector3(17.4, 1.4, NORTH + 0.13), "brass" if not present else "iron")


func _build_lights() -> void:
	if not present:
		for x: float in [2.0, 6.0, 10.0, 14.0, 18.0]:
			_omni(Vector3(x, H - 0.4, (NORTH + SOUTH) / 2.0), WARM, 1.1, 5.0)
			_part(Vector3(x - 0.12, H - 0.2, NORTH + 0.1), Vector3(x + 0.12, H - 0.05, NORTH + 0.2), "brass")
		_omni(Vector3(7.75, 2.6, 7.0), WARM, 1.2, 6.0, true)
		_omni(Vector3(12.5, 2.6, -0.3), WARM, 0.8, 5.0)
		_omni(Vector3(7.5, 2.4, 0.7), WARM, 0.6, 3.0)
	else:
		_spot(Vector3(8.1, 2.6, 9.6), Vector3(8.0, 0, 6.5), MOON, 1.2, 8.0, 25.0)
		_omni(Vector3(10.0, 2.5, 3.3), MOON, 0.25, 12.0)
