extends Node
## Autoload: troca de sala. Escurece a tela, abre a nova cena e posiciona as personagens.
## 2D: Helena e Lia mudam de sala juntas. 3D (pedido do Roberto, 04/11/2026): só a
## personagem ativa passa pela porta; a outra fica onde foi deixada, na sala dela.
## Cada cena tem os dois nós de personagem; o da que está em outra sala fica parado ali
## (a época dela está inativa) e não vale nada até ela voltar. Apertar Tab abre a sala
## da outra (`switch_to_away`).

const FADE_DURATION: float = 0.2

var _is_changing: bool = false
var _fade_rect: ColorRect
## Personagens que ficaram em outra sala: era -> {"scene", "position", "yaw"}.
var _away: Dictionary = {}


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 99
	add_child(layer)

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color.BLACK
	_fade_rect.modulate.a = 0.0
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade_rect)


func is_changing() -> bool:
	return _is_changing


## Vai para outra sala e coloca as duas personagens no ponto de entrada (2D).
func change_room(scene_path: String, spawn_name: String) -> void:
	await go_to(scene_path, func(room: Node) -> void: _place_at_spawn(room, spawn_name))


## Só `traveler_era` passa pela porta; quem estava na sala fica lá, no mesmo lugar.
func change_room_alone(scene_path: String, spawn_name: String, traveler_era: Era.Id) -> void:
	if _is_changing:
		return
	var room := get_tree().current_scene
	for motor in find_characters(room):
		if motor.era != traveler_era and not is_away(motor.era):
			_remember(motor, room.scene_file_path)
	_away.erase(traveler_era)
	await go_to(scene_path, func(new_room: Node) -> void:
		_place_at_spawn(new_room, spawn_name, traveler_era)
		_place_from_memory(new_room))


## A personagem desta época está em outra sala (não na que está aberta).
func is_away(era: Era.Id) -> bool:
	if not _away.has(era):
		return false
	var scene := get_tree().current_scene
	return scene == null or _away[era]["scene"] != scene.scene_file_path


## Troca de época quando a outra está em outra sala: guarda onde a ativa ficou,
## abre a sala da outra e a põe onde foi deixada.
func switch_to_away(era: Era.Id) -> void:
	if _is_changing or not is_away(era):
		return
	var room := get_tree().current_scene
	for motor in find_characters(room):
		if motor.era == EraManager.current_era:
			_remember(motor, room.scene_file_path)
	var target_scene: String = _away[era]["scene"]
	await go_to(target_scene, _place_from_memory, func() -> void: EraManager.set_era(era))


## Para o save: onde está cada personagem fora da sala aberta.
func away_to_dict() -> Dictionary:
	var result := {}
	for era: int in _away:
		var entry: Dictionary = _away[era]
		var at: Vector3 = entry["position"]
		result[Era.character_name(era)] = {"scene": entry["scene"], "x": at.x, "y": at.y, "z": at.z, "yaw": entry["yaw"]}
	return result


func load_away(data: Dictionary) -> void:
	_away.clear()
	for era: Era.Id in [Era.Id.PAST_1923, Era.Id.PRESENT]:
		var key := Era.character_name(era)
		if data.has(key):
			var entry: Dictionary = data[key]
			_away[era] = {"scene": entry["scene"], "position": Vector3(entry["x"], entry["y"], entry["z"]), "yaw": float(entry["yaw"])}


func clear_away() -> void:
	_away.clear()


## Abre a sala e chama `place_characters(sala)` antes de clarear a tela.
## `before_load` roda com a tela já escura, antes de abrir a cena (ex.: trocar a época,
## para os objetos da sala nova já nascerem na época certa).
func go_to(scene_path: String, place_characters: Callable, before_load: Callable = Callable()) -> void:
	if _is_changing:
		return
	_is_changing = true
	await _fade(1.0)
	if before_load.is_valid():
		before_load.call()
	get_tree().change_scene_to_file(scene_path)
	await get_tree().scene_changed
	place_characters.call(get_tree().current_scene)
	await _fade(0.0)
	_is_changing = false


## Personagens da sala: PlayerMotor (2D) ou FirstPersonMotor (3D).
static func find_characters(room: Node) -> Array[Node]:
	var result: Array[Node] = []
	for node in room.find_children("*", "", true, false):
		if node is PlayerMotor or node is FirstPersonMotor:
			result.append(node)
	return result


func _remember(motor: Node, scene_path: String) -> void:
	_away[motor.era] = {"scene": scene_path, "position": motor.get_save_position(), "yaw": motor.rotation.y}


## Quem ficou nesta sala volta ao lugar e ao jeito de olhar em que foi deixada.
func _place_from_memory(room: Node) -> void:
	for motor in find_characters(room):
		if not _away.has(motor.era) or _away[motor.era]["scene"] != room.scene_file_path:
			continue
		var entry: Dictionary = _away[motor.era]
		motor.global_position = entry["position"]
		motor.rotation.y = entry["yaw"]
		motor.velocity = Vector3.ZERO
		_away.erase(motor.era)


## Põe no ponto de entrada as duas personagens, ou só `only_era` (>= 0).
func _place_at_spawn(room: Node, spawn_name: String, only_era: int = -1) -> void:
	var spawn := room.find_child(spawn_name, true, false)
	if spawn == null:
		push_error("RoomManager: ponto de entrada '%s' não existe em %s" % [spawn_name, room.scene_file_path])
		return
	for motor in find_characters(room):
		if only_era >= 0 and motor.era != only_era:
			continue
		motor.global_position = spawn.global_position
		if motor is FirstPersonMotor:
			# Em 3D o marcador também diz para onde elas olham ao entrar
			motor.rotation.y = (spawn as Node3D).global_rotation.y
			motor.velocity = Vector3.ZERO
		else:
			motor.velocity = Vector2.ZERO


func _fade(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", alpha, FADE_DURATION)
	await tween.finished
