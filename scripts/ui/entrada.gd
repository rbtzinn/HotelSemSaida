extends Control
## Recepção anterior à campanha. A sala particular só começa por ação do anfitrião.
const INK := Color("#EAE2CF")
const GOLD := Color("#D6B272")
const FONT := preload("res://art/fonts/interface_font.tres")
const SIGN := preload("res://art/fonts/sign_font.tres")
var _form := VBoxContainer.new()
var _options := VBoxContainer.new()
var _waiting := VBoxContainer.new()
var _role := OptionButton.new()
var _address := LineEdit.new()
var _status := Label.new()
var _start: Button
var _resume: Button
var _cancel: Button
var _solo: Button

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	theme = Theme.new()
	theme.default_font = FONT
	theme.default_font_size = 12
	var panel := CenterContainer.new()
	panel.anchor_left = 0.40
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	add_child(panel)
	_form.custom_minimum_size.x = 294
	_form.add_theme_constant_override("separation",6)
	panel.add_child(_form)
	var title := _label(_form,"Livro de entrada",22)
	title.add_theme_color_override("font_color",INK)
	_form.add_child(_options)
	_options.add_theme_constant_override("separation",5)
	var solo_row := HBoxContainer.new()
	_options.add_child(solo_row)
	_solo = _button(solo_row,"Jogar solo",_play_solo)
	if SaveSystem.has_save():
		_button(solo_row,"Continuar solo",SaveSystem.load_game)
	_options.add_child(HSeparator.new())
	_label(_options,"PARTIDA PARA DUAS PESSOAS",10).modulate = GOLD
	var host_row := HBoxContainer.new()
	_options.add_child(host_row)
	_role.add_item("Helena · 1923",0)
	_role.add_item("Lia · Hoje",1)
	_role.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_role.tooltip_text = "Sua personagem ao criar a sala"
	host_row.add_child(_role)
	_button(host_row,"Criar sala",func() -> void: NetSession.host(_role.get_selected_id()))
	_label(_options,"Entrar na sala de um amigo",12)
	var join_row := HBoxContainer.new()
	_options.add_child(join_row)
	_address.placeholder_text = "Endereço:porta"
	_address.max_length = 255
	_address.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_address.text_submitted.connect(func(_v: String) -> void: _join())
	join_row.add_child(_address)
	_button(join_row,"Entrar",_join)
	_form.add_child(_waiting)
	_label(_waiting,"REGISTRO DA DUPLA",10).modulate = GOLD
	_start = _button(_waiting,"Começar no Saguão",NetSession.start)
	_resume = _button(_waiting,"Retomar save da dupla",func() -> void: NetSession.start(true))
	_cancel = _button(_waiting,"Voltar",NetSession.leave)
	_status.custom_minimum_size.x = 294
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override("font_size",11)
	_status.modulate = GOLD
	_form.add_child(_status)
	NetSession.lobby_changed.connect(_refresh)
	_refresh()

func _play_solo() -> void:
	RoomManager.clear_away()
	WorldState.clear()
	EraManager.set_era(Era.Id.PAST_1923)
	get_tree().change_scene_to_file(NetSession.HOTEL)

func _join() -> void:
	NetSession.join(_address.text)

func _refresh() -> void:
	var idle := NetSession.phase == NetSession.Phase.OFF
	_options.visible = idle
	_waiting.visible = not idle
	_start.visible = NetSession.is_host
	_start.disabled = NetSession.phase != NetSession.Phase.WAITING
	_resume.visible = NetSession.is_host and FileAccess.file_exists(NetSession.SAVE)
	_resume.disabled = _start.disabled
	_status.text = NetSession.status
	if idle:
		_solo.grab_focus()
	elif _start.visible and not _start.disabled:
		_start.grab_focus()
	else:
		_cancel.grab_focus()

func _button(parent: Container, caption: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 25
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _label(parent: Container, caption: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = caption
	label.add_theme_font_size_override("font_size",font_size)
	parent.add_child(label)
	return label

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("#192527"))
	var w := size.x*0.39
	var mid := Vector2(w*0.5,size.y*0.5)
	draw_rect(Rect2(0,0,w,size.y),Color("#311E23"))
	for inset: int in [9,13]:
		draw_rect(Rect2(inset,inset,w-2*inset,size.y-2*inset),Color("#795E44"),false,1)
	draw_arc(mid+Vector2(0,-29),w*0.35,PI,TAU,64,GOLD,1,true)
	for i in 11:
		var direction := Vector2.from_angle(PI+i*PI/10)
		draw_line(mid+Vector2(0,-29)+direction*18,mid+Vector2(0,-29)+direction*w*0.32,Color("#886748"),1,true)
	draw_string(SIGN,Vector2(0,mid.y+7),"GRAND HOTEL",HORIZONTAL_ALIGNMENT_CENTER,w,19,GOLD)
	draw_string(SIGN,Vector2(0,mid.y+44),"AURORA",HORIZONTAL_ALIGNMENT_CENTER,w,33,INK)
	draw_string(FONT,Vector2(0,size.y-31),"1923    ◆    HOJE",HORIZONTAL_ALIGNMENT_CENTER,w,11,GOLD)
