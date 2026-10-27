class_name EraLinkedObject
extends Node2D
## Objeto do presente que depende de uma flag do WorldState.
## Ao entrar no presente, aparece (e liga colisões e interações) só se a flag
## estiver no estado esperado. Ex.: armário na posição nova só se Helena o empurrou.

@export var flag_key: String = ""
## true: aparece quando a flag está ligada. false: aparece quando está desligada.
@export var visible_when_set: bool = true


func _ready() -> void:
	EraManager.era_changed.connect(_on_era_changed)
	_apply()


func _on_era_changed(era: Era.Id) -> void:
	if era == Era.Id.PRESENT:
		_apply()


func _apply() -> void:
	var is_shown := WorldState.is_set(flag_key) == visible_when_set
	visible = is_shown
	process_mode = Node.PROCESS_MODE_INHERIT if is_shown else Node.PROCESS_MODE_DISABLED
