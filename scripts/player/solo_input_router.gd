class_name SoloInputRouter
extends Node
## Modo solo: entrega o input do jogador só à personagem da época ativa.
## A outra recebe o input vazio e fica parada onde foi deixada.

@export var helena: PlayerMotor
@export var lia: PlayerMotor

var _player_input: CharacterInput = ActionCharacterInput.new()
var _no_input: CharacterInput = CharacterInput.new()


func _ready() -> void:
	EraManager.era_changed.connect(_route)
	_route(EraManager.current_era)


func _route(era: Era.Id) -> void:
	var is_past := era == Era.Id.PAST_1923
	helena.input = _player_input if is_past else _no_input
	lia.input = _no_input if is_past else _player_input
