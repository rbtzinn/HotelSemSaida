class_name CabinetPush
extends Interactable
## Enigma de teste: em 1923, Helena desliza o armário para o lado com E.
## Move o nó pai (o armário inteiro) e liga a flag no WorldState. Só vai uma vez.

@export var flag_key: String = "teste.armario.empurrado"
@export var slide_distance: float = 48.0
@export var slide_duration: float = 0.4


func _ready() -> void:
	super()
	# Jogo carregado com o armário já empurrado
	if WorldState.is_set(flag_key):
		get_parent().position.x += slide_distance
		enabled = false


func _on_interact(_by: PlayerMotor) -> void:
	enabled = false
	WorldState.set_flag(flag_key)
	var cabinet: Node2D = get_parent()
	var tween := create_tween()
	tween.tween_property(cabinet, "position:x", cabinet.position.x + slide_distance, slide_duration)
