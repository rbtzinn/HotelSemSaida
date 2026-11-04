class_name NoteUI
extends CanvasLayer
## Tela de leitura (cardápios, bilhetes, jornais), em close.
## Pausa o jogo até fechar com E, Enter ou Esc.

var _title: String
var _text: String
var _photo: Texture2D


static func open(tree: SceneTree, title: String, text: String, photo: Texture2D = null) -> NoteUI:
	var ui := NoteUI.new()
	ui._title = title
	ui._text = text
	ui._photo = photo
	tree.root.add_child(ui)
	return ui


func _ready() -> void:
	add_to_group("room_overlay")
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

	column.add_child(_make_label(_title, 14))
	if _photo:
		var print_view := TextureRect.new()
		print_view.texture = _photo
		print_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		print_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		print_view.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		print_view.custom_minimum_size.y = 94
		column.add_child(print_view)
	var body := _make_label(_text, 12)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(460 if _photo else 360, 0)
	column.add_child(body)
	var hint := _make_label("[" + Settings.binding_label("interact") + "] Fechar", 10)
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
	label.add_theme_font_override("font", preload("res://art/fonts/interface_font.tres"))
	label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("#2A1A1A"))
	return label
