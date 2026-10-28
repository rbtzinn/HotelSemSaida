class_name NoteUI
extends CanvasLayer
## Tela de leitura (cardápios, bilhetes, jornais), em close.
## Pausa o jogo até fechar com E, Enter ou Esc.

var _title: String
var _text: String


static func open(tree: SceneTree, title: String, text: String) -> NoteUI:
	var ui := NoteUI.new()
	ui._title = title
	ui._text = text
	tree.root.add_child(ui)
	return ui


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var paper := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#E8E2D0")
	style.set_content_margin_all(12)
	paper.add_theme_stylebox_override("panel", style)
	center.add_child(paper)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	paper.add_child(column)

	column.add_child(_make_label(_title, 12))
	var body := _make_label(_text, 10)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(280, 0)
	column.add_child(body)
	var hint := _make_label("[E] Fechar", 8)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column.add_child(hint)


func _unhandled_input(event: InputEvent) -> void:
	for action in ["interact", "ui_accept", "ui_cancel", "pause"]:
		if event.is_action_pressed(action):
			get_viewport().set_input_as_handled()
			close()
			return


func close() -> void:
	visible = false
	set_process_unhandled_input(false)
	await UIUtil.unpause_after_release(get_tree())
	queue_free()


func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("#2A1A1A"))
	return label
