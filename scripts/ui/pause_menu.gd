extends CanvasLayer
## Menu de pausa (Esc / Start): pausa o jogo e oferece continuar, salvar, carregar e sair.
## Navegação por mouse, setas, direcional do controle; Enter/Espaço/A confirma.

var _first_button: Button


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	center.add_child(column)

	var title := Label.new()
	title.text = "Pausa"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color("#E8E2D0"))
	column.add_child(title)

	_first_button = _add_button(column, "Continuar", close)
	_add_button(column, "Salvar", _save)
	_add_button(column, "Carregar", _load)
	_add_button(column, "Sair do jogo", func() -> void: get_tree().quit())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or (visible and event.is_action_pressed("ui_cancel")):
		get_viewport().set_input_as_handled()
		if visible:
			close()
		else:
			open()


func open() -> void:
	# Não pausa no meio de uma troca de sala nem por cima de outra tela (leitura, cadeado)
	if RoomManager.is_changing() or get_tree().paused:
		return
	get_tree().paused = true
	visible = true
	_first_button.grab_focus()


func close() -> void:
	visible = false
	await UIUtil.unpause_after_release(get_tree())


func _save() -> void:
	await close()
	SaveSystem.save_game()


func _load() -> void:
	await close()
	SaveSystem.load_game()


func _add_button(parent: Control, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(120, 0)
	button.add_theme_font_size_override("font_size", 10)
	button.pressed.connect(action)
	parent.add_child(button)
	return button
