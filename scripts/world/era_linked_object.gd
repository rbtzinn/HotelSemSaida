class_name EraLinkedObject
extends Node2D
## Objeto que depende de uma flag do WorldState: aparece (e liga colisões e interações)
## só se a flag estiver no estado esperado.
## No presente, confere a flag ao entrar na época (ex.: armário na posição nova só se
## Helena o empurrou). Em 1923, use update_immediately para reagir na hora
## (ex.: o cadeado some assim que Helena o abre).

@export var flag_key: String = ""
## true: aparece quando a flag está ligada. false: aparece quando está desligada.
@export var visible_when_set: bool = true
## true: reage assim que a flag muda, em vez de só ao entrar no presente.
@export var update_immediately: bool = false


func _ready() -> void:
	EraManager.era_changed.connect(_on_era_changed)
	if update_immediately:
		WorldState.flag_changed.connect(_on_flag_changed)
	_apply()


func _on_era_changed(era: Era.Id) -> void:
	if era == Era.Id.PRESENT:
		_apply()


func _on_flag_changed(key: String, _value: Variant) -> void:
	if key == flag_key:
		_apply()


func _apply() -> void:
	var is_shown := WorldState.is_set(flag_key) == visible_when_set
	visible = is_shown
	process_mode = Node.PROCESS_MODE_INHERIT if is_shown else Node.PROCESS_MODE_DISABLED
