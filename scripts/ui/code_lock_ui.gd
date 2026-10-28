class_name CodeLockUI
extends CanvasLayer
## Minigame do cadeado de código, em close. Pausa o jogo enquanto está aberto.
## A/D (ou setas) escolhem o disco, W/S giram, E/Enter testam, Esc sai.

signal solved

const ACTIVE_BORDER: Color = Color("#F2D49B")
const IDLE_BORDER: Color = Color("#3A4A58")

var _code: String
var _digits: Array[int] = []
var _index: int = 0
var _labels: Array[Label] = []
var _styles: Array[StyleBoxFlat] = []
var _status: Label


static func open(tree: SceneTree, code: String) -> CodeLockUI:
	var ui := CodeLockUI.new()
	ui._code = code
	tree.root.add_child(ui)
	return ui


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	for i in _code.length():
		_digits.append(0)

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

	column.add_child(_make_label("Cadeado", 12))

	var dials := HBoxContainer.new()
	dials.alignment = BoxContainer.ALIGNMENT_CENTER
	dials.add_theme_constant_override("separation", 4)
	column.add_child(dials)
	for i in _digits.size():
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#1C2630")
		style.set_border_width_all(2)
		style.set_content_margin_all(6)
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", style)
		var label := _make_label("0", 16)
		panel.add_child(label)
		dials.add_child(panel)
		_styles.append(style)
		_labels.append(label)

	_status = _make_label(" ", 10)
	column.add_child(_status)
	column.add_child(_make_label("A/D escolher · W/S girar · E testar · Esc sair", 8))
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	var handled := true
	if _pressed(event, ["move_left", "ui_left"]):
		_index = (_index + _digits.size() - 1) % _digits.size()
	elif _pressed(event, ["move_right", "ui_right"]):
		_index = (_index + 1) % _digits.size()
	elif _pressed(event, ["move_up", "ui_up"]):
		_digits[_index] = (_digits[_index] + 1) % 10
		_status.text = " "
	elif _pressed(event, ["move_down", "ui_down"]):
		_digits[_index] = (_digits[_index] + 9) % 10
		_status.text = " "
	elif _pressed(event, ["interact", "ui_accept"]):
		_try_code()
	elif _pressed(event, ["ui_cancel", "pause"]):
		close()
	else:
		handled = false
	if handled:
		get_viewport().set_input_as_handled()
		_refresh()


func close() -> void:
	visible = false
	set_process_unhandled_input(false)
	await UIUtil.unpause_after_release(get_tree())
	queue_free()


func _try_code() -> void:
	var attempt := "".join(_digits.map(func(d: int) -> String: return str(d)))
	if attempt == _code:
		solved.emit()
		close()
	else:
		_status.text = "Não abre."


func _refresh() -> void:
	for i in _digits.size():
		_labels[i].text = str(_digits[i])
		_styles[i].border_color = ACTIVE_BORDER if i == _index else IDLE_BORDER


func _pressed(event: InputEvent, actions: Array) -> bool:
	for action in actions:
		if event.is_action_pressed(action):
			return true
	return false


func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("#E8E2D0"))
	return label
