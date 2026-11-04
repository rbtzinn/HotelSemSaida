class_name ServiceElevator3D
extends Node3D
## Elevador de serviço de 1923, em 3D. A alavanca sobe e desce a cabine; o freio a prende.
## Cabine no alto com o freio puxado = travada, e liga "cozinha.elevador.travado".
## Sem o freio, a cabine não fica lá em cima por 100 anos. Mesmas flags do ServiceElevator 2D.
## Filhos: Cabine (Node3D), Alavanca e Freio (Interactable3D), AlavancaPega e FreioPega
## (punhos que giram para mostrar o estado).

const UP_FLAG: String = "cozinha.elevador.no_alto"
const BRAKE_FLAG: String = "cozinha.elevador.freio"
const JAMMED_FLAG: String = "cozinha.elevador.travado"

## Distância que a cabine sobe, em metros.
@export var travel: float = 4.53
@export var travel_time: float = 2.0
## Inclinação dos punhos, em graus, para cada lado.
@export var handle_angle: float = 35.0

var _moving: bool = false
var _cabin_down_y: float

@onready var _cabin: Node3D = $Cabine
@onready var _lever_handle: Node3D = $AlavancaPega
@onready var _brake_handle: Node3D = $FreioPega


func _ready() -> void:
	_cabin_down_y = _cabin.position.y
	($Alavanca as Interactable3D).interacted.connect(_on_lever)
	($Freio as Interactable3D).interacted.connect(_on_brake)
	# Estado salvo: aplica sem animação
	if WorldState.is_set(UP_FLAG):
		_cabin.position.y = _cabin_down_y + travel
	_refresh_controls()


func is_moving() -> bool:
	return _moving


func _on_lever(_by: FirstPersonMotor) -> void:
	if _moving:
		return
	if WorldState.is_set(BRAKE_FLAG):
		_say("O freio está puxado. A cabine não se move.")
		return
	var going_up := not WorldState.is_set(UP_FLAG)
	WorldState.set_flag(UP_FLAG, going_up)
	_update_jammed()
	_refresh_controls()
	_say("A cabine sobe." if going_up else "A cabine desce.")

	_moving = true
	var target_y := _cabin_down_y + travel if going_up else _cabin_down_y
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_cabin, "position:y", target_y, travel_time)
	tween.finished.connect(func() -> void: _moving = false)


func _on_brake(_by: FirstPersonMotor) -> void:
	if _moving:
		return
	var braked := not WorldState.is_set(BRAKE_FLAG)
	WorldState.set_flag(BRAKE_FLAG, braked)
	_update_jammed()
	_refresh_controls()
	_say("Freio puxado." if braked else "Freio solto.")


func _update_jammed() -> void:
	WorldState.set_flag(JAMMED_FLAG, WorldState.is_set(UP_FLAG) and WorldState.is_set(BRAKE_FLAG))


## Alavanca para baixo quando a cabine está no alto; freio para baixo quando puxado.
func _refresh_controls() -> void:
	_lever_handle.rotation_degrees.x = handle_angle if WorldState.is_set(UP_FLAG) else -handle_angle
	_brake_handle.rotation_degrees.x = handle_angle if WorldState.is_set(BRAKE_FLAG) else -handle_angle


func _say(text: String) -> void:
	get_tree().call_group("hud", "show_message", text)
