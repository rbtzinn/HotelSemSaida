class_name EraLinked3D
extends Node3D
## Objeto 3D que depende de uma flag do WorldState: aparece (e liga colisões e interações)
## só se a flag estiver no estado esperado. No presente confere ao entrar na época;
## com update_immediately reage na hora (ex.: a porta de 1923 que se abre).

@export var flag_key: String = ""
## true: aparece quando a flag está ligada. false: aparece quando está desligada.
@export var visible_when_set: bool = true
@export var update_immediately: bool = false


func _ready() -> void:
	EraManager.era_changed.connect(func(era: Era.Id) -> void:
		if era == Era.Id.PRESENT:
			_apply())
	if update_immediately or NetSession.phase == NetSession.Phase.PLAYING:
		WorldState.flag_changed.connect(func(key: String, _value: Variant) -> void:
			if key == flag_key or _also_refreshes(key):
				_apply())
	_apply()

func _also_refreshes(_key: String) -> bool:
	return false


func _apply() -> void:
	var is_shown := WorldState.is_set(flag_key) == visible_when_set
	visible = is_shown
	process_mode = Node.PROCESS_MODE_INHERIT if is_shown else Node.PROCESS_MODE_DISABLED
