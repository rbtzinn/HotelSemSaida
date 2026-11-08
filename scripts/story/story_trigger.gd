class_name StoryTrigger
extends Node
## Toca uma cutscene da história quando uma flag liga nesta sala. Com `on_ready`, toca também
## ao abrir a sala se a flag já estiver ligada (ex.: Lia chegando à manutenção depois da Cozinha).
## Fica como filho da sala: some com ela, e a ligação ao WorldState se desfaz sozinha.

var flag: String
var play: Callable
var on_ready := false


static func attach(room: Node, flag_key: String, cutscene: Callable, play_on_ready: bool = false) -> StoryTrigger:
	var trigger := StoryTrigger.new()
	trigger.name = "Cena_" + flag_key.replace(".", "_")
	trigger.flag = flag_key
	trigger.play = cutscene
	trigger.on_ready = play_on_ready
	room.add_child(trigger)
	return trigger


func _ready() -> void:
	WorldState.flag_changed.connect(_on_flag)
	if on_ready and WorldState.is_set(flag):
		_fire.call_deferred()


func _on_flag(key: String, value: Variant) -> void:
	if key == flag and value:
		_fire()


func _fire() -> void:
	if is_inside_tree():
		play.call(get_tree())
