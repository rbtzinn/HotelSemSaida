class_name PianoUI
extends CanvasLayer
## Minigame do piano, em close (vista de cima do teclado): uma oitava de oito teclas brancas,
## de dó a dó, com a primeira marcada por uma plaquinha de latão. Toca-se com o mouse ou com as
## teclas 1 a 8. Quando as últimas notas tocadas formam `melody`, emite `solved`. Errar não faz
## nada; dá para tentar quantas vezes quiser. Esc ou E saem. Pausa o jogo enquanto está aberto.
## Sem áudio ainda: a tecla tocada só abaixa.

signal solved

const KEYS := 8
const KEY_SIZE := Vector2(34, 132)
const BLACK_SIZE := Vector2(20, 80)
## Teclas pretas depois destas brancas (dó#, ré#, fá#, sol#, lá#).
const BLACK_AFTER := [0, 1, 3, 4, 5]
const IVORY := Color("#EDE4CF")
const PRESSED := Color("#BFB39A")
const BRASS := Color("#C9973B")

var _melody: Array = []
var _played: Array[int] = []
var _keys: Array[ColorRect] = []
var _done := false


static func open(tree: SceneTree, melody: Array) -> PianoUI:
	var ui := PianoUI.new()
	ui._melody = melody
	tree.root.add_child(ui)
	return ui


func _ready() -> void:
	add_to_group("room_overlay")
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	center.add_child(column)
	column.add_child(_make_label("Piano de cauda", 14))

	# Caixa de laca preta em volta do teclado
	var case := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0E0A0B")
	style.border_color = Color("#3A2A14")
	style.set_border_width_all(2)
	style.set_content_margin_all(10)
	case.add_theme_stylebox_override("panel", style)
	column.add_child(case)

	var keyboard := Control.new()
	keyboard.custom_minimum_size = Vector2(KEYS * (KEY_SIZE.x + 2), KEY_SIZE.y)
	case.add_child(keyboard)
	for i in KEYS:
		var key := ColorRect.new()
		key.color = IVORY
		key.position = Vector2(i * (KEY_SIZE.x + 2), 0)
		key.size = KEY_SIZE
		key.mouse_filter = Control.MOUSE_FILTER_STOP
		key.gui_input.connect(_on_key_input.bind(i + 1))
		keyboard.add_child(key)
		_keys.append(key)
		if i == 0:
			# A plaquinha de latão na frente da primeira tecla
			var plate := ColorRect.new()
			plate.color = BRASS
			plate.position = Vector2(6, KEY_SIZE.y - 14)
			plate.size = Vector2(KEY_SIZE.x - 12, 6)
			plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
			key.add_child(plate)
	for i: int in BLACK_AFTER:
		var black := ColorRect.new()
		black.color = Color("#151012")
		black.position = Vector2((i + 1) * (KEY_SIZE.x + 2) - BLACK_SIZE.x / 2.0 - 1, 0)
		black.size = BLACK_SIZE
		# Teclas pretas não fazem parte da valsa: só bloqueiam o clique por cima das brancas
		black.mouse_filter = Control.MOUSE_FILTER_STOP
		keyboard.add_child(black)

	column.add_child(_make_label("Mouse ou 1 a 8 tocam · %s ou Esc sair" % Settings.binding_label("interact"), 10))


func _on_key_input(event: InputEvent, number: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		play(number)


func _unhandled_input(event: InputEvent) -> void:
	if _done:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var number := _number_for(event.physical_keycode)
		if number > 0:
			get_viewport().set_input_as_handled()
			play(number)
			return
	for action in ["interact", "ui_accept", "ui_cancel", "pause"]:
		if event.is_action_pressed(action):
			get_viewport().set_input_as_handled()
			close()
			return


static func _number_for(code: Key) -> int:
	if code >= KEY_1 and code <= KEY_8:
		return code - KEY_1 + 1
	if code >= KEY_KP_1 and code <= KEY_KP_8:
		return code - KEY_KP_1 + 1
	return 0


## Toca a tecla `number` (1 = dó de latão). Usado também pelos testes.
func play(number: int) -> void:
	if _done or number < 1 or number > KEYS:
		return
	var key := _keys[number - 1]
	key.color = PRESSED
	Audio.play("piano_%d" % number, -2.0, 0.0)
	var release := create_tween()
	release.tween_interval(0.15)
	release.tween_property(key, "color", IVORY, 0.1)
	_played.append(number)
	if _played.size() > _melody.size():
		_played.remove_at(0)
	if _matches():
		_done = true
		solved.emit()
		var wait := create_tween()
		wait.tween_interval(0.6)
		wait.tween_callback(close)


func _matches() -> bool:
	if _played.size() != _melody.size():
		return false
	for i in _melody.size():
		if _played[i] != int(_melody[i]):
			return false
	return true


func close() -> void:
	_done = true
	visible = false
	set_process_unhandled_input(false)
	await UIUtil.unpause_after_release(get_tree())
	queue_free()


func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", preload("res://art/fonts/interface_font.tres"))
	label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("#E8E2D0"))
	return label
