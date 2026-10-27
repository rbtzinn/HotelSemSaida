class_name ActionCharacterInput
extends CharacterInput
## Lê os comandos das ações do Input Map.
## No co-op, cada jogador terá ações com prefixo próprio (ex.: "p2_move_left").

var action_prefix: String


func _init(prefix: String = "") -> void:
	action_prefix = prefix


func get_move() -> Vector2:
	return Input.get_vector(
		action_prefix + "move_left", action_prefix + "move_right",
		action_prefix + "move_up", action_prefix + "move_down")


func is_jump_just_pressed() -> bool:
	return Input.is_action_just_pressed(action_prefix + "jump")


func is_interact_just_pressed() -> bool:
	return Input.is_action_just_pressed(action_prefix + "interact")
