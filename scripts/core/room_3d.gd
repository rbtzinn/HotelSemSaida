class_name Room3D
extends Node3D
## Raiz de cada sala em primeira pessoa. Prende o mouse enquanto se joga, solta no menu
## de pausa e nas telas em close, e entrega o movimento do mouse ao input do jogador.


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().call_group("hud", "set_first_person", true)


func _process(_delta: float) -> void:
	var wanted := Input.MOUSE_MODE_VISIBLE if get_tree().paused else Input.MOUSE_MODE_CAPTURED
	if Input.mouse_mode != wanted:
		Input.mouse_mode = wanted


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		ActionCharacterInput.pending_mouse += event.relative


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
