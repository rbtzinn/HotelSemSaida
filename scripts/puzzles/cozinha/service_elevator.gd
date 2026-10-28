class_name ServiceElevator
extends Node2D
## Elevador de serviço de 1923. A alavanca sobe e desce a cabine; o freio a prende.
## Cabine no alto com o freio puxado = travada, e liga "cozinha.elevador.travado".
## Sem o freio, a cabine não fica lá em cima por 100 anos.

const UP_FLAG: String = "cozinha.elevador.no_alto"
const BRAKE_FLAG: String = "cozinha.elevador.freio"
const JAMMED_FLAG: String = "cozinha.elevador.travado"

## Distância que a cabine sobe, em pixels.
@export var travel: float = 128.0
@export var travel_time: float = 1.2

var _moving: bool = false
var _cabin_down_y: float
var _lever_down_y: float

@onready var _cabin: Node2D = $Cabine
@onready var _lever_handle: ColorRect = $PainelAlavanca/Alca
@onready var _brake_handle: ColorRect = $PainelFreio/Alca


func _ready() -> void:
	_cabin_down_y = _cabin.position.y
	_lever_down_y = _lever_handle.position.y
	$Alavanca.interacted.connect(_on_lever)
	$Freio.interacted.connect(_on_brake)
	# Estado salvo: aplica sem animação
	if WorldState.is_set(UP_FLAG):
		_cabin.position.y = _cabin_down_y - travel
	_refresh_controls()


func _on_lever(_by: PlayerMotor) -> void:
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
	var target_y := _cabin_down_y - travel if going_up else _cabin_down_y
	var tween := create_tween()
	tween.tween_property(_cabin, "position:y", target_y, travel_time)
	tween.finished.connect(func() -> void: _moving = false)


func _on_brake(_by: PlayerMotor) -> void:
	if _moving:
		return
	var braked := not WorldState.is_set(BRAKE_FLAG)
	WorldState.set_flag(BRAKE_FLAG, braked)
	_update_jammed()
	_refresh_controls()
	_say("Freio puxado." if braked else "Freio solto.")


func _update_jammed() -> void:
	WorldState.set_flag(JAMMED_FLAG, WorldState.is_set(UP_FLAG) and WorldState.is_set(BRAKE_FLAG))


## Alça da alavanca em cima quando a cabine está no alto; freio fica claro quando puxado.
func _refresh_controls() -> void:
	_lever_handle.position.y = _lever_down_y - 14.0 if WorldState.is_set(UP_FLAG) else _lever_down_y
	_brake_handle.color = Color("#F2D49B") if WorldState.is_set(BRAKE_FLAG) else Color("#6B1E2A")


func _say(text: String) -> void:
	get_tree().call_group("hud", "show_message", text)
