class_name ClockUI
extends CanvasLayer
## Minigame dos ponteiros do relógio da torre, em close. A/D (ou setas) giram o ponteiro dos
## minutos, de 1 em 1 minuto (segurando, acelera), e o das horas anda junto, como num relógio de
## verdade. E/Enter deixam os ponteiros na hora mostrada (`confirmed`); Esc sai sem mexer.
## A hora vai de 0 a 719 minutos (0 = 12h00). Pausa o jogo enquanto está aberto.

signal confirmed(minutes: int)

const DAY := 720
const FACE := Color("#EDE4CF")
const INK := Color("#1A1214")
const BRASS := Color("#C9973B")


## Mostrador desenhado: marcas das horas, algarismos e os dois ponteiros.
class Dial extends Control:
	var minutes := 0

	func _draw() -> void:
		var center := size / 2.0
		var radius := minf(size.x, size.y) / 2.0 - 4.0
		draw_circle(center, radius + 4.0, BRASS)
		draw_circle(center, radius, FACE)
		var font := preload("res://art/fonts/interface_font.tres")
		for h in 12:
			var angle := TAU * h / 12.0
			var direction := Vector2(sin(angle), -cos(angle))
			var long := h % 3 == 0
			draw_line(center + direction * (radius - (14.0 if long else 9.0)), center + direction * (radius - 3.0), INK, 3.0 if long else 1.5)
			var text: String = ["XII", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI"][h]
			var at := center + direction * (radius - 28.0)
			var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
			draw_string(font, at + Vector2(-width / 2.0, 4.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, INK)
		var minute_angle := TAU * (minutes % 60) / 60.0
		var hour_angle := TAU * minutes / float(DAY)
		draw_line(center, center + Vector2(sin(hour_angle), -cos(hour_angle)) * radius * 0.5, INK, 5.0)
		draw_line(center, center + Vector2(sin(minute_angle), -cos(minute_angle)) * radius * 0.8, INK, 3.0)
		draw_circle(center, 5.0, BRASS)


var minutes := 0
var _dial: Dial
var _held := 0
var _last_tick := 0


static func open(tree: SceneTree, start: int) -> ClockUI:
	var ui := ClockUI.new()
	ui.minutes = posmod(start, DAY)
	tree.root.add_child(ui)
	return ui


func _ready() -> void:
	add_to_group("room_overlay")
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true

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
	column.add_child(_make_label("Mostrador de acerto", 14))
	_dial = Dial.new()
	_dial.custom_minimum_size = Vector2(200, 200)
	_dial.minutes = minutes
	column.add_child(_dial)
	column.add_child(_make_label("%s/%s giram os ponteiros · %s deixar nesta hora · Esc sair" % [
		Settings.binding_label("move_left"), Settings.binding_label("move_right"), Settings.binding_label("interact")], 10))


func _unhandled_input(event: InputEvent) -> void:
	var step := 0
	if _pressed(event, ["move_left", "ui_left"]):
		step = -1
	elif _pressed(event, ["move_right", "ui_right"]):
		step = 1
	if step != 0:
		# Segurando a tecla, os ponteiros correm mais
		_held = _held + 1 if event.is_echo() else 0
		turn(step * (5 if _held > 8 else 1))
		get_viewport().set_input_as_handled()
		return
	if _pressed(event, ["interact", "ui_accept"]):
		get_viewport().set_input_as_handled()
		confirm()
	elif _pressed(event, ["ui_cancel", "pause"]):
		get_viewport().set_input_as_handled()
		close()


## Gira o ponteiro dos minutos (negativo volta). Usado também pelos testes.
func turn(amount: int) -> void:
	minutes = posmod(minutes + amount, DAY)
	# Segurando, os ponteiros correm: um tique a cada 60 ms basta
	var now := Time.get_ticks_msec()
	if now - _last_tick > 60:
		_last_tick = now
		Audio.play("tique", -8.0)
	_dial.minutes = minutes
	_dial.queue_redraw()


func confirm() -> void:
	Audio.play("corda", -4.0)
	confirmed.emit(minutes)
	close()


func close() -> void:
	visible = false
	set_process_unhandled_input(false)
	await UIUtil.unpause_after_release(get_tree())
	queue_free()


static func describe(value: int) -> String:
	var hours := posmod(value, DAY) / 60
	return "%dh%02d" % [12 if hours == 0 else hours, posmod(value, 60)]


func _pressed(event: InputEvent, actions: Array) -> bool:
	for action in actions:
		if event.is_action_pressed(action, true):
			return true
	return false


func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", preload("res://art/fonts/interface_font.tres"))
	label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("#E8E2D0"))
	return label
