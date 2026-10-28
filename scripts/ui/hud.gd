extends CanvasLayer
## HUD mínimo: ícone da personagem ativa e o ano, no canto superior esquerdo,
## e mensagens curtas na parte de baixo da tela (grupo "hud", show_message).

const MESSAGE_DURATION: float = 2.5

var _icon: Panel
var _icon_style: StyleBoxFlat
var _label: Label
var _message: Label
var _message_tween: Tween


func _ready() -> void:
	layer = 10
	add_to_group("hud")

	_message = Label.new()
	_message.position = Vector2(0, 328)
	_message.size = Vector2(640, 16)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.add_theme_font_size_override("font_size", 10)
	_message.add_theme_color_override("font_color", Color("#E8E2D0"))
	_message.add_theme_color_override("font_outline_color", Color.BLACK)
	_message.add_theme_constant_override("outline_size", 2)
	_message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_message.modulate.a = 0.0
	add_child(_message)

	var row := HBoxContainer.new()
	row.position = Vector2(8, 8)
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)

	# Ícone: retângulo na proporção da personagem (24×48), com borda clara
	_icon_style = StyleBoxFlat.new()
	_icon_style.set_border_width_all(1)
	_icon_style.border_color = Color("#E8E2D0")
	_icon = Panel.new()
	_icon.custom_minimum_size = Vector2(8, 16)
	_icon.add_theme_stylebox_override("panel", _icon_style)
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_icon)

	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 10)
	_label.add_theme_color_override("font_color", Color("#E8E2D0"))
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 2)
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_label)

	EraManager.era_changed.connect(_refresh)
	# O objeto na mão fica no WorldState
	WorldState.flag_changed.connect(_on_flag_changed)
	_refresh(EraManager.current_era)


func show_message(text: String) -> void:
	_message.text = text
	_message.modulate.a = 1.0
	if _message_tween:
		_message_tween.kill()
	_message_tween = create_tween()
	_message_tween.tween_interval(MESSAGE_DURATION)
	_message_tween.tween_property(_message, "modulate:a", 0.0, 0.5)


func _on_flag_changed(_key: String, _value: Variant) -> void:
	_refresh(EraManager.current_era)


func _refresh(era: Era.Id) -> void:
	_icon_style.bg_color = Era.character_color(era)
	var name_text := Era.character_name(era)
	_label.text = "%s · %s" % [name_text, Era.year_label(era)]
	var item := str(WorldState.get_flag("%s.mao" % name_text.to_lower(), ""))
	if item != "":
		_label.text += " · %s" % Items.display_name(item)
