class_name TowerLevel3D
extends ChapterRoom3D
## Telhado e torre do relógio: caixa d'água (registro), relógio parado, pêndulo com a chave do
## gerente e os nomes riscados. As duas chegam pela escada em caracol atrás do piano do Saguão.
## Solução no GDD ("Andares de cima").

const ACTION := preload("res://scripts/interaction3d/interactable_3d.gd")
const DOOR := preload("res://scripts/interaction3d/door_3d.gd")
const ROOM := preload("res://scripts/puzzles/torre/tower_room_3d.gd")
const LOBBY := "res://scenes/rooms/saguao_3d.tscn"

const VALVE_CLOSED := "torre.registro.fechado"
## Onde Helena deixou os ponteiros, em minutos de 0 a 719 (0 = 12h00).
const HANDS := "torre.ponteiros"
const CASE_OPEN := "torre.pendulo.aberto"
const KEY_TAKEN := "torre.chave.gerente"
const DONE := "torre.concluida"
const KEY_ITEM := "chave_gerente"
## A hora em que o relógio parou (3h07) e a que ele marcava em 1923 antes de Helena mexer.
const STOPPED_AT := 187
const RUNNING_AT := 700
const NAMES := "Riscados na madeira, por dentro da caixa, cada um com uma letra diferente:\n\n" \
	+ "H. 14/03/1923\nO. 1923\nC.F. 1951\nM.S. 1979\nT.R. 2003\n\n" \
	+ "Embaixo de todos, um risco novo, fundo, que começa e não termina."

## Estado de uma passarela: firme, podre (afunda) ou caída (só o vão).
enum Walk { FIRM, ROTTEN, FALLEN }

var _walks: Dictionary = {}
var _leak: Node3D
var _hands: Array[Node3D] = []
var _case_doors: Array[Node3D] = []
var _names: Label3D
var _key: Node3D
var _pendulum: Node3D
var _swing := 0.0


func _ready() -> void:
	for present: bool in [false, true]:
		var world := make_world(ROOM, present)
		_build_access(world, present)
		_build_walks(world, present)
		_build_valve(world, present)
		_build_clock(world, present)
		_build_case(world, present)
	marker("DaEscada", Vector3(1.5, 0, 2.4), PI)
	_apply_state()
	WorldState.flag_changed.connect(_on_flag)
	super()


func _process(delta: float) -> void:
	# Em 1923 o relógio funciona: o pêndulo balança
	_swing += delta
	if _pendulum:
		_pendulum.rotation_degrees.z = sin(_swing * PI) * 8.0


static func hands_at(present: bool) -> int:
	var fallback := STOPPED_AT if present else RUNNING_AT
	return posmod(int(WorldState.get_flag(HANDS, fallback)), ClockUI.DAY)


# --- Escada em caracol -----------------------------------------------------------------------

func _build_access(world: Node3D, present: bool) -> void:
	area(DOOR, world, "DescerEscada", ROOM.STAIR_HOLE + Vector3(0, 0.6, 0.8), Vector3(1.6, 1.0, 0.1), {
		"target_scene": LOBBY, "target_spawn": "DaTorre",
		"prompt_text": "Descer ao Saguão", "available_in": 1 if present else 0})


# --- Passarelas ---------------------------------------------------------------------------------

func _build_walks(world: Node3D, present: bool) -> void:
	for side: String in ["Oeste", "Leste"]:
		var span: Vector2 = ROOM.WEST_WALK if side == "Oeste" else ROOM.EAST_WALK
		var states := {}
		for state: Walk in ([Walk.FIRM] if not present else [Walk.FIRM, Walk.ROTTEN, Walk.FALLEN]):
			states[state] = _build_walk(world, present, span, state, side)
		_walks[str(present) + side] = states
		if present:
			for end: float in [ROOM.FRONT.y - 0.12, ROOM.BACK.x + 0.12]:
				var look := area(ACTION, world, "Passarela" + side + ("Frente" if end < 8 else "Fundo"),
					Vector3((span.x + span.y) / 2.0, 0.7, end), Vector3(1.0, 0.8, 0.12), {
						"prompt_text": "Examinar passarela", "available_in": 1})
				look.interacted.connect(_examine_walk.bind(side))
	if not present:
		# Em 1923, o ladrão da boia derrama água sobre o começo da passarela leste
		_leak = Node3D.new()
		_leak.name = "Vazamento"
		world.add_child(_leak)
		var x := ROOM.EAST_WALK.x + 0.45
		box(_leak, Vector3(x, (ROOM.TANK_TOP - 0.25) / 2.0, ROOM.FRONT.y + 0.6), Vector3(0.03, ROOM.TANK_TOP - 0.25, 0.03), "ice", false)
		box(_leak, Vector3(x, 0.005, ROOM.FRONT.y + 1.2), Vector3(0.8, 0.01, 1.6), "ice", false)


func _build_walk(world: Node3D, present: bool, span: Vector2, state: Walk, side: String) -> Node3D:
	var holder := Node3D.new()
	holder.name = "Passarela%s%d" % [side, state]
	world.add_child(holder)
	var z0 := ROOM.FRONT.y
	var z1 := ROOM.BACK.x
	var wood := "oak" if not present else "plank"
	var metal := "iron"
	var mid := (span.x + span.y) / 2.0
	var width := span.y - span.x
	if state == Walk.FIRM:
		_solid_box(holder, Vector3(mid, -0.1, (z0 + z1) / 2.0), Vector3(width, 0.2, z1 - z0), "")
		for i in 15:
			var z := z0 + 0.2 + i * 0.4
			box(holder, Vector3(mid, -0.03, z), Vector3(width, 0.06, 0.36), wood, present)
		for x: float in [span.x, span.y]:
			# Guarda-corpo dos dois lados (sólido)
			_solid_box(holder, Vector3(x, 0.5, (z0 + z1) / 2.0), Vector3(0.06, 1.0, z1 - z0), "")
			box(holder, Vector3(x, 1.0, (z0 + z1) / 2.0), Vector3(0.05, 0.05, z1 - z0), metal, present)
			box(holder, Vector3(x, 0.5, (z0 + z1) / 2.0), Vector3(0.03, 0.03, z1 - z0), metal, present)
			for k in 7:
				box(holder, Vector3(x, 0.5, z0 + 0.1 + k * 0.97), Vector3(0.04, 1.0, 0.04), metal, present)
		return holder
	# Podre ou caída: barreira de tábuas quebradas nas duas pontas, e o vão no meio
	for end: float in [z0 + 0.15, z1 - 0.15]:
		var barrier := _solid_box(holder, Vector3(mid, 0.5, end), Vector3(width, 1.0, 0.3), "")
		for k in 4:
			var board := box(barrier, Vector3(-0.35 + k * 0.23, 0.0, 0.0), Vector3(0.12, 0.95, 0.04), wood, present)
			board.rotation_degrees = Vector3(0, 0, -25 + k * 17)
		box(barrier, Vector3(0, 0.2, 0), Vector3(width, 0.05, 0.05), metal, present).rotation_degrees.z = 12
	if state == Walk.ROTTEN:
		# Tábuas afundadas e falhadas, que se veem mas não aguentam ninguém
		for i in 15:
			if i % 3 == 1:
				continue
			var plank := box(holder, Vector3(mid, -0.06 - (i % 4) * 0.05, z0 + 0.2 + i * 0.4), Vector3(width, 0.05, 0.3), wood, present)
			plank.rotation_degrees.x = (i % 5 - 2) * 6.0
	else:
		for z: float in [z0 + 0.5, z1 - 0.5]:
			box(holder, Vector3(mid, -0.05, z), Vector3(width, 0.05, 0.3), wood, present).rotation_degrees.x = 20
		for i in 4:
			box(holder, Vector3(mid - 0.3 + i * 0.2, ROOM.DROP + 0.05, z0 + 1.5 + i * 1.0), Vector3(0.12, 0.05, 1.4), wood, present).rotation_degrees.y = i * 30
	return holder


func _examine_walk(_by: FirstPersonMotor, side: String) -> void:
	match _walk_state(true, side):
		Walk.FIRM:
			_say("As vigas deste lado estão secas e firmes.")
		Walk.FALLEN:
			_say("Deste lado, as vigas caíram no telhado de baixo. Só sobrou o vão.")
		_:
			_say("A madeira afunda sob o pé, encharcada de cem anos de goteira. Não aguenta.")


func _walk_state(present: bool, side: String) -> Walk:
	if not present:
		return Walk.FIRM
	var closed := WorldState.is_set(VALVE_CLOSED)
	if side == "Oeste":
		return Walk.FIRM if closed else Walk.ROTTEN
	return Walk.FALLEN if closed else Walk.ROTTEN


# --- Registro da caixa d'água -----------------------------------------------------------------

func _build_valve(world: Node3D, present: bool) -> void:
	var wheel := Node3D.new()
	wheel.position = ROOM.VALVE + Vector3(0, 0, 0.08)
	world.add_child(wheel)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.1
	torus.outer_radius = 0.13
	ring.mesh = torus
	ring.rotation_degrees.x = 90
	ring.material_override = HotelMaterials.get_material("brass" if not present else "iron", present)
	wheel.add_child(ring)
	box(wheel, Vector3.ZERO, Vector3(0.24, 0.02, 0.02), "iron", present)
	box(wheel, Vector3.ZERO, Vector3(0.02, 0.24, 0.02), "iron", present)
	var turn := area(ACTION, world, "Registro", ROOM.VALVE + Vector3(0, 0, 0.16), Vector3(0.4, 0.4, 0.1), {
		"prompt_text": "Girar registro" if not present else "Examinar registro", "available_in": 1 if present else 0})
	turn.interacted.connect(_use_valve.bind(present))


func _use_valve(_by: FirstPersonMotor, present: bool) -> void:
	var closed := WorldState.is_set(VALVE_CLOSED)
	if present:
		_say("O registro da caixa d'água está fechado, preso de ferrugem." if closed \
			else "O registro está aberto, travado de ferrugem. Uma mancha escura desce da caixa até as vigas do telhado.")
	elif closed:
		_say("O registro já está fechado. A boia não vaza mais.")
	else:
		WorldState.set_flag(VALVE_CLOSED)
		_say("Você gira o volante até o fim. A água que escorria do ladrão sobre as vigas para de cair.")


# --- Relógio ----------------------------------------------------------------------------------

func _build_clock(world: Node3D, present: bool) -> void:
	for dial: Array in [[ROOM.BIG_DIAL + Vector3(0, 0, -0.09), ROOM.BIG_RADIUS], [ROOM.SERVICE_DIAL + Vector3(0, 0, -0.02), ROOM.SERVICE_RADIUS]]:
		var at: Vector3 = dial[0]
		var radius: float = dial[1]
		var pair := Node3D.new()
		pair.position = at
		world.add_child(pair)
		for kind: String in ["Horas", "Minutos"]:
			var pivot := Node3D.new()
			pivot.name = kind
			pair.add_child(pivot)
			var length := radius * (0.55 if kind == "Horas" else 0.85)
			var thick := radius * (0.09 if kind == "Horas" else 0.06)
			box(pivot, Vector3(0, length / 2.0, -0.005 if kind == "Horas" else -0.012), Vector3(thick, length, 0.008), "lacquer", present)
		_hands.append(pair)
		pair.set_meta("present", present)
	# Janelinha da data, embaixo do centro do mostrador de acerto
	var date := label(world, "14/03", ROOM.SERVICE_DIAL + Vector3(0, -0.085, -0.02), 14)
	date.rotation_degrees.y = 180
	date.modulate = Color("#2A1A1A")
	var read := area(ACTION, world, "MostradorAcerto", ROOM.SERVICE_DIAL + Vector3(0, -0.03, -0.1), Vector3(0.5, 0.55, 0.1), {
		"prompt_text": "Acertar o relógio" if not present else "Examinar mostrador", "available_in": 1 if present else 0})
	read.interacted.connect(_use_dial.bind(present))


func _use_dial(_by: FirstPersonMotor, present: bool) -> void:
	if present:
		_say("O mostrador de acerto parou em %s. Na janelinha da data: 14/03." % ClockUI.describe(hands_at(true)))
		return
	var ui := ClockUI.open(get_tree(), hands_at(false))
	ui.confirmed.connect(func(minutes: int) -> void:
		WorldState.set_flag(HANDS, minutes)
		if minutes == STOPPED_AT and not WorldState.is_set(CASE_OPEN):
			WorldState.set_flag(CASE_OPEN)
			_say("Os ponteiros param em 3h07. Algo estala no fundo da torre: o ferrolho da caixa do pêndulo se solta.")
		else:
			_say("Os ponteiros ficam em %s." % ClockUI.describe(minutes)))


# --- Caixa do pêndulo -------------------------------------------------------------------------

func _build_case(world: Node3D, present: bool) -> void:
	var c := ROOM.CASE
	var front := c.position.y
	var hinge := Node3D.new()
	hinge.name = "PortaPendulo"
	hinge.position = Vector3(c.position.x, 0, front - 0.03)
	world.add_child(hinge)
	var door := _solid_box(hinge, Vector3(c.size.x / 2.0, 1.2, 0), Vector3(c.size.x, 2.1, 0.05), "mahogany" if not present else "plank", present)
	box(door, Vector3(0, 0.25, -0.03), Vector3(c.size.x - 0.3, 1.2, 0.01), "glass" if not present else "dark", present)
	_case_doors.append(hinge)
	if not present:
		_pendulum = Node3D.new()
		_pendulum.name = "Pendulo"
		_pendulum.position = Vector3(c.position.x + c.size.x / 2.0, 2.1, front + 0.03)
		world.add_child(_pendulum)
		box(_pendulum, Vector3(0, -0.6, 0), Vector3(0.02, 1.2, 0.01), "brass", false)
		var bob := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = 0.13
		disc.bottom_radius = 0.13
		disc.height = 0.02
		bob.mesh = disc
		bob.rotation_degrees.x = 90
		bob.position = Vector3(0, -1.25, 0)
		bob.material_override = HotelMaterials.get_material("brass", false)
		_pendulum.add_child(bob)
		_key = key_visual(world, Vector3(c.position.x + 0.35, 1.0, front + 0.02), false)
		_key.rotation_degrees.z = 90
	else:
		_names = label(world, "H. 14/03/1923\nO. 1923\nC.F. 1951\nM.S. 1979\nT.R. 2003\n|", Vector3(c.position.x + c.size.x / 2.0, 1.3, front + 0.03), 22)
		_names.rotation_degrees.y = 180
		_names.modulate = Color("#B8A888")
	var open := area(ACTION, world, "CaixaPendulo", Vector3(c.position.x + c.size.x / 2.0, 1.2, front - 0.12), Vector3(1.3, 2.0, 0.1), {
		"prompt_text": "Examinar caixa do pêndulo", "available_in": 1 if present else 0})
	open.interacted.connect(_use_case.bind(present))


func _use_case(by: FirstPersonMotor, present: bool) -> void:
	var opened := WorldState.is_set(CASE_OPEN)
	if present:
		if not opened:
			_say("A portinhola da caixa do pêndulo está emperrada. Pelo vidro imundo, riscos na madeira, ilegíveis.")
			return
		NoteUI.open(get_tree(), "Caixa do pêndulo", NAMES)
		WorldState.set_flag(DONE)
	elif not opened:
		_say("A caixa do pêndulo está trancada. Não há fechadura: só um ferrolho preso ao mecanismo dos ponteiros.")
	elif WorldState.is_set(KEY_TAKEN):
		_say("Dentro da caixa, só o pêndulo, indo e voltando.")
	elif by.get_held_item() != "":
		_say("Pendurada atrás do pêndulo há uma chave com a etiqueta GERÊNCIA. A mão está ocupada.")
	else:
		by.set_held_item(KEY_ITEM)
		WorldState.set_flag(KEY_TAKEN)
		_say("Você pega a chave pendurada atrás do pêndulo. A etiqueta diz GERÊNCIA.")


# --- Estado -----------------------------------------------------------------------------------

func _apply_state() -> void:
	for key: String in _walks:
		var present := key.begins_with("true")
		var side := key.trim_prefix("true" if present else "false")
		var wanted := _walk_state(present, side)
		var states: Dictionary = _walks[key]
		for state: Walk in states:
			_set_solid(states[state], state == wanted)
	_leak.visible = not WorldState.is_set(VALVE_CLOSED)
	for pair: Node3D in _hands:
		var minutes := hands_at(pair.get_meta("present"))
		(pair.get_node("Minutos") as Node3D).rotation.z = TAU * (minutes % 60) / 60.0
		(pair.get_node("Horas") as Node3D).rotation.z = TAU * minutes / float(ClockUI.DAY)
	var opened := WorldState.is_set(CASE_OPEN)
	for hinge: Node3D in _case_doors:
		hinge.rotation_degrees.y = 100.0 if opened else 0.0
	_names.visible = opened
	_key.visible = opened and not WorldState.is_set(KEY_TAKEN)


func _solid_box(parent: Node3D, center: Vector3, size: Vector3, role: String, present: bool = false) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = center
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	if role != "":
		box(body, Vector3.ZERO, size, role, present)
	return body


## Liga ou desliga uma peça com todas as colisões dentro dela.
func _set_solid(node: Node3D, solid: bool) -> void:
	node.visible = solid
	for body in node.find_children("*", "StaticBody3D", true, false):
		for child in body.get_children():
			if child is CollisionShape3D:
				child.disabled = not solid


func _on_flag(key: String, _value: Variant) -> void:
	if key.begins_with("torre."):
		_apply_state()


func _say(message: String) -> void:
	get_tree().call_group("hud", "show_message", message)
