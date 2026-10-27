class_name EraVisibility
extends Node
## Colocado como filho de uma raiz de cenário (World1923, WorldToday).
## Mostra o pai e liga as colisões dele só quando a época ativa é a desta raiz.
## Esconder o pai também apaga as luzes 2D dentro dele.

@export var era: Era.Id = Era.Id.PAST_1923


func _ready() -> void:
	# Continua recebendo o sinal mesmo com o pai desligado
	process_mode = Node.PROCESS_MODE_ALWAYS
	EraManager.era_changed.connect(_apply)
	_apply(EraManager.current_era)


func _apply(active_era: Era.Id) -> void:
	var target := get_parent()
	var is_active := active_era == era
	if target is CanvasItem:
		target.visible = is_active
	# Desligar o processamento tira os corpos físicos da simulação
	target.process_mode = Node.PROCESS_MODE_INHERIT if is_active else Node.PROCESS_MODE_DISABLED
