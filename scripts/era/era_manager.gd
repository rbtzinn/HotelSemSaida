extends Node
## Autoload: guarda a época ativa e faz a troca com um fade curto, sem mover a câmera.

signal era_changed(new_era: Era.Id)

## Duração total do fade (escurecer + clarear), em segundos.
const FADE_DURATION: float = 0.25

var current_era: Era.Id = Era.Id.PAST_1923

var _is_switching: bool = false
var _fade_rect: ColorRect


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color.BLACK
	_fade_rect.modulate.a = 0.0
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade_rect)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("switch_era") and not event.is_echo():
		get_viewport().set_input_as_handled()
		switch_era()


## Troca para a outra época com fade. Ignora pedidos durante uma troca em andamento.
func switch_era() -> void:
	if _is_switching:
		return
	_is_switching = true

	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 1.0, FADE_DURATION / 2.0)
	tween.tween_callback(func() -> void: set_era(Era.other(current_era)))
	tween.tween_property(_fade_rect, "modulate:a", 0.0, FADE_DURATION / 2.0)
	tween.finished.connect(func() -> void: _is_switching = false)


func is_switching() -> bool:
	return _is_switching


## Define a época na hora, sem fade (útil para carregar jogo salvo).
func set_era(era: Era.Id) -> void:
	current_era = era
	era_changed.emit(era)
