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
## Capa da esquerda: 0 = 1923, 1 = hoje (em ruínas). Segue a personagem escolhida (Lia = hoje).
var _cover := 0.0
var _cover_tween: Tween

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
	_button(solo_row, "Configurações", _open_settings)
	if GamePlatform.can_fullscreen():
		_button(_options, "Tela cheia", GamePlatform.toggle_fullscreen)
	# Daqui para baixo (dupla e atualização) não existe na versão de navegador
	var first_extra := _options.get_child_count()
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
	_role.item_selected.connect(func(_index: int) -> void: _update_cover())
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
	if (OS.has_feature("template") and not GamePlatform.is_web()) or "--procurar-atualizacao" in OS.get_cmdline_user_args():
		_updater.check()
	_refresh_update()
	NetSession.lobby_changed.connect(_refresh)
	_refresh()
	if GamePlatform.is_web():
		for index in range(first_extra, _options.get_child_count()):
			(_options.get_child(index) as Control).visible = false
		_label(_options, "Versão de navegador %s · só o modo solo" % GameVersion.VERSION, 10).modulate = GOLD
	# Chegou à recepção: o remendo (se houver) funciona
	get_node("/root/PatchLoader").confirm()

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

func _open_settings() -> void:
	var menu := preload("res://scripts/ui/settings_menu.gd").new()
	menu.closed.connect(func() -> void: _solo.grab_focus())
	get_tree().root.add_child(menu)

## A capa passa para a de hoje com Lia e volta para a de 1923 com Helena.
func _update_cover() -> void:
	var era: int = _role.get_selected_id() if NetSession.phase == NetSession.Phase.OFF else NetSession.local_era
	var target := 1.0 if era == Era.Id.PRESENT else 0.0
	if is_equal_approx(target, _cover) or not is_inside_tree():
		return
	if _cover_tween:
		_cover_tween.kill()
	_cover_tween = create_tween()
	_cover_tween.tween_method(func(value: float) -> void:
		_cover = value
		queue_redraw(), _cover, target, 0.6)

func _play_solo() -> void:
	RoomManager.clear_away()
	WorldState.clear()
	EraManager.set_era(Era.Id.PAST_1923)
	RoomManager.open_scene(NetSession.HOTEL)

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
	_update_cover()
	if idle:
		_solo.grab_focus()
	elif _start.visible and not _start.disabled:
		_start.grab_focus()
	else:
		_cancel.grab_focus()

func _button(parent: Container, caption: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 34 if GamePlatform.is_touch() else 25
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
	if _cover < 1.0:
		_draw_cover_1923(w)
	if _cover > 0.0:
		_draw_cover_today(w, _cover)

func _draw_cover_1923(w: float) -> void:
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

## A mesma capa cem anos depois: madeira azulada, moldura partida, raios caídos e letras faltando
## (como a placa do Saguão de hoje). Desenhada por cima da de 1923 com a opacidade `alpha`.
func _draw_cover_today(w: float, alpha: float) -> void:
	var fade := func(color: Color) -> Color: return Color(color, color.a*alpha)
	var mid := Vector2(w*0.5, size.y*0.5)
	var sun := mid + Vector2(0, -29)
	var detail := Color("#3A4A58")
	var cold := Color("#9fb6c4")
	var dull := Color("#6E8596")
	draw_rect(Rect2(0, 0, w, size.y), fade.call(Color("#1C2630")))
	# Manchas de umidade
	# Manchas de umidade: círculos sobrepostos bem fracos, mais escuros no meio
	for stain: Array in [[Vector2(0.2, 0.14), 0.13], [Vector2(0.72, 0.72), 0.14], [Vector2(0.3, 0.9), 0.09]]:
		for ring in 6:
			draw_circle(Vector2(w*stain[0].x, size.y*stain[0].y), w*stain[1]*(1.0 - ring/7.0),
					fade.call(Color("#10171e", 0.09)))
	# Moldura partida: cada lado em pedaços, com falhas
	for inset: int in [9, 13]:
		var r := Rect2(inset, inset, w-2*inset, size.y-2*inset)
		var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
		for side in 4:
			var a: Vector2 = corners[side]
			var b: Vector2 = corners[(side + 1) % 4]
			for piece: Vector2 in [Vector2(0.0, 0.22), Vector2(0.27, 0.55), Vector2(0.61, 0.83), Vector2(0.9, 1.0)]:
				if (side + inset) % 3 == 0 and piece.x > 0.5 and piece.x < 0.7:
					continue
				draw_line(a.lerp(b, piece.x), a.lerp(b, piece.y), fade.call(detail), 1)
	# Arco rachado em três pedaços, um deles caído
	draw_arc(sun, w*0.35, PI, PI*1.38, 24, fade.call(dull), 1, true)
	draw_arc(sun, w*0.35, PI*1.44, PI*1.8, 24, fade.call(dull), 1, true)
	draw_arc(sun + Vector2(6, 9), w*0.35, PI*1.84, TAU*0.985, 12, fade.call(dull), 1, true)
	for i in 11:
		if i in [2, 5, 9]:
			continue  # raios que caíram
		var direction := Vector2.from_angle(PI+i*PI/10)
		var length := w*(0.32 if i % 4 != 1 else 0.22)
		draw_line(sun+direction*18, sun+direction*length, fade.call(Color(detail, 0.9)), 1, true)
	# Os raios caídos, no chão da capa
	draw_line(sun+Vector2(-w*0.2, w*0.06), sun+Vector2(-w*0.03, w*0.1), fade.call(detail), 1, true)
	draw_line(sun+Vector2(w*0.08, w*0.08), sun+Vector2(w*0.27, w*0.05), fade.call(detail), 1, true)
	# Rachaduras
	for crack: PackedVector2Array in [
			PackedVector2Array([Vector2(w, size.y*0.08), Vector2(w*0.86, size.y*0.15), Vector2(w*0.9, size.y*0.24),
					Vector2(w*0.78, size.y*0.31)]),
			PackedVector2Array([Vector2(0, size.y*0.62), Vector2(w*0.1, size.y*0.66), Vector2(w*0.07, size.y*0.74),
					Vector2(w*0.19, size.y*0.79)])]:
		draw_polyline(crack, fade.call(Color("#0f161c")), 1.5, true)
	_draw_worn(Vector2(0, mid.y+7), w, "GRAND HOTEL", 19, cold, [9], alpha)
	_draw_worn(Vector2(0, mid.y+44), w, "AURORA", 33, Color("#cfd6d4"), [3, 5], alpha)
	draw_string(FONT, Vector2(0, size.y-31), "1923    ◆    HOJE", HORIZONTAL_ALIGNMENT_CENTER, w, 11,
			fade.call(dull))

## Texto centralizado letra por letra; as letras de `missing` caíram (só sobra a marca na parede) e uma
## ficou torta.
func _draw_worn(at: Vector2, w: float, text: String, font_size: int, color: Color, missing: Array,
		alpha: float) -> void:
	var x := (w - SIGN.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)*0.5
	for i in text.length():
		var letter := text[i]
		var advance := SIGN.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		if i in missing:
			draw_string(SIGN, Vector2(x, at.y), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size,
					Color("#141c24", 0.8*alpha))
		elif i == 1:
			draw_set_transform(Vector2(x + advance*0.5, at.y), 0.12)
			draw_string(SIGN, Vector2(-advance*0.5, 2), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size,
					Color(color, color.a*alpha))
			draw_set_transform(Vector2.ZERO)
		else:
			draw_string(SIGN, Vector2(x, at.y), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size,
					Color(color, color.a*alpha))
		x += advance
