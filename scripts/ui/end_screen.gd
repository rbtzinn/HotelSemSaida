class_name EndScreen
extends CanvasLayer
## Tela de fim desta versão. Aparece quando `jogo.encerrado` liga (Lia leu o próprio nome
## no livro), espera as outras telas em close fecharem, salva e volta à recepção.

const ENDED := "jogo.encerrado"
const LINES := [
	"1923. Diante da porta giratória, Helena ouve alguém bater do outro lado.\nTrês batidas, como os passos de alguém que tateia no escuro.",
	"GRAND HOTEL AURORA",
	"Hóspedes que entraram e nunca saíram:\n1923, 1951, 1979, 2003… e hoje.",
]
const LINE_DELAY := 2.2

var _shown := false
var _ready_to_leave := false
var _hint: Label


static func open(tree: SceneTree) -> void:
	for node in tree.root.get_children():
		if node is EndScreen:
			return
	tree.root.add_child(EndScreen.new())


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func _process(_delta: float) -> void:
	if not _shown:
		# Espera o bilhete (ou outra tela em close) fechar
		if not get_tree().get_nodes_in_group("room_overlay").is_empty():
			return
		_show()
	# A tela que fechou despausa ao soltar a tecla; o fim continua pausado
	get_tree().paused = true


func _show() -> void:
	_shown = true
	visible = true
	add_to_group("room_overlay")
	if NetSession.phase == NetSession.Phase.OFF:
		SaveSystem.save_game()
	else:
		NetSession.save_duo()
	get_tree().paused = true
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.03, 0)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 22)
	center.add_child(column)
	var tween := create_tween()
	tween.tween_property(dim, "color:a", 1.0, 1.2)
	for i in LINES.size():
		var line := _make_label(LINES[i], 22 if i == 1 else 13, Color("#D6B272") if i == 1 else Color("#EAE2CF"))
		line.modulate.a = 0
		column.add_child(line)
		tween.tween_property(line, "modulate:a", 1.0, 1.4)
		tween.tween_interval(LINE_DELAY - 1.4)
	_hint = _make_label("[" + Settings.binding_label("interact") + "] Voltar à recepção", 10, Color("#8A8270"))
	_hint.modulate.a = 0
	column.add_child(_hint)
	tween.tween_property(_hint, "modulate:a", 1.0, 0.8)
	tween.tween_callback(func() -> void: _ready_to_leave = true)


func _unhandled_input(event: InputEvent) -> void:
	if not _shown:
		return
	get_viewport().set_input_as_handled()
	if not _ready_to_leave:
		return
	for action in ["interact", "ui_accept"]:
		if event.is_action_pressed(action):
			_leave()
			return


func _leave() -> void:
	_ready_to_leave = false
	set_process(false)
	if NetSession.phase != NetSession.Phase.OFF:
		NetSession.leave("Fim desta versão.")
		return
	get_tree().paused = false
	queue_free()
	RoomManager.open_scene(NetSession.LOBBY)


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", preload("res://art/fonts/interface_font.tres"))
	label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
