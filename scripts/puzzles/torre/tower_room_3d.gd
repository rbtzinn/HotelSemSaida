@tool
class_name TowerRoom3D
extends HotelBuilder3D
## Telhado e torre do relógio, montados por código nas duas épocas. A escada em caracol (que sai
## do painel atrás do piano do Saguão) chega à casinha da escada, a oeste. Do terraço da frente,
## duas passarelas de vigas cruzam o vão do telhado até o terraço da torre. A caixa d'água fica
## no terraço da frente, ao lado da passarela leste. Na torre: o mecanismo com o mostrador de
## acerto e a caixa do pêndulo encostada na parede do fundo.
## O que muda com os enigmas (passarelas, ponteiros, caixa do pêndulo) fica com TowerLevel3D.

const WEST: float = 0.0
const EAST: float = 10.0
## Terraço da frente e terraço da torre (faixas em z).
const FRONT := Vector2(0.0, 5.0)
const BACK := Vector2(11.0, 13.0)
const DROP: float = -4.0
## Passarelas sobre o vão (faixas em x), de FRONT.y a BACK.x.
const WEST_WALK := Vector2(2.5, 3.5)
const EAST_WALK := Vector2(6.5, 7.5)
const PARAPET: float = 1.0
## Casinha da escada.
const STAIR_HOUSE := Rect2(0.0, 0.0, 3.0, 3.0)
const STAIR_DOOR := Vector2(1.0, 2.0)
const HOUSE_H: float = 2.6
const STAIR_HOLE := Vector3(1.5, 0, 1.0)
## Caixa d'água sobre a base de tijolos, e o registro na frente da base.
const TANK := Rect2(7.6, 0.4, 2.0, 2.0)
const TANK_BASE: float = 1.0
const TANK_TOP: float = 3.0
const VALVE := Vector3(8.0, 0.7, 2.42)
## Torre.
const TOWER := Rect2(2.0, 13.0, 6.0, 6.0)
const TOWER_H: float = 4.5
const TOWER_DOOR := Vector2(4.5, 5.5)
const DOOR_TOP: float = 2.3
const BIG_DIAL := Vector3(5.0, 3.4, 12.86)
const BIG_RADIUS: float = 0.75
## Mecanismo, mostrador de acerto (na face norte) e caixa do pêndulo.
const MACHINE := Rect2(4.2, 15.2, 1.6, 1.2)
const MACHINE_H: float = 1.2
const SERVICE_DIAL := Vector3(5.0, 1.45, 15.17)
const SERVICE_RADIUS: float = 0.17
const CASE := Rect2(4.3, 18.3, 1.4, 0.6)
const CASE_H: float = 2.4

const WARM := Color("#F2D49B")
const MOON := Color("#8FA6BE")


func _build_room() -> void:
	_build_decks()
	_build_stair_house()
	_build_tank()
	_build_tower()
	_build_machine()
	_build_sky()
	_build_lights()


# --- Terraços, parapeitos e o vão -----------------------------------------------------------

func _build_decks() -> void:
	var deck := "rubble" if present else "floor"
	for band: Vector2 in [FRONT, BACK]:
		_part(Vector3(WEST, -0.2, band.x), Vector3(EAST, 0, band.y), deck)
		_solid(Vector3(WEST, -0.2, band.x), Vector3(EAST, 0, band.y), "Deck")
	# Fundo do vão: o telhado de baixo, longe
	_part(Vector3(WEST - 2, DROP - 0.2, FRONT.y), Vector3(EAST + 2, DROP, BACK.x), "rubble" if present else "dark_wood")
	for i in 6:
		_block(Vector3(1.0 + i * 1.6, DROP + 0.4, FRONT.y + 1.0 + (i % 3) * 1.8), Vector3(0.5, 0.8, 0.5), "stone")
	# Parapeitos de pedra nas bordas do vão, com aberturas nas passarelas
	for z: float in [FRONT.y, BACK.x]:
		var x := WEST
		for walk: Vector2 in [WEST_WALK, EAST_WALK]:
			_parapet(Vector3(x, 0, z - 0.1), Vector3(walk.x, PARAPET, z + 0.1))
			x = walk.y
		_parapet(Vector3(x, 0, z - 0.1), Vector3(EAST, PARAPET, z + 0.1))
	# Bordas laterais e a de trás do terraço da frente
	_parapet(Vector3(WEST - 0.2, 0, FRONT.x), Vector3(WEST, PARAPET, FRONT.y))
	_parapet(Vector3(EAST, 0, FRONT.x), Vector3(EAST + 0.2, PARAPET, FRONT.y))
	_parapet(Vector3(STAIR_HOUSE.end.x, 0, FRONT.x - 0.2), Vector3(EAST, PARAPET, FRONT.x))
	_parapet(Vector3(WEST - 0.2, 0, BACK.x), Vector3(WEST, PARAPET, BACK.y))
	_parapet(Vector3(EAST, 0, BACK.x), Vector3(EAST + 0.2, PARAPET, BACK.y))
	for x: Vector2 in [Vector2(WEST, TOWER.position.x), Vector2(TOWER.end.x, EAST)]:
		_parapet(Vector3(x.x, 0, BACK.y), Vector3(x.y, PARAPET, BACK.y + 0.2))
	# Pilares sob as passarelas, que descem até o telhado de baixo
	for walk: Vector2 in [WEST_WALK, EAST_WALK]:
		for z: float in [FRONT.y + 0.15, BACK.x - 0.15]:
			_part(Vector3(walk.x - 0.15, DROP, z - 0.15), Vector3(walk.x + 0.05, 0, z + 0.15), "iron")
			_part(Vector3(walk.y - 0.05, DROP, z - 0.15), Vector3(walk.y + 0.15, 0, z + 0.15), "iron")


func _parapet(from: Vector3, to: Vector3) -> void:
	_part(from, to, "plaster_cream")
	_part(Vector3(from.x - 0.03, to.y, from.z - 0.03), Vector3(to.x + 0.03, to.y + 0.06, to.z + 0.03), "rubble" if present else "marble")
	_solid(from, Vector3(to.x, to.y + 0.06, to.z), "Parapet")


# --- Casinha da escada ------------------------------------------------------------------------

func _build_stair_house() -> void:
	var r := STAIR_HOUSE
	var wall := "plaster_cream" if not present else "rubble"
	_part(Vector3(r.position.x - 0.1, 0, r.position.y - 0.1), Vector3(r.position.x + 0.1, HOUSE_H, r.end.y), wall)
	_part(Vector3(r.end.x - 0.1, 0, r.position.y - 0.1), Vector3(r.end.x + 0.1, HOUSE_H, r.end.y), wall)
	_part(Vector3(r.position.x - 0.1, 0, r.position.y - 0.1), Vector3(r.end.x + 0.1, HOUSE_H, r.position.y + 0.1), wall)
	_solid(Vector3(r.position.x - 0.1, 0, r.position.y - 0.1), Vector3(r.position.x + 0.1, HOUSE_H, r.end.y), "Wall")
	_solid(Vector3(r.end.x - 0.1, 0, r.position.y - 0.1), Vector3(r.end.x + 0.1, HOUSE_H, r.end.y), "Wall")
	_solid(Vector3(r.position.x - 0.1, 0, r.position.y - 0.1), Vector3(r.end.x + 0.1, HOUSE_H, r.position.y + 0.1), "Wall")
	# Frente com a porta
	for x: Vector2 in [Vector2(r.position.x - 0.1, STAIR_DOOR.x), Vector2(STAIR_DOOR.y, r.end.x + 0.1)]:
		_part(Vector3(x.x, 0, r.end.y - 0.1), Vector3(x.y, HOUSE_H, r.end.y + 0.1), wall)
		_solid(Vector3(x.x, 0, r.end.y - 0.1), Vector3(x.y, HOUSE_H, r.end.y + 0.1), "Wall")
	_part(Vector3(STAIR_DOOR.x, DOOR_TOP, r.end.y - 0.1), Vector3(STAIR_DOOR.y, HOUSE_H, r.end.y + 0.1), wall)
	_solid(Vector3(STAIR_DOOR.x, DOOR_TOP, r.end.y - 0.1), Vector3(STAIR_DOOR.y, HOUSE_H, r.end.y + 0.1), "Lintel")
	for side: float in [STAIR_DOOR.x - 0.06, STAIR_DOOR.y]:
		_part(Vector3(side, 0, r.end.y - 0.12), Vector3(side + 0.06, DOOR_TOP + 0.06, r.end.y + 0.12), "dark_wood")
	_part(Vector3(r.position.x - 0.2, HOUSE_H, r.position.y - 0.2), Vector3(r.end.x + 0.2, HOUSE_H + 0.15, r.end.y + 0.2), "iron" if not present else "rubble")
	# Vão da escada em caracol, com o guarda-corpo em volta (sólido)
	var hole := STAIR_HOLE
	_part(hole + Vector3(-0.8, -0.19, -0.7), hole + Vector3(0.8, 0.005, 0.7), "dark")
	_cylinder(hole + Vector3(0, -2.0, 0), 0.05, 0.05, 3.0, "iron", Vector3.ZERO, 8)
	for i in 5:
		var step := _block(hole + Vector3(0.35, -0.15 - i * 0.2, 0), Vector3(0.7, 0.04, 0.25), "iron", Vector3(0, i * 40.0, 0))
		step.position = hole + Vector3(cos(deg_to_rad(i * 40.0)) * 0.35, -0.15 - i * 0.2, -sin(deg_to_rad(i * 40.0)) * 0.35)
	_part(hole + Vector3(-0.8, 0, 0.7), hole + Vector3(0.8, 0.95, 0.74), "iron")
	_part(hole + Vector3(0.8, 0, -0.7), hole + Vector3(0.84, 0.95, 0.74), "iron")
	_solid(hole + Vector3(-0.8, 0, 0.7), hole + Vector3(0.84, 0.95, 0.76), "StairRail")
	_solid(hole + Vector3(0.8, 0, -0.7), hole + Vector3(0.86, 0.95, 0.76), "StairRail")
	# O vão em si: não se anda sobre ele
	_solid(hole + Vector3(-0.8, 0, -0.7), hole + Vector3(0.8, 0.95, 0.7), "StairHole")


# --- Caixa d'água -----------------------------------------------------------------------------

func _build_tank() -> void:
	var r := TANK
	_part(Vector3(r.position.x, 0, r.position.y), Vector3(r.end.x, TANK_BASE, r.end.y), "stone")
	_solid(Vector3(r.position.x, 0, r.position.y), Vector3(r.end.x, TANK_TOP, r.end.y), "Tank")
	var metal := "copper" if not present else "iron"
	_part(Vector3(r.position.x + 0.05, TANK_BASE, r.position.y + 0.05), Vector3(r.end.x - 0.05, TANK_TOP, r.end.y - 0.05), metal)
	for y: float in [1.5, 2.2, 2.85]:
		_part(Vector3(r.position.x, y, r.position.y), Vector3(r.end.x, y + 0.06, r.end.y), "iron")
	_part(Vector3(r.position.x + 0.3, TANK_TOP, r.position.y + 0.3), Vector3(r.end.x - 0.3, TANK_TOP + 0.08, r.end.y - 0.3), "iron")
	# Ladrão da boia: sai da caixa e passa sobre o começo da passarela leste
	var pipe := Vector3(r.position.x + 0.2, TANK_TOP - 0.25, r.end.y)
	_part(pipe + Vector3(-0.04, -0.04, 0), Vector3(pipe.x + 0.04, pipe.y + 0.04, FRONT.y + 0.6), "iron")
	_part(Vector3(EAST_WALK.x + 0.45, pipe.y - 0.04, FRONT.y + 0.56), Vector3(pipe.x + 0.04, pipe.y + 0.04, FRONT.y + 0.64), "iron")
	# Cano do registro, descendo pela frente da base
	_part(Vector3(VALVE.x - 0.04, VALVE.y, r.end.y), Vector3(VALVE.x + 0.04, TANK_BASE + 0.1, r.end.y + 0.08), "iron")
	if present:
		# Ferrugem escorrida pela caixa
		for i in 4:
			_part(Vector3(r.position.x + 0.3 + i * 0.4, TANK_BASE, r.end.y - 0.04), Vector3(r.position.x + 0.36 + i * 0.4, TANK_TOP - 0.3, r.end.y - 0.03), "leather")


# --- Torre ------------------------------------------------------------------------------------

func _build_tower() -> void:
	var r := TOWER
	var wall := "wallpaper"
	var outside := "plaster_cream"
	_part(Vector3(r.position.x, -0.2, r.position.y), Vector3(r.end.x, 0, r.end.y), "floorboards")
	_solid(Vector3(r.position.x, -0.2, r.position.y), Vector3(r.end.x, 0, r.end.y), "Floor")
	_part(Vector3(r.position.x, TOWER_H, r.position.y), Vector3(r.end.x, TOWER_H + 0.2, r.end.y), "ceiling" if not present else "dark_wood")
	for x: float in [r.position.x, r.end.x]:
		_part(Vector3(x - 0.15, 0, r.position.y), Vector3(x + 0.15, TOWER_H, r.end.y), outside)
		_solid(Vector3(x - 0.15, 0, r.position.y), Vector3(x + 0.15, TOWER_H, r.end.y), "Wall")
	_part(Vector3(r.position.x, 0, r.end.y - 0.15), Vector3(r.end.x, TOWER_H, r.end.y + 0.15), outside)
	_solid(Vector3(r.position.x, 0, r.end.y - 0.15), Vector3(r.end.x, TOWER_H, r.end.y + 0.15), "Wall")
	var z := r.position.y
	for x: Vector2 in [Vector2(r.position.x, TOWER_DOOR.x), Vector2(TOWER_DOOR.y, r.end.x)]:
		_part(Vector3(x.x, 0, z - 0.15), Vector3(x.y, TOWER_H, z + 0.15), outside)
		_solid(Vector3(x.x, 0, z - 0.15), Vector3(x.y, TOWER_H, z + 0.15), "Wall")
	_part(Vector3(TOWER_DOOR.x, DOOR_TOP, z - 0.15), Vector3(TOWER_DOOR.y, TOWER_H, z + 0.15), outside)
	_solid(Vector3(TOWER_DOOR.x, DOOR_TOP, z - 0.15), Vector3(TOWER_DOOR.y, TOWER_H, z + 0.15), "Lintel")
	for side: float in [TOWER_DOOR.x - 0.08, TOWER_DOOR.y]:
		_part(Vector3(side, 0, z - 0.17), Vector3(side + 0.08, DOOR_TOP + 0.08, z + 0.17), "dark_wood")
	# Papel de parede por dentro
	_part(Vector3(r.position.x + 0.15, 0, r.end.y - 0.17), Vector3(r.end.x - 0.15, TOWER_H, r.end.y - 0.15), wall)
	# Telhado em pirâmide, acima do teto
	for i in 6:
		var inset := i * 0.45
		_part(Vector3(r.position.x - 0.3 + inset, TOWER_H + 0.2 + i * 0.35, r.position.y - 0.3 + inset),
			Vector3(r.end.x + 0.3 - inset, TOWER_H + 0.55 + i * 0.35, r.end.y + 0.3 - inset), "iron" if present else "copper")
	# Mostrador grande na fachada: disco e marcas das horas (os ponteiros são do nível)
	_cylinder(BIG_DIAL, BIG_RADIUS + 0.08, BIG_RADIUS + 0.08, 0.04, "brass" if not present else "iron", Vector3(-90, 0, 0), 32)
	_cylinder(BIG_DIAL + Vector3(0, 0, -0.04), BIG_RADIUS, BIG_RADIUS, 0.03, "ivory", Vector3(-90, 0, 0), 32)
	for h in 12:
		var angle := TAU * h / 12.0
		var at := BIG_DIAL + Vector3(sin(angle) * (BIG_RADIUS - 0.1), cos(angle) * (BIG_RADIUS - 0.1), -0.08)
		_block(at, Vector3(0.04, 0.12 if h % 3 == 0 else 0.07, 0.02), "lacquer", Vector3(0, 0, -rad_to_deg(angle)))


func _build_machine() -> void:
	var r := MACHINE
	var metal := "brass" if not present else "iron"
	_part(Vector3(r.position.x, 0, r.position.y), Vector3(r.end.x, MACHINE_H, r.end.y), "cast_iron")
	_solid(Vector3(r.position.x, 0, r.position.y), Vector3(r.end.x, MACHINE_H + 0.5, r.end.y), "Machine")
	# Engrenagens em cima do mecanismo
	for i in 3:
		var at := Vector3(r.position.x + 0.35 + i * 0.45, MACHINE_H + 0.25, r.position.y + 0.6)
		_cylinder(at + Vector3(0, -0.25, 0), 0.22 - i * 0.04, 0.22 - i * 0.04, 0.04, metal, Vector3(90, 0, 0), 16)
	# Mostrador de acerto (o disco; os ponteiros e a data são do nível)
	_part(SERVICE_DIAL + Vector3(-0.24, -0.3, 0.0), SERVICE_DIAL + Vector3(0.24, 0.24, 0.03), metal)
	_cylinder(SERVICE_DIAL + Vector3(0, 0, -0.005), SERVICE_RADIUS, SERVICE_RADIUS, 0.01, "ivory", Vector3(-90, 0, 0), 24)
	# Eixo que sobe até o mostrador grande
	_part(Vector3(4.97, MACHINE_H, r.position.y + 0.1), Vector3(5.03, 3.4, r.position.y + 0.16), "iron")
	_part(Vector3(4.97, 3.37, TOWER.position.y), Vector3(5.03, 3.43, r.position.y + 0.16), "iron")
	# Caixa do pêndulo encostada no fundo (a porta e o que há dentro são do nível)
	var c := CASE
	_part(Vector3(c.position.x, 0, c.position.y + 0.05), Vector3(c.end.x, CASE_H, c.end.y), "mahogany" if not present else "plank")
	_part(Vector3(c.position.x + 0.1, 0.25, c.position.y + 0.04), Vector3(c.end.x - 0.1, CASE_H - 0.25, c.position.y + 0.06), "dark")
	_solid(Vector3(c.position.x, 0, c.position.y), Vector3(c.end.x, CASE_H, c.end.y), "Case")
	_part(Vector3(c.position.x - 0.05, CASE_H, c.position.y - 0.05), Vector3(c.end.x + 0.05, CASE_H + 0.12, c.end.y + 0.05), "mahogany" if not present else "plank")


# --- Céu e luzes ------------------------------------------------------------------------------

func _build_sky() -> void:
	# A noite é o fundo do ambiente; ao longe, só a silhueta da cidade
	for i in 7:
		var x := -9.0 + i * 4.0
		var height := 1.0 + _random(i) * 4.0
		_part(Vector3(x, -6, 26), Vector3(x + 2.5, height, 28), "dark")


func _build_lights() -> void:
	if not present:
		_omni(Vector3(5.0, 3.6, 16.0), WARM, 1.8, 9.0, true)
		_omni(Vector3(1.5, 2.2, 1.5), WARM, 0.9, 4.0)
		_omni(Vector3(5.0, 2.6, 12.2), WARM, 1.2, 5.0)
		_spot(Vector3(-4, 9, -6), Vector3(5, 0, 8), MOON, 1.6, 30.0, 35.0)
	else:
		_spot(Vector3(-4, 9, -6), Vector3(5, 0, 8), MOON, 2.2, 30.0, 35.0)
		_omni(Vector3(5.0, 3.0, 16.0), MOON, 0.35, 8.0)
		_omni(Vector3(5.0, 2.0, 8.0), MOON, 0.3, 12.0)
