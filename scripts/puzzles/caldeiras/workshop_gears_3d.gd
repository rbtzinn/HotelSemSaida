extends Node3D
## Peças sobressalentes de Helena e transmissão manual da portinhola F-2.
const MODEL := preload("res://scripts/puzzles/caldeiras/gear_model_3d.gd")
const PICKUP := preload("res://scripts/interaction3d/item_pickup_3d.gd")
const SOCKET := preload("res://scripts/interaction3d/item_use_3d.gd")
const CONTROL := preload("res://scripts/interaction3d/interactable_3d.gd")
const NOTE := preload("res://scripts/interaction3d/note_interactable_3d.gd")
const OPEN := "caldeiras.f2.inspecao.aberta"
const IDS := [MODEL.PINION, MODEL.CROWN]
const NAMES := ["pinhão", "coroa"]

var _present: bool
var _low: Array[MeshInstance3D] = []
var _high: Array[MeshInstance3D] = []
var _drive: Array[MeshInstance3D] = []
var _crank: Node3D
var _shutter: MeshInstance3D

func install(room: ChapterRoom3D, world: Node3D, present: bool) -> void:
	_present = present
	for i in IDS.size():
		_build_spare(room, i)
		_build_axle(room, i)
	# Três cortes de lima na quina identificam a bancada da fotografia de Marta.
	for i in 3:
		var cut := room.box(self, Vector3(15.47+i*0.065, 1.002, 1.42), Vector3(0.016, 0.008, 0.19), "dark", present)
		cut.rotation_degrees.y = -18
	if present:
		room.box(self, Vector3(14.64, 1.37, 0.015), Vector3(1.9, 0.065, 0.023), "rubble", true)
		var trace := room.box(self, Vector3(14.65, 1.42, 0.018), Vector3(1.75, 0.019, 0.016), "rubble", true)
		trace.rotation_degrees.z = 1.1
	var badge := room.label(self, "F-2  ·  INSPEÇÃO", Vector3(15.39, 0.78, 2.74), 28)
	badge.rotation.y = -PI/2
	_install_hatch(room, world)
	_refresh(false)
	WorldState.flag_changed.connect(_on_flag)

func _build_spare(room: ChapterRoom3D, i: int) -> void:
	var x := 14.19+i*0.88
	var low := Vector3(x, 0.81, 0.16)
	var high := Vector3(x, 1.95, 0.16)
	for at: Vector3 in [low, high]:
		room.box(self, at-Vector3(0, 0, 0.125), Vector3(0.38, 0.32, 0.07), "oak", _present)
		room.box(self, at-Vector3(0, 0, 0.045), Vector3(0.042, 0.042, 0.18), "iron", _present)
	_low.append(_gear(i, low))
	_high.append(_gear(i, high))
	var size := Vector3(0.51, 0.51, 0.28)
	if _present:
		room.area(PICKUP, self, "Reserva%d" % i, high, size, {
			"available_in": 1, "item_id": IDS[i], "taken_flag": _flag(i, "recuperada"),
			"required_flag": _flag(i, "guardada"), "prompt_text": "Retirar " + NAMES[i]
		})
	else:
		room.area(PICKUP, self, "Peca%d" % i, low, size, {
			"available_in": 0, "item_id": IDS[i], "taken_flag": _flag(i, "retirada"),
			"prompt_text": "Pegar " + NAMES[i]
		})
		room.area(SOCKET, self, "Suporte%d" % i, high, size, {
			"available_in": 0, "accepted_item": IDS[i], "result_flag": _flag(i, "guardada"),
			"prompt_text": "Examinar suporte superior", "idle_message": "O pino tem a medida do " + NAMES[i] + ".",
			"success_message": "A peça fica pendurada no suporte de cima."
		})

func _build_axle(room: ChapterRoom3D, i: int) -> void:
	# Distância entre centros = soma dos raios primitivos de 12 e 20 dentes.
	var at := Vector3(15.73, 1.41, 2.58+i*0.352)
	room.box(self, at+Vector3(0.22, -0.20, 0), Vector3(0.20, 0.42, 0.13), "cast_iron", _present)
	room.box(self, at+Vector3(0.10, 0, 0), Vector3(0.28, 0.058+0.030*i, 0.058+0.030*i), "brass", _present)
	var gear := _gear(i, at)
	gear.rotation.y = -PI/2
	if i == 1:
		gear.rotate_object_local(Vector3.BACK, PI/20)
	_drive.append(gear)
	if _present:
		room.area(SOCKET, self, "Eixo%d" % i, at, Vector3(0.23, 0.37, 0.31), {
			"available_in": 1, "accepted_item": IDS[i], "result_flag": _flag(i, "montada"),
			"prompt_text": "Examinar eixo do " + NAMES[i], "idle_message": "A chaveta só assenta no cubo do " + NAMES[i] + ".",
			"success_message": "Os dentes assentam no eixo."
		})
	if i == 0:
		_crank = Node3D.new()
		_crank.position = at+Vector3(-0.11, 0, 0)
		add_child(_crank)
		room.box(self, at+Vector3(-0.055, 0, 0), Vector3(0.12, 0.05, 0.05), "iron", _present)
		room.box(_crank, Vector3(0, 0.14, 0), Vector3(0.05, 0.32, 0.055), "brass", _present)
		room.box(_crank, Vector3(-0.065, 0.30, 0), Vector3(0.16, 0.075, 0.075), "oak", _present)
		if _present:
			var control := room.area(CONTROL, self, "Manivela", _crank.position+Vector3(-0.065, 0.30, 0),
				Vector3(0.26, 0.17, 0.22), {"available_in":1, "done_flag":OPEN, "prompt_text":"Girar manivela da F-2"})
			control.interacted.connect(_turn)

func _install_hatch(room: ChapterRoom3D, world: Node3D) -> void:
	# Caixa de visita presa ao casco da segunda caldeira, voltada para o corredor.
	var at := Vector3(3.38, 1.52, 8.15)
	for y: float in [-0.32, 0.32]:
		room.box(world, at+Vector3(0, y, 0), Vector3(0.56, 0.08, 0.8), "iron", _present)
	for z: float in [-0.37, 0.37]:
		room.box(world, at+Vector3(0, 0, z), Vector3(0.56, 0.58, 0.07), "cast_iron", _present)
	room.box(world, at-Vector3(0.13, 0, 0), Vector3(0.06, 0.58, 0.70), "dark", _present)
	for i in 4:
		room.box(world, at+Vector3(-0.075, -0.19+0.11*i, 0), Vector3(0.06, 0.043, 0.60), "copper", _present)
	var body := StaticBody3D.new()
	body.position = at
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.56, 0.72, 0.80)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	world.add_child(body)
	_shutter = room.box(world, at+Vector3(0.30, 0, 0), Vector3(0.048, 0.61, 0.72), "iron", _present)
	var plate := room.label(_shutter, "F-2", Vector3(0.026, 0, 0), 45)
	plate.rotation.y = PI/2
	if _present:
		room.area(NOTE, world, "InspecaoF2", Vector3(3.71, 1.52, 8.15), Vector3(0.13, 0.56, 0.68), {
			"available_in":1, "required_flag":OPEN, "prompt_text":"Examinar a inspeção da F-2",
			"title":"Fornalha F-2 · Caixa de inspeção",
			"text":"A haste de cima vem da admissão. Contando desde a articulação, a luz passa por dois furos escuros antes de pegar na borda polida do terceiro.\n\nA haste da chaminé entra pelo lado contrário. Nela só há um furo escuro entre a articulação e o assento polido. Os dois assentos ficam na mesma vertical, sobre o ferrolho da caixa de limpeza."
		})

func _gear(i: int, at: Vector3) -> MeshInstance3D:
	var gear := MeshInstance3D.new()
	gear.mesh = MODEL.mesh_for(IDS[i])
	gear.position = at
	gear.material_override = HotelMaterials.get_material("copper" if i == 0 else "brass", _present)
	add_child(gear)
	return gear

func _flag(i: int, action: String) -> String:
	return "caldeiras.f2.%s.%s" % [IDS[i], action]

func _turn(_by: FirstPersonMotor) -> void:
	for i in IDS.size():
		if not WorldState.is_set(_flag(i, "montada")):
			get_tree().call_group("hud", "show_message", "A manivela gira em falso. A haste da F-2 continua parada.")
			return
	WorldState.set_flag(OPEN)
	get_tree().call_group("hud", "show_message", "A haste corre pela parede. Do lado das caldeiras vem o baque da portinhola F-2.")

func _on_flag(key: String, _value: Variant) -> void:
	if key.begins_with("caldeiras.f2."):
		_refresh(key == OPEN)

func _refresh(animate: bool) -> void:
	for i in IDS.size():
		_low[i].visible = not _present and not WorldState.is_set(_flag(i, "retirada"))
		_high[i].visible = WorldState.is_set(_flag(i, "guardada")) and (not _present or not WorldState.is_set(_flag(i, "recuperada")))
		_drive[i].visible = not _present or WorldState.is_set(_flag(i, "montada"))
	if _present and WorldState.is_set(OPEN):
		if animate:
			var tween := create_tween().set_parallel(true)
			tween.tween_property(_crank, "rotation:x", TAU, 0.95)
			tween.tween_method(_rotate_drive, 0.0, TAU, 0.95)
			tween.tween_property(_shutter, "position:y", 2.18, 0.95)
		else:
			_shutter.position.y = 2.18
			_rotate_drive(TAU)

func _rotate_drive(angle: float) -> void:
	var facing := Basis(Vector3.UP, -PI/2)
	_drive[0].basis = facing * Basis(Vector3.BACK, -angle)
	_drive[1].basis = facing * Basis(Vector3.BACK, PI/20 + angle*12.0/20.0)
