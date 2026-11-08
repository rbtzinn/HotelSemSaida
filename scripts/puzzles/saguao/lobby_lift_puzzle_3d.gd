extends Node
## O número do gancho identifica a chave, inclusive ao salvar com ela na mão.

const ACTION := preload("res://scripts/interaction3d/interactable_3d.gd")
const NOTE := preload("res://scripts/interaction3d/note_interactable_3d.gd")
const RAISED := "saguao.elevador.no_alto"
const HOOK := "saguao.quadro.gancho"
const BAG := "saguao.bolsa.marta"
const STAFF := ["Otília", "Amaral", "Rosa", "Abel", "Celina", "Ivo",
		"Nair", "Inês", "Bento", "Raul", "Alice", "Rui"]
const RACK_KEY := "chave_quadro"
const LANDING := Vector3(16.48, 0, 2.55)
const LADDER := Vector3(16.48, 0, 1.47)
const BOTTOM := Vector3(16.24, LobbyRoom3D.PIT_FLOOR, 1.12)

var past_car: Node3D
var present_car: Node3D
var gate: StaticBody3D
var grille_view: Area3D
var keys: Array[Node3D] = []
var inserted: Node3D
var marta_key: Node3D
var key_pickup: Area3D


func install(room: ChapterRoom3D) -> void:
	var past := room.get_node("World1923") as Node3D
	var today := room.get_node("WorldToday") as Node3D
	past_car = past.get_node("Cabin")
	present_car = today.get_node("Cabin")
	for i in STAFF.size():
		var hook := LobbyRoom3D.RACK + Vector3(-0.5 + (i % 6) * 0.2, 0.22 - floori(i / 6.0) * 0.44, 0.11)
		var plate := room.label(today, STAFF[i], hook + Vector3(0, 0.09, -0.038), 19)
		plate.modulate = Color("#33231C")
		var target := hook + Vector3(0, -0.095, 0.03)
		var size := Vector3(0.196, 0.39, 0.09)
		var slot := room.area(ACTION, past, "Gancho%d" % (i+1), target, size, {
			"prompt_text": "Examinar gancho %d" % (i+1),
			"available_in": 0,
		})
		slot.interacted.connect(_use_hook.bind(i+1))
		room.area(NOTE, today, "Chapa%d" % (i+1), target, size, {
			"title": "Quadro da recepção",
			"text": "Sob o verniz descascado do gancho %02d lê-se um nome.\n\n%s." % [i+1, STAFF[i]],
			"prompt_text": "Ler chapa %02d" % (i+1),
			"available_in": 1,
		})
		var key := room.key_visual(past, hook + Vector3(0, -0.112, -0.008), false)
		key.basis = Basis(Vector3.BACK, -PI/2) * Basis(Vector3.RIGHT, PI/2)
		keys.append(key)
	var panel := Vector3(LobbyRoom3D.ELEVATOR.y+0.45, 1.32, LobbyRoom3D.NORTH+0.07)
	inserted = room.key_visual(past, panel, false)
	inserted.rotation_degrees.y = 90
	var lock := room.area(ACTION, past, "PainelElevador", panel, Vector3(0.34, 0.47, 0.13), {
		"prompt_text": "Girar chave do elevador",
		"available_in": 0,
		"done_flag": RAISED,
	})
	lock.interacted.connect(_turn_key)
	_make_pit(room, today)
	_restore()
	WorldState.flag_changed.connect(_on_flag)


func _make_pit(room: ChapterRoom3D, today: Node3D) -> void:
	gate = StaticBody3D.new()
	gate.name = "GradeBaixa"
	gate.position = Vector3(16.25, 1.28, 1.99)
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.70, 2.58, 0.10)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	gate.add_child(collision)
	today.add_child(gate)
	for i in 8:
		room.box(gate, Vector3(-0.75+i*0.21, 0, 0), Vector3(0.022, 2.55, 0.025), "iron", true)
	room.box(gate, Vector3(0, 0.02, 0), Vector3(1.68, 0.045, 0.04), "iron", true)
	grille_view = room.area(preload("res://scripts/interaction3d/message_interactable_3d.gd"), today, "OlharGrade", Vector3(16.26, 1.2, 2.12), Vector3(1.10, 2.16, 0.08), {
		"prompt_text": "Espiar pela grade",
		"message": "A cabine cedeu sobre o poço. Pela fresta no piso dá para ver uma alça de couro presa no ferro.",
		"available_in": 1,
		"done_flag": RAISED,
	})
	# A correia sai da bolsa, passa pela guia e fica entalada na soleira.
	var at := Vector3(15.72, -1.70, 0.57)
	room.box(today, at+Vector3(-0.13, 0.36, 0), Vector3(0.38, 0.055, 0.08), "iron", true)
	for x: float in [-0.13, 0.13]:
		room.box(today, at+Vector3(x, 0.23, 0), Vector3(0.03, 0.3, 0.035), "leather", true)
	room.box(today, at+Vector3(0, 0.38, 0), Vector3(0.29, 0.035, 0.04), "leather", true)
	room.box(today, at, Vector3(0.43, 0.27, 0.23), "leather", true)
	var bag_body := StaticBody3D.new()
	bag_body.position = at
	var bag_shape := BoxShape3D.new()
	bag_shape.size = Vector3(0.43, 0.27, 0.23)
	var bag_collision := CollisionShape3D.new()
	bag_collision.shape = bag_shape
	bag_body.add_child(bag_collision)
	today.add_child(bag_body)
	room.box(today, at+Vector3(0, 0.06, 0.115), Vector3(0.41, 0.13, 0.025), "leather", true)
	room.box(today, at+Vector3(0, -0.025, 0.132), Vector3(0.034, 0.135, 0.018), "leather", true)
	room.box(today, at+Vector3(0, -0.01, 0.143), Vector3(0.048, 0.034, 0.012), "brass", true)
	var tag := room.box(today, at+Vector3(0.13, 0.042, 0.143), Vector3(0.09, 0.058, 0.008), "paper", true)
	tag.rotation_degrees.z = -12
	var initials := room.label(tag, "M.S.", Vector3(0, 0, 0.006), 13)
	initials.modulate = Color("#33251E")
	var strap := PackedVector3Array([at+Vector3(-0.21, 0, 0), Vector3(15.45, -0.61, 1.25),
		Vector3(15.49, -0.20, 1.90), Vector3(15.89, 0.03, 2.06), Vector3(16.05, 0.024, 2.17)])
	for i in range(strap.size()-1):
		var start := strap[i]
		var end := strap[i+1]
		var strip := room.box(today, (start+end)*0.5, Vector3(0.038, 0.012, start.distance_to(end)), "leather", true)
		strip.look_at(end)
	room.box(today, strap[-1], Vector3(0.050, 0.018, 0.035), "brass", true)
	room.area(preload("res://scripts/puzzles/saguao/marta_bag_3d.gd"), today, "BolsaMarta", at+Vector3(0, 0.02, 0.10),
		Vector3(0.55, 0.42, 0.32), {
			"prompt_text":"Examinar bolsa de câmera", "title":"Bolsa de Marta Siqueira · 1979",
			"photograph":preload("res://art/biblioteca/marta_f2_1979.jpg"), "available_in":1, "required_flag":RAISED})
	# A chave miúda pendurada na etiqueta, até Lia soltá-la. A área fica na frente da bolsa e só
	# existe enquanto a chave estiver lá e a bolsa já tiver sido examinada.
	marta_key = room.key_visual(today, at+Vector3(0.13, -0.03, 0.15), true)
	marta_key.scale = Vector3.ONE * 0.5
	marta_key.rotation_degrees.z = -80
	key_pickup = room.area(preload("res://scripts/interaction3d/item_pickup_3d.gd"), today, "ChaveMiuda",
		at+Vector3(0.13, -0.03, 0.31), Vector3(0.2, 0.2, 0.1), {
			"prompt_text": "Pegar chave miúda", "item_id": MartaBag3D.KEY, "taken_flag": MartaBag3D.TAKEN,
			"required_flag": BAG, "available_in": 1})
	# Subida pela escada do poço até o 2º andar (depois da bolsa, que aponta o caminho)
	room.area(preload("res://scripts/interaction3d/door_3d.gd"), today, "SubirAndar", Vector3(16.42, 2.1, 2.08),
		Vector3(0.96, 0.9, 0.12), {
			"target_scene": "res://scenes/rooms/quartos_3d.tscn", "target_spawn": "DoPoco",
			"prompt_text": "Subir pela escada do poço", "available_in": 1, "required_flag": BAG})
	var down := room.area(ACTION, today, "DescerPoco", Vector3(16.42, 0.83, 2.08), Vector3(0.96, 1.10, 0.12), {
		"prompt_text": "Descer pela escada do poço",
		"available_in": 1,
		"required_flag": RAISED,
	})
	var up := room.area(ACTION, today, "SubirPoco", Vector3(16.94, -1.58, 1.47), Vector3(0.18, 1.45, 0.68), {
		"prompt_text": "Subir ao Saguão",
		"available_in": 1,
		"required_flag": RAISED,
	})
	down.interacted.connect(func(by: FirstPersonMotor) -> void:
		by.begin_traversal(PackedVector3Array([LANDING, LADDER, Vector3(LADDER.x, BOTTOM.y, LADDER.z), BOTTOM])))
	up.interacted.connect(func(by: FirstPersonMotor) -> void:
		by.begin_traversal(PackedVector3Array([Vector3(LADDER.x, BOTTOM.y, LADDER.z), LADDER, LANDING])))


func _use_hook(by: FirstPersonMotor, number: int) -> void:
	var hand := by.get_held_item()
	var taken := int(WorldState.get_flag(HOOK, 0))
	if hand == RACK_KEY and number == taken:
		by.set_held_item("")
		WorldState.set_flag(HOOK, 0)
		_say("A chave volta ao gancho %02d." % number)
	elif hand != "":
		_say("O gancho ainda tem sua chave." if hand == RACK_KEY else "A mão está ocupada.")
	elif number != taken and not WorldState.is_set(RAISED):
		WorldState.set_flag(HOOK, number)
		by.set_held_item(RACK_KEY)
		_say("Helena pega a chave do gancho %02d." % number)
	else:
		_say("O gancho está vazio." if number == taken else "A chave está pendurada no lugar.")


func _turn_key(by: FirstPersonMotor) -> void:
	if by.get_held_item() != RACK_KEY:
		_say("Há um rasgo de chave abaixo da botoeira.")
	elif int(WorldState.get_flag(HOOK, 0)) != STAFF.find("Bento")+1:
		_say("A chave entra, mas não gira.")
	else:
		by.set_held_item("")
		WorldState.set_flag(RAISED)
		_say("A cabine sobe vazia. A chave fica presa no painel.")


func _restore() -> void:
	var raised := WorldState.is_set(RAISED)
	past_car.position.y = 3.55 if raised else 0.0
	present_car.position.y = past_car.position.y
	gate.position.y = 4.77 if raised else 1.28
	grille_view.collision_layer = 0 if raised else FirstPersonMotor.INTERACT_LAYER
	inserted.visible = raised
	_show_marta_key()
	_show_keys()


func _show_keys() -> void:
	var taken := int(WorldState.get_flag(HOOK, 0))
	for i in keys.size():
		keys[i].visible = i+1 != taken


func _on_flag(key: String, _value: Variant) -> void:
	if key == HOOK:
		_show_keys()
	elif key == MartaBag3D.TAKEN or key == BAG:
		_show_marta_key()
	elif key == RAISED:
		present_car.position.y = 3.55
		gate.position.y = 4.77
		grille_view.collision_layer = 0
		inserted.show()
		var lift := past_car.create_tween()
		lift.tween_property(past_car, "position:y", 3.55, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _show_marta_key() -> void:
	var there := not WorldState.is_set(MartaBag3D.TAKEN)
	marta_key.visible = there
	# Fora de uso, a área não pode tapar a bolsa na mira
	key_pickup.collision_layer = FirstPersonMotor.INTERACT_LAYER if there and WorldState.is_set(BAG) else 0


func _say(message: String) -> void:
	get_tree().call_group("hud", "show_message", message)
