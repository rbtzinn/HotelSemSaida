class_name BallroomLevel3D
extends ChapterRoom3D
## Salão de baile (3º andar): cabine como degrau, contrapeso da cortina e partitura na banqueta.
## Helena chega pela escada principal de 1923; Lia, pelo alçapão da cabine parada no 2º andar e
## pela escada do poço. Solução no GDD ("Andares de cima").

const ACTION := preload("res://scripts/interaction3d/interactable_3d.gd")
const MESSAGE := preload("res://scripts/interaction3d/message_interactable_3d.gd")
const DOOR := preload("res://scripts/interaction3d/door_3d.gd")
const FLOOR_2 := "res://scenes/rooms/quartos_3d.tscn"

## Onde a cabine do elevador principal está: 1 = 2º andar, 2 = 3º andar, 3 = casa de máquinas
## (sem a flag, depois da chave de Bento). Só Helena a chama, pelas botoeiras dos andares.
const LIFT_FLOOR := "saguao.elevador.andar"
const LIFT_POWER := "saguao.elevador.no_alto"
const LIFT_DEFAULT := 3
const THIS_FLOOR := 2
const COUNTERWEIGHT := "salao.contrapeso.solto"
const SCORE_SAVED := "salao.partitura.guardada"
const SCORE_READ := "salao.partitura.lida"
const DONE := "salao.concluido"
const SCORE_ITEM := "partitura"

const ROOM := preload("res://scripts/puzzles/salao/ballroom_room_3d.gd")
const SCORE_TITLE := "Valsa da Aurora"
const SCORE_1923 := "Partitura para piano, sem dedilhado. As quatro primeiras notas voltam no fim de cada página, como um refrão."
const SCORE_TODAY := "A partitura amarelou, mas a pauta se lê. A lápis, sobre as quatro primeiras notas: 3 · 1 · 5 · 6.\n\n" \
	+ "Na margem, a mesma letra do caderno do 214: «Contar a partir da tecla de latão do piano do Saguão. C.F., 1951.»"

var _cabs: Array[Node3D] = []
var _landing_door: StaticBody3D
var _hanging: Array[Node3D] = []
var _fallen_1923: StaticBody3D
var _mound: StaticBody3D
var _score_on_stand: MeshInstance3D
var _score_in_bench: MeshInstance3D
var _dust: MeshInstance3D


func _ready() -> void:
	for present: bool in [false, true]:
		var world := make_world(ROOM, present)
		_build_access(world, present)
		_build_landing(world, present)
		_build_counterweight(world, present)
		_build_score(world, present)
	marker("DaEscada", Vector3(3.0, 0, 2.9), PI)
	marker("DoPoco", Vector3(16.25, 0, 1.2), PI)
	_apply_state()
	WorldState.flag_changed.connect(_on_flag)
	super()


static func lift_floor() -> int:
	return int(WorldState.get_flag(LIFT_FLOOR, LIFT_DEFAULT))


# --- Acesso: escada (1923) e poço (hoje) ----------------------------------------------------

func _build_access(world: Node3D, present: bool) -> void:
	if not present:
		area(DOOR, world, "DescerEscada", Vector3(3.0, 0.9, 2.05), Vector3(3.0, 1.0, 0.15), {
			"target_scene": FLOOR_2, "target_spawn": "DaEscada",
			"prompt_text": "Descer ao 2º andar", "available_in": 0})
	else:
		area(MESSAGE, world, "EscadaDesabada", Vector3(3.0, 0.9, 2.05), Vector3(3.0, 1.0, 0.15), {
			"prompt_text": "Examinar escada", "available_in": 1,
			"message": "A escada principal desabou. Dois andares abaixo, só escombros."})
		area(DOOR, world, "DescerPoco", Vector3(16.48, 0.9, 0.62), Vector3(0.6, 1.4, 0.15), {
			"target_scene": FLOOR_2, "target_spawn": "DoPoco",
			"prompt_text": "Descer pela escada do poço", "available_in": 1})
		area(MESSAGE, world, "EscadaPartida", Vector3(16.48, -0.2, 0.62), Vector3(0.6, 0.6, 0.15), {
			"prompt_text": "Examinar escada do poço", "available_in": 1,
			"message": "Abaixo do patamar faltam degraus num trecho de dois metros. Para descer, dá para se pendurar e soltar; para subir, não."})


# --- Porta de pavimento e botoeira ------------------------------------------------------------

func _build_landing(world: Node3D, present: bool) -> void:
	_cabs.append(ElevatorCab3D.build(world, present))
	if not present:
		_landing_door = StaticBody3D.new()
		_landing_door.name = "PortaPavimento"
		_landing_door.position = Vector3(16.25, 1.15, ROOM.NORTH)
		var shape := BoxShape3D.new()
		shape.size = Vector3(1.0, 2.3, 0.08)
		var collision := CollisionShape3D.new()
		collision.shape = shape
		_landing_door.add_child(collision)
		world.add_child(_landing_door)
		for i in 9:
			box(_landing_door, Vector3(-0.45 + i * 0.1125, 0, 0), Vector3(0.025, 2.28, 0.03), "iron", false)
		for y: float in [-1.1, 0.0, 1.1]:
			box(_landing_door, Vector3(0, y, 0), Vector3(1.0, 0.04, 0.04), "iron", false)
		var button := area(ACTION, world, "Botoeira", Vector3(17.3, 1.2, ROOM.NORTH + 0.18), Vector3(0.3, 0.5, 0.12), {
			"prompt_text": "Chamar o elevador", "available_in": 0})
		button.interacted.connect(_call_cab)
		var gate := area(ACTION, world, "PavimentoFechado", Vector3(16.25, 1.2, ROOM.NORTH + 0.15), Vector3(1.0, 2.0, 0.1), {
			"prompt_text": "Examinar porta do elevador", "available_in": 0})
		gate.interacted.connect(func(_by: FirstPersonMotor) -> void:
			_say("A porta do elevador está fechada. Pelas grades, a cabine está bem aqui." if lift_floor() == THIS_FLOOR \
				else "A porta do elevador está fechada. Pelas grades, só os cabos no escuro."))
	else:
		# Hoje a porta foi arrombada: a grade ficou torta, encostada na parede do poço
		var bent := Node3D.new()
		bent.name = "GradeArrombada"
		bent.position = Vector3(17.02, 1.1, 1.2)
		bent.rotation_degrees = Vector3(0, 90, 6)
		world.add_child(bent)
		for i in 7:
			box(bent, Vector3(-0.36 + i * 0.12, 0, 0), Vector3(0.025, 2.1, 0.03), "iron", true)
		for y: float in [-1.0, 0.1, 0.95]:
			box(bent, Vector3(0, y, 0), Vector3(0.8, 0.04, 0.04), "iron", true)


func _call_cab(_by: FirstPersonMotor) -> void:
	if not WorldState.is_set(LIFT_POWER):
		_say("Você aperta o botão. Nada acende: o elevador está desligado lá embaixo.")
	elif lift_floor() == THIS_FLOOR:
		_say("A cabine já está parada neste andar.")
	else:
		WorldState.set_flag(LIFT_FLOOR, THIS_FLOOR)
		_say("Os cabos rangem no poço. A cabine sobe e para no 3º andar.")


# --- Contrapeso da cortina --------------------------------------------------------------------

func _build_counterweight(world: Node3D, present: bool) -> void:
	var hanging := Node3D.new()
	hanging.name = "SacoPendurado"
	hanging.position = Vector3(ROOM.SANDBAG.x, 3.6, ROOM.SANDBAG.z)
	world.add_child(hanging)
	box(hanging, Vector3.ZERO, Vector3(0.6, 0.8, 0.55), "flour", present)
	box(hanging, Vector3(0, 0.45, 0), Vector3(0.15, 0.1, 0.15), "leather", present)
	var rope := ROOM.PULLEY.y - 0.12 - 3.6 - 0.4
	box(hanging, Vector3(0, 0.4 + rope / 2.0, 0), Vector3(0.02, rope, 0.02), "leather", present)
	_hanging.append(hanging)
	if not present:
		_fallen_1923 = _solid_box(world, "SacoCaido", ROOM.SANDBAG + Vector3(0, 0.175, 0), Vector3(0.8, 0.35, 0.65), "flour", false)
		var cleat := area(ACTION, world, "Malagueta", ROOM.CLEAT + Vector3(0, 0, -0.12), Vector3(0.4, 0.4, 0.12), {
			"prompt_text": "Examinar corda do contrapeso", "available_in": 0})
		cleat.interacted.connect(_release_counterweight)
	else:
		# O saco endureceu num monte do tamanho de um degrau, encostado no palco
		_mound = _solid_box(world, "MonteDeAreia", Vector3(ROOM.SANDBAG.x, 0.3, ROOM.STAGE_FRONT - 0.5), Vector3(1.0, 0.6, 1.0), "rubble", true)
		# Restos do saco de lona por cima do monte
		var cloth := box(_mound, Vector3(0.05, 0.31, -0.05), Vector3(0.8, 0.03, 0.7), "tarp", true)
		cloth.rotation_degrees.y = 12.0
		area(MESSAGE, world, "PalcoAlto", Vector3((ROOM.STEPS_X.x + ROOM.STEPS_X.y) / 2.0, 0.7, ROOM.STAGE_FRONT - 0.08),
			Vector3(1.4, 0.9, 0.12), {
				"prompt_text": "Examinar palco", "available_in": 1,
				"message": "A escadinha do palco desabou. A borda fica na altura do peito, alta demais para subir."})
		area(MESSAGE, world, "Malagueta", ROOM.CLEAT + Vector3(0, 0, -0.12), Vector3(0.4, 0.4, 0.12), {
			"prompt_text": "Examinar corda", "available_in": 1,
			"message": "A corda apodreceu presa na malagueta do pilar. Ela sobe até uma polia no alto, sobre a frente do palco."})


func _release_counterweight(_by: FirstPersonMotor) -> void:
	if WorldState.is_set(COUNTERWEIGHT):
		_say("A corda está solta. O saco de areia ficou no chão, na frente do palco.")
		return
	WorldState.set_flag(COUNTERWEIGHT)
	_say("Você solta a corda da malagueta. O saco de areia do contrapeso despenca na frente do palco, e a cortina lateral desce um palmo.")


# --- Partitura --------------------------------------------------------------------------------

func _build_score(world: Node3D, present: bool) -> void:
	var stand := ROOM.MUSIC_STAND
	var bench := ROOM.BENCH
	if not present:
		_score_on_stand = box(world, stand + Vector3(0, 1.2, 0.03), Vector3(0.42, 0.3, 0.01), "paper", false)
		_score_on_stand.rotation_degrees.x = 20.0
		_score_in_bench = box(world, bench + Vector3(0, 0.51, 0), Vector3(0.28, 0.01, 0.36), "paper", false)
		var take := area(ACTION, world, "Estante", stand + Vector3(0, 1.2, -0.16), Vector3(0.6, 0.45, 0.16), {
			"prompt_text": "Examinar estante do maestro", "available_in": 0})
		take.interacted.connect(_stand_1923)
		var seat := area(ACTION, world, "Banqueta", bench + Vector3(0, 0.55, 0), Vector3(0.5, 0.15, 0.9), {
			"prompt_text": "Abrir banqueta do piano", "available_in": 0})
		seat.interacted.connect(_bench_1923)
	else:
		_dust = box(world, stand + Vector3(0, 1.2, 0.03), Vector3(0.36, 0.05, 0.03), "rubble", true)
		_dust.rotation_degrees.x = 20.0
		var look := area(ACTION, world, "Estante", stand + Vector3(0, 1.2, -0.16), Vector3(0.6, 0.45, 0.16), {
			"prompt_text": "Examinar estante do maestro", "available_in": 1})
		look.interacted.connect(func(_by: FirstPersonMotor) -> void:
			_say("A estante do maestro está vazia." if WorldState.is_set(SCORE_SAVED) \
				else "Na estante, um montinho de pó amarelado que um dia foi papel."))
		var seat := area(ACTION, world, "Banqueta", bench + Vector3(0, 0.55, 0), Vector3(0.5, 0.15, 0.9), {
			"prompt_text": "Abrir banqueta do piano", "available_in": 1})
		seat.interacted.connect(_bench_today)


func _stand_1923(by: FirstPersonMotor) -> void:
	var held := by.get_held_item()
	if held == SCORE_ITEM:
		by.set_held_item("")
		_say("Você devolve a partitura à estante do maestro.")
	elif WorldState.is_set(SCORE_SAVED) or not _score_on_stand.visible:
		_say("A estante do maestro está vazia.")
	elif held != "":
		NoteUI.open(get_tree(), SCORE_TITLE, SCORE_1923 + "\n\nA mão está ocupada.", ScoreSheet.texture(false))
	else:
		by.set_held_item(SCORE_ITEM)
		_apply_state()
		NoteUI.open(get_tree(), SCORE_TITLE, SCORE_1923, ScoreSheet.texture(false))


func _bench_1923(by: FirstPersonMotor) -> void:
	var held := by.get_held_item()
	if held == SCORE_ITEM:
		by.set_held_item("")
		WorldState.set_flag(SCORE_SAVED)
		_say("Você guarda a partitura dentro da banqueta forrada e fecha o tampo.")
	elif WorldState.is_set(SCORE_SAVED):
		if held != "":
			_say("A partitura está dentro da banqueta. A mão está ocupada.")
		else:
			WorldState.set_flag(SCORE_SAVED, false)
			by.set_held_item(SCORE_ITEM)
			_say("Você tira a partitura da banqueta.")
	else:
		_say("Dentro da banqueta forrada, só um pedaço de breu e poeira.")


func _bench_today(_by: FirstPersonMotor) -> void:
	if not WorldState.is_set(SCORE_SAVED):
		_say("Dentro da banqueta, o forro foi comido pelas traças. Nada mais.")
		return
	NoteUI.open(get_tree(), SCORE_TITLE, SCORE_TODAY, ScoreSheet.texture(true))
	WorldState.set_flag(SCORE_READ)
	WorldState.set_flag(DONE)


# --- Estado ---------------------------------------------------------------------------------

func _apply_state() -> void:
	var here := lift_floor() == THIS_FLOOR
	for cab: Node3D in _cabs:
		cab.visible = here
	var released := WorldState.is_set(COUNTERWEIGHT)
	for bag: Node3D in _hanging:
		bag.visible = not released
	_set_solid(_fallen_1923, released)
	_set_solid(_mound, released)
	var saved := WorldState.is_set(SCORE_SAVED)
	_score_in_bench.visible = saved
	_score_on_stand.visible = not saved and str(WorldState.get_flag("helena.mao", "")) != SCORE_ITEM
	_dust.visible = not saved


func _solid_box(world: Node3D, node_name: String, center: Vector3, size: Vector3, role: String, present: bool) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = center
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	world.add_child(body)
	box(body, Vector3.ZERO, size, role, present)
	return body


func _set_solid(body: StaticBody3D, solid: bool) -> void:
	body.visible = solid
	for child in body.get_children():
		if child is CollisionShape3D:
			child.disabled = not solid


func _on_flag(key: String, _value: Variant) -> void:
	if key.begins_with("salao.") or key in [LIFT_FLOOR, "helena.mao"]:
		_apply_state()


func _say(message: String) -> void:
	get_tree().call_group("hud", "show_message", message)
