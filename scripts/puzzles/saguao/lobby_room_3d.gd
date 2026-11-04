@tool
class_name LobbyRoom3D
extends Node3D
## Saguão em 3D, em blocos: a mesma planta do Saguão 2D (LobbyRoom), levantada em paredes.
## As medidas vêm da planta em pixels (640x360) a 32 px por metro, então as duas versões
## continuam batendo. `present = true` monta a versão em ruínas (hoje).
## Os blocos são recriados a cada carregamento e não ficam salvos na cena.

## Liga a versão em ruínas (hoje).
@export var present: bool = false:
	set(value):
		present = value
		if is_inside_tree():
			_build()

const PX: float = 1.0 / 32.0
const HEIGHT: float = 6.0
const WALL: float = 0.2
const DOOR_HEIGHT: float = 2.4

var _materials: Dictionary = {}


func _ready() -> void:
	_build()


func _build() -> void:
	for child in get_children():
		if child.has_meta("generated"):
			remove_child(child)
			child.queue_free()
	_materials.clear()
	_build_shell()
	_build_stairs()
	_build_reception()
	_build_elevator()
	_build_columns()
	_build_chandelier()
	_build_piano()
	_build_lights()


func _color(role: String) -> Color:
	var past := {
		"wall": Color("#3B1A1F"), "trim": Color("#C9973B"), "floor": Color("#1F3A2E"),
		"object": Color("#6B1E2A"), "wood": Color("#4A2A1A"), "dark": Color("#120C0E"),
		"ceiling": Color("#2A1416"), "paper": Color("#E8DCC0"),
	}
	var today := {
		"wall": Color("#1C2630"), "trim": Color("#3A4A58"), "floor": Color("#3E4A2F"),
		"object": Color("#6E8596"), "wood": Color("#3A3128"), "dark": Color("#0B0F14"),
		"ceiling": Color("#141B22"), "paper": Color("#8C8A70"),
	}
	return (today if present else past)[role]


func _material(role: String) -> StandardMaterial3D:
	if not _materials.has(role):
		var material := StandardMaterial3D.new()
		material.albedo_color = _color(role)
		material.roughness = 0.9
		if not present:
			# 1923: leitura retrô, sem filtragem
			material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		_materials[role] = material
	return _materials[role]


## Paredes, piso, teto e os vãos da porta da Cozinha (oeste) e da entrada (sul).
func _build_shell() -> void:
	var west := 16 * PX
	var east := 624 * PX
	var north := 64 * PX
	var south := 344 * PX
	_box("Floor", Vector3(0, -0.2, 0), Vector3(640 * PX, 0, 360 * PX), "floor")
	_box("Ceiling", Vector3(0, HEIGHT, 0), Vector3(640 * PX, HEIGHT + 0.2, 360 * PX), "ceiling")
	_box("WallNorth", Vector3(0, 0, north - WALL), Vector3(640 * PX, HEIGHT, north), "wall")
	_box("WallEast", Vector3(east, 0, north), Vector3(east + WALL, HEIGHT, south), "wall")
	# Oeste, com o vão da porta da Cozinha (z 208..256 px)
	var door_z0 := 208 * PX
	var door_z1 := 256 * PX
	_box("WallWest", Vector3(west - WALL, 0, north), Vector3(west, HEIGHT, door_z0), "wall")
	_box("WallWest", Vector3(west - WALL, 0, door_z1), Vector3(west, HEIGHT, south), "wall")
	_box("WallWest", Vector3(west - WALL, DOOR_HEIGHT, door_z0), Vector3(west, HEIGHT, door_z1), "wall")
	_box("KitchenDoor", Vector3(west - WALL, 0, door_z0), Vector3(west - 0.05, DOOR_HEIGHT, door_z1), "wood" if present else "object")
	# Sul, com a entrada principal (x 288..352 px)
	var gate_x0 := 288 * PX
	var gate_x1 := 352 * PX
	_box("WallSouth", Vector3(0, 0, south), Vector3(gate_x0, HEIGHT, south + WALL), "wall")
	_box("WallSouth", Vector3(gate_x1, 0, south), Vector3(640 * PX, HEIGHT, south + WALL), "wall")
	_box("WallSouth", Vector3(gate_x0, 3.0, south), Vector3(gate_x1, HEIGHT, south + WALL), "wall")
	if present:
		# Tábuas pregadas
		for i in 4:
			_box("Plank", Vector3(gate_x0 - 0.1, 0.4 + i * 0.6, south - 0.08), Vector3(gate_x1 + 0.1, 0.6 + i * 0.6, south), "wood")
		_box("Entrance", Vector3(gate_x0, 0, south + 0.05), Vector3(gate_x1, 3.0, south + WALL), "dark")
	else:
		# Porta giratória: quatro folhas de vidro em cruz, presa
		_box("Entrance", Vector3(gate_x0, 0, south + 0.05), Vector3(gate_x1, 3.0, south + WALL), "dark")
		_box("RevolvingDoor", Vector3(gate_x0 + 0.1, 0, south - 0.02), Vector3(gate_x1 - 0.1, 2.8, south + 0.02), "trim")
		_box("RevolvingDoor", Vector3((gate_x0 + gate_x1) / 2.0 - 0.02, 0, south - 0.9), Vector3((gate_x0 + gate_x1) / 2.0 + 0.02, 2.8, south + 0.04), "trim")
	# Rodapé e sanca
	_box("Baseboard", Vector3(west, 0, north), Vector3(east, 0.15, north + 0.04), "trim", false)
	_box("Cornice", Vector3(west, HEIGHT - 0.3, north), Vector3(east, HEIGHT - 0.2, north + 0.08), "trim", false)


## Escada a noroeste (x 48..144, z 64..112 px). Em 1923 sobe; hoje, escombros.
func _build_stairs() -> void:
	var x0 := 48 * PX
	var x1 := 144 * PX
	var z_front := 112 * PX
	if present:
		_box("Rubble", Vector3(x0, 0, 64 * PX), Vector3(x1, 1.2, z_front), "trim")
		_box("Rubble", Vector3(x0 + 0.3, 1.2, 64 * PX), Vector3(x0 + 1.6, 2.0, z_front - 0.4), "wood")
		_box("Rubble", Vector3(x0 + 1.8, 0, z_front - 0.2), Vector3(x1 - 0.2, 0.6, z_front + 0.5), "trim")
	else:
		var steps := 8
		var depth := (z_front - 64 * PX) / steps
		for i in steps:
			var z1 := z_front - i * depth
			_box("Step", Vector3(x0, 0, z1 - depth), Vector3(x1, 0.22 * (i + 1), z1), "object" if i % 2 == 0 else "wood")
		_box("Banister", Vector3(x1, 0, 64 * PX), Vector3(x1 + 0.08, 2.6, z_front), "trim")


## Recepção: balcão com o livro; na parede de trás, quadro de chaves e cofre.
func _build_reception() -> void:
	var z0 := 96 * PX
	var z1 := 128 * PX
	_box("Counter", Vector3(224 * PX, 0, z0), Vector3(416 * PX, 1.05, z1), "object" if not present else "trim")
	_box("CounterTop", Vector3(224 * PX - 0.05, 1.05, z0 - 0.05), Vector3(416 * PX + 0.05, 1.12, z1 + 0.05), "trim" if not present else "wood")
	var book_center := Vector3(320 * PX, 1.12, 112 * PX)
	_box("GuestBook", book_center - Vector3(0.3, 0, 0.2), book_center + Vector3(0.3, 0.06, 0.2), "paper", false)

	var wall := 64 * PX
	_box("KeyRack", Vector3(232 * PX, 1.3, wall), Vector3(272 * PX, 2.2, wall + 0.06), "wood", false)
	for row in 2:
		for col in 6:
			var hook := Vector3(232 * PX + 0.12 + col * 0.18, 2.0 - row * 0.42, wall + 0.06)
			_box("Hook", hook, hook + Vector3(0.04, 0.04, 0.05), "trim", false)
			if not present:
				_box("Key", hook + Vector3(0, -0.16, 0.02), hook + Vector3(0.04, 0, 0.04), "trim", false)
	_box("Safe", Vector3(372 * PX, 0.2, wall), Vector3(408 * PX, 1.3, wall + 0.5), "dark")
	_box("SafeDial", Vector3(388 * PX, 0.7, wall + 0.5), Vector3(392 * PX, 0.82, wall + 0.54), "trim", false)


## Elevador na parede norte (x 496..544 px). Em 1923, grade fechada; hoje, portas arrombadas.
func _build_elevator() -> void:
	var wall := 64 * PX
	var x0 := 496 * PX
	var x1 := 544 * PX
	_box("ElevatorFrame", Vector3(x0 - 0.2, 0, wall), Vector3(x1 + 0.2, 2.9, wall + 0.05), "trim", false)
	_box("ElevatorShaft", Vector3(x0, 0, wall + 0.05), Vector3(x1, 2.6, wall + 0.07), "dark", false)
	if present:
		_box("ElevatorDoor", Vector3(x0, 0, wall + 0.07), Vector3(x0 + 0.3, 2.6, wall + 0.12), "object")
		_box("ElevatorDoor", Vector3(x1 - 0.25, 0, wall + 0.07), Vector3(x1, 2.3, wall + 0.15), "object")
	else:
		for i in 7:
			var x := x0 + 0.08 + i * 0.22
			_box("Gate", Vector3(x, 0, wall + 0.07), Vector3(x + 0.04, 2.6, wall + 0.11), "trim", false)
		_box("GateSolid", Vector3(x0, 0, wall + 0.07), Vector3(x1, 2.6, wall + 0.11), "trim", true, false)


func _build_columns() -> void:
	for base: Vector2 in [Vector2(160, 176), Vector2(480, 176), Vector2(160, 304), Vector2(480, 304)]:
		_cylinder("Column", Vector3(base.x * PX, 0, base.y * PX), 0.35, HEIGHT, "trim")


## Lustre: em 1923 pendurado sobre o tapete; hoje caído no meio do salão.
func _build_chandelier() -> void:
	var center := Vector3(320 * PX, 0, 224 * PX)
	if present:
		_box("FallenChandelier", center + Vector3(-1.8, 0, -0.9), center + Vector3(1.8, 0.7, 0.9), "trim")
		# A coroa de latão, à vista na frente do monte
		_cylinder("ChandelierCrown", center + Vector3(0, 0, 1.1), 0.6, 0.35, "wood")
	else:
		_box("Rug", center + Vector3(-2, 0, -1), center + Vector3(2, 0.02, 1), "object", false)
		_cylinder("Chandelier", center + Vector3(0, 4.2, 0), 1.1, 0.5, "trim", false)
		_cylinder("ChandelierChain", center + Vector3(0, 4.7, 0), 0.04, HEIGHT - 4.7, "trim", false)


## Piano de cauda a leste. Hoje, coberto por uma lona.
func _build_piano() -> void:
	var center := Vector3(544 * PX, 0, 256 * PX)
	if present:
		_box("Piano", center + Vector3(-1.35, 0, -0.85), center + Vector3(1.35, 1.15, 0.85), "object")
	else:
		_box("Piano", center + Vector3(-1.25, 0.6, -0.75), center + Vector3(1.25, 1.05, 0.75), "dark")
		_box("PianoKeys", center + Vector3(-1.25, 0.75, 0.75), center + Vector3(-0.1, 0.8, 0.95), "paper", false)
		for leg: Vector3 in [Vector3(-1.1, 0, -0.6), Vector3(1.1, 0, -0.6), Vector3(-1.1, 0, 0.6)]:
			_box("PianoLeg", center + leg, center + leg + Vector3(0.1, 0.6, 0.1), "dark")


func _build_lights() -> void:
	if present:
		# Frestas: luz fria e fraca
		_light(Vector3(4, 4.5, 3), Color("#9FB4C8"), 0.6, 9.0)
		_light(Vector3(17, 3.5, 9.5), Color("#9FB4C8"), 0.4, 7.0)
	else:
		_light(Vector3(10, 4.0, 7), Color("#F2D49B"), 2.2, 12.0)
		for spot: Vector3 in [Vector3(2, 2.6, 2.4), Vector3(18, 2.6, 2.4), Vector3(2, 2.6, 10.3), Vector3(18, 2.6, 10.3)]:
			_light(spot, Color("#F2D49B"), 0.9, 6.0)


## Caixa entre dois cantos (metros). Com `solid`, ganha colisão.
func _box(box_name: String, from: Vector3, to: Vector3, role: String, solid: bool = true, visible_mesh: bool = true) -> void:
	var size := (to - from).abs()
	var center := (from + to) / 2.0
	var node := StaticBody3D.new() if solid else Node3D.new()
	node.name = box_name
	node.position = center
	if visible_mesh:
		var mesh := BoxMesh.new()
		mesh.size = size
		var instance := MeshInstance3D.new()
		instance.mesh = mesh
		instance.material_override = _material(role)
		node.add_child(instance)
	if solid:
		var shape := BoxShape3D.new()
		shape.size = size
		var collision := CollisionShape3D.new()
		collision.shape = shape
		node.add_child(collision)
	_add_generated(node)


## Cilindro em pé com a base em `base`.
func _cylinder(cylinder_name: String, base: Vector3, radius: float, height: float, role: String, solid: bool = true) -> void:
	var node := StaticBody3D.new() if solid else Node3D.new()
	node.name = cylinder_name
	node.position = base + Vector3(0, height / 2.0, 0)
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = _material(role)
	node.add_child(instance)
	if solid:
		var shape := CylinderShape3D.new()
		shape.radius = radius
		shape.height = height
		var collision := CollisionShape3D.new()
		collision.shape = shape
		node.add_child(collision)
	_add_generated(node)


func _light(at: Vector3, color: Color, energy: float, light_range: float) -> void:
	var light := OmniLight3D.new()
	light.name = "Light"
	light.position = at
	light.light_color = color
	light.light_energy = energy
	light.omni_range = light_range
	_add_generated(light)


func _add_generated(node: Node) -> void:
	node.set_meta("generated", true)
	add_child(node)
