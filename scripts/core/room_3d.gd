class_name Room3D
extends Node3D
## Raiz de cada sala em primeira pessoa. Prende o mouse enquanto se joga, solta no menu
## de pausa e nas telas em close, e entrega o movimento do mouse ao input do jogador.
## A sala em si pausa junto com o jogo (as personagens herdam isso e ficam paradas
## enquanto um bilhete ou o cadeado está aberto); o mouse é conferido pelo sinal
## process_frame da árvore, que continua chegando com o jogo pausado.


func _ready() -> void:
	get_tree().call_group("hud", "set_first_person", true)
	get_tree().process_frame.connect(_update_mouse_mode)
	# O fim pode chegar em qualquer sala (na dupla online, Helena pode estar longe do Saguão)
	WorldState.flag_changed.connect(_on_world_flag)


func _on_world_flag(key: String, value: Variant) -> void:
	if key == EndScreen.ENDED and value:
		EndScreen.open(get_tree())


func _update_mouse_mode() -> void:
	var wanted := Input.MOUSE_MODE_VISIBLE if get_tree().paused else Input.MOUSE_MODE_CAPTURED
	if Input.mouse_mode != wanted:
		Input.mouse_mode = wanted
	if get_tree().paused:
		# O que o mouse andou com a tela aberta não vira giro de cabeça ao fechar
		ActionCharacterInput.pending_mouse = Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		ActionCharacterInput.pending_mouse += event.relative


func _exit_tree() -> void:
	get_tree().process_frame.disconnect(_update_mouse_mode)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
