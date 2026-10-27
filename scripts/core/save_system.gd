extends Node
## Autoload: salva e carrega o jogo em JSON (flags do WorldState, época ativa,
## sala atual e posição das duas personagens).
## Teclas provisórias: F2 salva, F3 carrega. Depois viram opções do menu de pausa.

const SAVE_PATH: String = "user://save.json"
const SAVE_VERSION: int = 1


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("quick_save"):
		get_viewport().set_input_as_handled()
		save_game()
	elif event.is_action_pressed("quick_load"):
		get_viewport().set_input_as_handled()
		load_game()


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> bool:
	# No meio do fade a época ainda vai mudar; espera a troca terminar
	if EraManager.is_switching():
		return false
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path.is_empty():
		push_error("SaveSystem: nenhuma sala aberta para salvar")
		return false

	var characters := {}
	for motor in _find_characters(scene):
		characters[Era.character_name(motor.era)] = {"x": motor.position.x, "y": motor.position.y}

	var data := {
		"version": SAVE_VERSION,
		"scene": scene.scene_file_path,
		"era": EraManager.current_era,
		"world_state": WorldState.to_dict(),
		"characters": characters,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveSystem: não consegui salvar em %s" % SAVE_PATH)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	_notify("Jogo salvo.")
	return true


## Recarrega a sala salva do zero, para que todo objeto leia as flags no _ready.
func load_game() -> bool:
	if EraManager.is_switching():
		return false
	if not has_save():
		_notify("Nenhum jogo salvo.")
		return false
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not data is Dictionary or int(data.get("version", 0)) != SAVE_VERSION:
		push_error("SaveSystem: arquivo de save inválido em %s" % SAVE_PATH)
		return false

	# Flags e época antes de abrir a sala, para os objetos já nascerem no estado certo
	WorldState.load_dict(data["world_state"])
	EraManager.set_era(int(data["era"]))
	get_tree().change_scene_to_file(data["scene"])
	await get_tree().scene_changed

	var characters: Dictionary = data["characters"]
	for motor in _find_characters(get_tree().current_scene):
		var key := Era.character_name(motor.era)
		if characters.has(key):
			motor.position = Vector2(characters[key]["x"], characters[key]["y"])
			motor.velocity = Vector2.ZERO
	_notify("Jogo carregado.")
	return true


func _find_characters(scene: Node) -> Array[PlayerMotor]:
	var result: Array[PlayerMotor] = []
	for node in scene.find_children("*", "", true, false):
		if node is PlayerMotor:
			result.append(node)
	return result


func _notify(text: String) -> void:
	get_tree().call_group("hud", "show_message", text)
