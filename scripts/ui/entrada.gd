extends Control
## Recepção anterior à campanha. A sala da dupla abre por código (Epic) ou, no plano B, por
## endereço:porta. O anfitrião escolhe a personagem (pode trocar até começar) e decide entre
## jogo novo e retomar o save da dupla.
const INK := Color("#EAE2CF")
const GOLD := Color("#D6B272")
const FONT := preload("res://art/fonts/interface_font.tres")
const SIGN := preload("res://art/fonts/sign_font.tres")
var _form := VBoxContainer.new()
var _options := VBoxContainer.new()
var _waiting := VBoxContainer.new()
var _address_box := VBoxContainer.new()
var _role := OptionButton.new()
var _room_role := OptionButton.new()
var _name := LineEdit.new()
var _code := LineEdit.new()
var _address := LineEdit.new()
var _status := Label.new()
var _room_title := Label.new()
var _room_code := Label.new()
var _copy: Button
var _role_row := HBoxContainer.new()
var _start: Button
var _resume: Button
var _cancel: Button
var _solo: Button
var _create: Button
var _version := Label.new()
var _update: Button
var _updater := Updater.new()

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
	_form.add_theme_constant_override("separation", 6)
	panel.add_child(_form)
	var title := _label(_form, "Livro de entrada", 22)
	title.add_theme_color_override("font_color", INK)
	_form.add_child(_options)
	_options.add_theme_constant_override("separation", 5)
	var solo_row := HBoxContainer.new()
	_options.add_child(solo_row)
	_solo = _button(solo_row, "Jogar solo", _play_solo)
	if SaveSystem.has_save():
		_button(solo_row, "Continuar solo", SaveSystem.load_game)
	_options.add_child(HSeparator.new())
	_label(_options, "PARTIDA PARA DUAS PESSOAS", 10).modulate = GOLD
	_name.placeholder_text = "Seu nome (a outra pessoa vê)"
	_name.max_length = NetSession.MAX_NAME
	_name.text = str(Settings.data.get("player_name", ""))
	_options.add_child(_name)
	var host_row := HBoxContainer.new()
	_options.add_child(host_row)
	_fill_roles(_role)
	_role.tooltip_text = "Sua personagem (dá para trocar até começar)"
	host_row.add_child(_role)
	_create = _button(host_row, "Criar sala", _host_room)
	var join_row := HBoxContainer.new()
	_options.add_child(join_row)
	_code.placeholder_text = "Código da sala"
	_code.max_length = 12
	_code.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_code.text_submitted.connect(func(_v: String) -> void: _join_room())
	join_row.add_child(_code)
	_button(join_row, "Entrar", _join_room)
	var more := _button(_options, "Plano B: entrar por endereço (Playit) ▸", func() -> void:
		_address_box.visible = not _address_box.visible)
	more.flat = true
	more.add_theme_font_size_override("font_size", 10)
	_options.add_child(_address_box)
	_address_box.visible = false
	var address_row := HBoxContainer.new()
	_address_box.add_child(address_row)
	_address.placeholder_text = "Endereço:porta"
	_address.max_length = 255
	_address.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_address.text_submitted.connect(func(_v: String) -> void: _join())
	address_row.add_child(_address)
	_button(address_row, "Entrar", _join)
	_button(_address_box, "Criar sala por endereço (UDP %d)" % NetSession.PORT, func() -> void:
		_save_name()
		NetSession.host(_role.get_selected_id()))
	_form.add_child(_waiting)
	_waiting.add_theme_constant_override("separation", 5)
	_label(_waiting, "SALA DA DUPLA", 10).modulate = GOLD
	var code_row := HBoxContainer.new()
	_waiting.add_child(code_row)
	_room_title.add_theme_font_size_override("font_size", 11)
	code_row.add_child(_room_title)
	_room_code.add_theme_font_size_override("font_size", 24)
	_room_code.add_theme_color_override("font_color", INK)
	_room_code.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	code_row.add_child(_room_code)
	_copy = _button(code_row, "Copiar", _copy_code)
	_copy.size_flags_horizontal = Control.SIZE_SHRINK_END
	_waiting.add_child(_role_row)
	_label(_role_row, "Sua personagem:", 11)
	_fill_roles(_room_role)
	_room_role.item_selected.connect(func(index: int) -> void:
		NetSession.choose_era(_room_role.get_item_id(index) as Era.Id))
	_role_row.add_child(_room_role)
	var start_row := HBoxContainer.new()
	_waiting.add_child(start_row)
	_start = _button(start_row, "Novo jogo", NetSession.start)
	_resume = _button(start_row, "Retomar save", func() -> void: NetSession.start(true))
	_cancel = _button(_waiting, "Voltar", NetSession.leave)
	_status.custom_minimum_size.x = 294
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override("font_size", 11)
	_status.modulate = GOLD
	_form.add_child(_status)
	_options.add_child(HSeparator.new())
	var update_row := HBoxContainer.new()
	_options.add_child(update_row)
	_version.add_theme_font_size_override("font_size", 10)
	_version.modulate = GOLD
	_version.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_version.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	update_row.add_child(_version)
	_update = _button(update_row, "", _on_update)
	add_child(_updater)
	_updater.changed.connect(_refresh_update)
	# Só o jogo exportado procura (no editor, os arquivos já são os atuais); o argumento serve para testar
	if OS.has_feature("template") or "--procurar-atualizacao" in OS.get_cmdline_user_args():
		_updater.check()
	_refresh_update()
	NetSession.lobby_changed.connect(_refresh)
	_refresh()

func _process(_delta: float) -> void:
	if _updater.state == Updater.State.DOWNLOADING:
		_refresh_update()

func _refresh_update() -> void:
	var version := GameVersion.VERSION
	var next := str(_updater.manifest.get("version", ""))
	var caption := ""
	var text := "Versão %s" % version
	match _updater.state:
		Updater.State.CHECKING:
			text += " · procurando atualização…"
		Updater.State.UP_TO_DATE:
			text += " · em dia"
		Updater.State.PATCH:
			caption = "Atualizar para %s (%s MB)" % [next, ("%.1f" % _updater.patch_megabytes()).replace(".", ",")]
		Updater.State.NEW_ZIP:
			if _updater.can_install_full():
				var size := _updater.full_megabytes()
				caption = "Atualizar para %s" % next + (" (%d MB)" % maxi(1, roundi(size)) if size > 0.0 else "")
			else:
				text += ". A %s precisa do jogo novo (ZIP)." % next
				caption = "Baixar a versão %s" % next
		Updater.State.DOWNLOADING:
			text = "Baixando a versão %s… %d%%" % [next, roundi(_updater.progress()*100.0)]
		Updater.State.READY:
			text = "Versão %s baixada." % next
			caption = "Reiniciar o jogo"
		Updater.State.FAILED:
			if _updater.download_failed:
				text = "Não deu para baixar a atualização."
				caption = "Tentar de novo"
			else:
				text += " · não deu para procurar atualização"
	_version.text = text
	_update.text = caption
	_update.visible = caption != ""

func _on_update() -> void:
	match _updater.state:
		Updater.State.PATCH:
			_updater.download()
		Updater.State.NEW_ZIP:
			if _updater.can_install_full():
				_updater.download_full()
			else:
				_updater.open_page()
		Updater.State.READY:
			_updater.restart()
		Updater.State.FAILED:
			_updater.check()

func _fill_roles(button: OptionButton) -> void:
	button.add_item("Helena · 1923", Era.Id.PAST_1923)
	button.add_item("Lia · Hoje", Era.Id.PRESENT)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _play_solo() -> void:
	RoomManager.clear_away()
	WorldState.clear()
	EraManager.set_era(Era.Id.PAST_1923)
	get_tree().change_scene_to_file(NetSession.HOTEL)

func _save_name() -> void:
	var name_text := NetSession.clean_name(_name.text)
	if name_text != str(Settings.data.get("player_name", "")):
		Settings.data.player_name = name_text
		Settings.save()

func _host_room() -> void:
	_save_name()
	NetSession.host_room(_role.get_selected_id() as Era.Id)

func _join_room() -> void:
	_save_name()
	NetSession.join_room(_code.text)

func _join() -> void:
	_save_name()
	NetSession.join(_address.text)

func _copy_code() -> void:
	DisplayServer.clipboard_set(NetSession.room_code)
	_copy.text = "Copiado"
	get_tree().create_timer(1.5).timeout.connect(func() -> void:
		if is_instance_valid(_copy):
			_copy.text = "Copiar")

func _refresh() -> void:
	var idle := NetSession.phase == NetSession.Phase.OFF
	var host := NetSession.is_host
	_options.visible = idle
	_waiting.visible = not idle
	var has_code := NetSession.room_code != ""
	if has_code:
		_room_title.text = "Código:" if host else "Sala"
		_room_code.text = NetSession.room_code
	else:
		_room_title.text = "Por endereço" if host else "Conectando"
		_room_code.text = "UDP %d" % NetSession.PORT if host else ""
	_copy.visible = host and has_code and NetSession.phase in [NetSession.Phase.HOSTING, NetSession.Phase.WAITING]
	_role_row.visible = host
	_room_role.select(_room_role.get_item_index(NetSession.local_era))
	_start.visible = host
	_start.disabled = NetSession.phase != NetSession.Phase.WAITING
	_resume.visible = host and FileAccess.file_exists(NetSession.SAVE)
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
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#192527"))
	var w := size.x*0.39
	var mid := Vector2(w*0.5, size.y*0.5)
	draw_rect(Rect2(0, 0, w, size.y), Color("#311E23"))
	for inset: int in [9, 13]:
		draw_rect(Rect2(inset, inset, w-2*inset, size.y-2*inset), Color("#795E44"), false, 1)
	draw_arc(mid+Vector2(0, -29), w*0.35, PI, TAU, 64, GOLD, 1, true)
	for i in 11:
		var direction := Vector2.from_angle(PI+i*PI/10)
		draw_line(mid+Vector2(0, -29)+direction*18, mid+Vector2(0, -29)+direction*w*0.32, Color("#886748"), 1, true)
	draw_string(SIGN, Vector2(0, mid.y+7), "GRAND HOTEL", HORIZONTAL_ALIGNMENT_CENTER, w, 19, GOLD)
	draw_string(SIGN, Vector2(0, mid.y+44), "AURORA", HORIZONTAL_ALIGNMENT_CENTER, w, 33, INK)
	draw_string(FONT, Vector2(0, size.y-31), "1923    ◆    HOJE", HORIZONTAL_ALIGNMENT_CENTER, w, 11, GOLD)
