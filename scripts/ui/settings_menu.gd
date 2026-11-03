extends CanvasLayer
## Configurações utilizáveis por mouse, teclado e controle.
signal closed
var draft: Dictionary
var previous: Dictionary
var tabs: TabContainer
var status: Label
var apply_button: Button
var cancel_button: Button
var binding_buttons: Dictionary = {}
var waiting: String = ""
var confirm_left: float = 0.0
var pending_video: bool = false
var _panel: PanelContainer

func _ready() -> void:
	layer = 70
	process_mode = Node.PROCESS_MODE_ALWAYS
	previous = Settings.data.duplicate(true)
	draft = previous.duplicate(true)
	var dim := ColorRect.new()
	dim.color = Color(0.015,0.02,0.03,0.96)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var future_wall := TextureRect.new()
	future_wall.position = Vector2(320,0)
	future_wall.size = Vector2(320,360)
	future_wall.texture = load("res://art/future/wall.png")
	future_wall.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	future_wall.modulate = Color(0.6,0.8,0.9,0.5)
	future_wall.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(future_wall)
	# A costura diagonal divide as épocas sem reduzir o contraste dos controles.
	var past := Polygon2D.new()
	past.polygon = PackedVector2Array([Vector2.ZERO,Vector2(360,0),Vector2(280,360),Vector2(0,360)])
	past.color = Color("#341920")
	add_child(past)
	var seam := Line2D.new()
	seam.points = PackedVector2Array([Vector2(360,0),Vector2(280,360)])
	seam.default_color = Color("#C9973B")
	seam.width = 2
	add_child(seam)
	_panel = PanelContainer.new()
	_panel.position = Vector2(20,12)
	_panel.size = Vector2(600,336)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025,0.035,0.05,0.55)
	style.border_color = Color("#697d86")
	style.set_border_width_all(1)
	style.set_content_margin_all(12)
	_panel.add_theme_stylebox_override("panel",style)
	var theme := Theme.new()
	theme.default_font_size = 11
	theme.set_color("font_color","Label",Color("#F2E7D1"))
	theme.set_color("font_color","Button",Color("#F2E7D1"))
	theme.set_color("font_focus_color","Button",Color("#F2D49B"))
	_panel.theme = theme
	add_child(_panel)
	var column := VBoxContainer.new()
	_panel.add_child(column)
	var heading := HBoxContainer.new()
	column.add_child(heading)
	var title := Label.new()
	title.text = "CONFIGURAÇÕES"
	title.add_theme_font_size_override("font_size",16)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	var eras := Label.new()
	eras.text = "1923  /  HOJE"
	eras.add_theme_color_override("font_color",Color("#C9973B"))
	heading.add_child(eras)
	var caption := Label.new()
	caption.text = "GRAND HOTEL AURORA                                      ARQUIVO DO PRESENTE"
	caption.add_theme_font_size_override("font_size",9)
	caption.add_theme_color_override("font_color",Color("#9CAFB5"))
	column.add_child(caption)
	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(tabs)
	_video()
	_audio()
	_controls()
	status = Label.new()
	status.text = "Preferências salvas neste computador."
	status.add_theme_font_size_override("font_size",10)
	column.add_child(status)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation",10)
	column.add_child(footer)
	_button(footer,"Restaurar padrões",_reset)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)
	cancel_button = _button(footer,"Voltar",_cancel)
	apply_button = _button(footer,"Aplicar",_apply)
	cancel_button.grab_focus()

func _page(title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",8)
	scroll.add_child(column)
	return column

func _row(parent: Control,title: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 24
	parent.add_child(row)
	var label := Label.new()
	label.text = title
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	return row

func _choice(parent: Control,title: String,key: String,labels: Array,values: Array) -> void:
	var row := _row(parent,title)
	var option := OptionButton.new()
	option.custom_minimum_size.x = 230
	for i in labels.size():
		option.add_item(str(labels[i]))
		if draft[key] == values[i]:
			option.select(i)
	option.item_selected.connect(func(index: int) -> void: draft[key] = values[index])
	row.add_child(option)

func _toggle(parent: Control,title: String,key: String) -> void:
	var check := CheckButton.new()
	check.button_pressed = draft[key]
	check.toggled.connect(func(value: bool) -> void: draft[key] = value)
	_row(parent,title).add_child(check)

func _video() -> void:
	var page := _page("Vídeo")
	_choice(page,"Modo de exibição","mode",["Janela","Tela cheia sem bordas","Tela cheia exclusiva"],[0,1,2])
	_choice(page,"Tamanho da janela","resolution",["1280 × 720","1600 × 900","1920 × 1080","2560 × 1440"],[Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080),Vector2i(2560,1440)])
	_toggle(page,"Sincronização vertical (VSync)","vsync")
	_choice(page,"Limite de quadros por segundo","fps",["30","60","120","144","Sem limite"],[30,60,120,144,0])
	var hint := Label.new()
	hint.text = "Vídeo: confirme em 15 segundos ou a alteração será revertida."
	hint.add_theme_font_size_override("font_size",10)
	page.add_child(hint)

func _audio() -> void:
	var page := _page("Áudio")
	var row := _row(page,"Volume geral")
	var slider := HSlider.new()
	slider.custom_minimum_size.x = 210
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = draft.volume * 100
	var value := Label.new()
	value.text = "%d%%" % slider.value
	value.custom_minimum_size.x = 45
	slider.value_changed.connect(func(v: float) -> void:
		draft.volume = v/100.0
		value.text = "%d%%" % v)
	row.add_child(slider)
	row.add_child(value)
	_toggle(page,"Silenciar todo o áudio","mute")

func _controls() -> void:
	var page := _page("Controles")
	var hint := Label.new()
	hint.text = "Escolha uma ação e pressione uma tecla ou botão do mouse.\nEsc cancela a captura. O controle continua disponível."
	hint.add_theme_font_size_override("font_size",10)
	page.add_child(hint)
	for i in Settings.ACTIONS.size():
		var action: String = Settings.ACTIONS[i]
		var button := _button(_row(page,Settings.LABELS[i]),Settings.binding_label(action,draft),func() -> void:
			waiting = action
			status.text = "Pressione uma tecla ou botão do mouse. Esc cancela.")
		button.custom_minimum_size.x = 180
		binding_buttons[action] = button
	var row := _row(page,"Zona morta do analógico")
	var slider := HSlider.new()
	slider.custom_minimum_size.x = 180
	slider.min_value = 0.05
	slider.max_value = 0.5
	slider.step = 0.05
	slider.value = draft.deadzone
	var value := Label.new()
	value.text = "%.2f" % draft.deadzone
	slider.value_changed.connect(func(v: float) -> void:
		draft.deadzone = v
		value.text = "%.2f" % v)
	row.add_child(slider)
	row.add_child(value)

func _button(parent: Control,text: String,callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 24
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _input(event: InputEvent) -> void:
	if waiting.is_empty():
		return
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		waiting = ""
		status.text = "Captura cancelada."
		get_viewport().set_input_as_handled()
		return
	var binding := {}
	if event is InputEventKey and event.pressed and not event.echo:
		binding = {"kind":"key","code":event.physical_keycode}
	elif event is InputEventMouseButton and event.pressed:
		binding = {"kind":"mouse","code":event.button_index}
	if binding.is_empty():
		return
	get_viewport().set_input_as_handled()
	for action in Settings.ACTIONS:
		if action != waiting and draft.bindings[action] == binding:
			status.text = "Já usado em: " + Settings.LABELS[Settings.ACTIONS.find(action)]
			return
	draft.bindings[waiting] = binding
	binding_buttons[waiting].text = Settings.binding_label(waiting,draft)
	waiting = ""
	status.text = "Controle alterado. Use Aplicar para salvar."

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_cancel()

func _apply() -> void:
	if pending_video:
		pending_video = false
		confirm_left = 0
		_persist()
		return
	waiting = ""
	var video_changed: bool = draft.mode != previous.mode or draft.resolution != previous.resolution
	Settings.apply(draft)
	if video_changed and DisplayServer.get_name() != "headless":
		pending_video = true
		confirm_left = 15
		apply_button.text = "Manter alterações"
	else:
		_persist()

func _persist() -> void:
	if Settings.save() != OK:
		Settings.apply(previous)
		status.text = "Não foi possível salvar as preferências."
		return
	previous = Settings.data.duplicate(true)
	apply_button.text = "Aplicar"
	status.text = "Configurações aplicadas e salvas."

func _process(delta: float) -> void:
	if pending_video:
		confirm_left -= delta
		status.text = "Manter este vídeo? Reverte em %d s." % ceili(confirm_left)
		if confirm_left <= 0:
			Settings.apply(previous)
			draft = previous.duplicate(true)
			pending_video = false
			confirm_left = 0
			_rebuild()

func _cancel() -> void:
	Settings.apply(previous)
	closed.emit()
	queue_free()

func _reset() -> void:
	if pending_video:
		Settings.apply(previous)
	pending_video = false
	draft = Settings.factory()
	_rebuild()

func _rebuild() -> void:
	# Recria os campos para representar corretamente valores revertidos/padrões.
	var selected := tabs.current_tab
	for child in tabs.get_children():
		tabs.remove_child(child)
		child.queue_free()
	binding_buttons.clear()
	_video()
	_audio()
	_controls()
	tabs.current_tab = selected
	apply_button.text = "Aplicar"
	status.text = "Use Aplicar para confirmar."

