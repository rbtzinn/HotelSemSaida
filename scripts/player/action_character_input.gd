class_name ActionCharacterInput
extends CharacterInput
## Lê os comandos das ações do Input Map.
## No co-op, cada jogador terá ações com prefixo próprio (ex.: "p2_move_left").

## Pixels de mouse por segundo que o analógico direito vale, inclinado até o fim.
const STICK_LOOK_SPEED: float = 900.0

## Movimento do mouse acumulado desde a última leitura (só o jogador sem prefixo usa o mouse).
static var pending_mouse: Vector2 = Vector2.ZERO

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


func get_look() -> Vector2:
	var stick := Input.get_vector(
		action_prefix + "look_left", action_prefix + "look_right",
		action_prefix + "look_up", action_prefix + "look_down")
	var look := stick * STICK_LOOK_SPEED / Engine.physics_ticks_per_second
	if action_prefix == "":
		look += pending_mouse
		pending_mouse = Vector2.ZERO
	return look
