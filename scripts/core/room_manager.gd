extends Node
## Autoload: troca de sala. Escurece a tela, abre a nova cena e posiciona as personagens.
## Helena e Lia sempre mudam de sala juntas (mesmo espaço, mesma câmera).

const FADE_DURATION: float = 0.2

var _is_changing: bool = false
var _fade_rect: ColorRect


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


## Vai para outra sala e coloca as duas personagens no ponto de entrada (um Marker2D da sala).
func change_room(scene_path: String, spawn_name: String) -> void:
	await go_to(scene_path, func(room: Node) -> void: _place_at_spawn(room, spawn_name))


## Abre a sala e chama `place_characters(sala)` antes de clarear a tela.
func go_to(scene_path: String, place_characters: Callable) -> void:
	if _is_changing:
		return
	_is_changing = true
	await _fade(1.0)
	get_tree().change_scene_to_file(scene_path)
	await get_tree().scene_changed
	place_characters.call(get_tree().current_scene)
	await _fade(0.0)
	_is_changing = false


static func find_characters(room: Node) -> Array[PlayerMotor]:
	var result: Array[PlayerMotor] = []
	for node in room.find_children("*", "", true, false):
		if node is PlayerMotor:
			result.append(node)
	return result


func _place_at_spawn(room: Node, spawn_name: String) -> void:
	var spawn := room.find_child(spawn_name, true, false) as Node2D
	if spawn == null:
		push_error("RoomManager: ponto de entrada '%s' não existe em %s" % [spawn_name, room.scene_file_path])
		return
	for motor in find_characters(room):
		motor.global_position = spawn.global_position
		motor.velocity = Vector2.ZERO


func _fade(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", alpha, FADE_DURATION)
	await tween.finished
