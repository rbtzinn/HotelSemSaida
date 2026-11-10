class_name TouchControls
extends CanvasLayer
## Controles na tela para celular (versão de navegador). Jogando: metade esquerda é o analógico
## de andar (nasce onde o dedo encosta), metade direita arrasta o olhar, e há botões de Usar,
## Pular, trocar de Época e Pausa. Com uma tela em close aberta (bilhete, cadeado, relógio,
## pausa), o analógico vira quatro setas e sobram Usar e Voltar.
## Tudo sai como ações do Input Map, então o resto do jogo não sabe que é toque.

const FONT := preload("res://art/fonts/interface_font.tres")
## Raio do analógico e zona morta, em pixels da tela lógica (640×360).
const STICK_RADIUS: float = 36.0
const STICK_DEADZONE: float = 0.18
## Quantos "pixels de mouse" vale um pixel lógico arrastado no olhar.
const LOOK_SCALE: float = 1.5
## Um arrasto maior que isto num só evento (pixels lógicos) é salto do navegador, não dedo:
## acontece quando um segundo dedo encosta ou a página se mexe. É descartado.
const LOOK_JUMP: float = 70.0
## Fração do olhar pendente entregue a cada quadro: espalha os eventos de toque, que chegam
## em rajadas, para a câmera não dar trancos.
const LOOK_SMOOTHING: float = 0.45
const MOVES := ["move_left", "move_right", "move_up", "move_down"]
const INK := Color("#E8E2D0")

## Botões: ação, centro, raio e rótulo.
## Ação que não vai para o Input Map: o botão de tela cheia (só onde o navegador deixa).
const FULLSCREEN := "fullscreen"
const FULLSCREEN_BUTTON := [FULLSCREEN, Vector2(582, 22), 15.0, ""]

const PLAY_BUTTONS := [
	["interact", Vector2(588, 286), 27.0, "Usar"],
	["jump", Vector2(528, 322), 21.0, "Pular"],
	["switch_era", Vector2(600, 74), 21.0, "Época"],
	["pause", Vector2(618, 22), 15.0, "II"],
]
const MENU_BUTTONS := [
	["move_left", Vector2(48, 296), 21.0, "<"],
	["move_right", Vector2(132, 296), 21.0, ">"],
	["move_up", Vector2(90, 256), 21.0, "^"],
	["move_down", Vector2(90, 332), 21.0, "v"],
	["interact", Vector2(588, 286), 27.0, "Usar"],
	["pause", Vector2(618, 22), 15.0, "X"],
]

## Dedo (índice do toque) → o que ele está fazendo: {"kind": "stick"|"look"|"button", ...}
var _touches: Dictionary = {}
var _stick_origin := Vector2.ZERO
var _stick_vector := Vector2.ZERO
var _was_paused: bool = false
## Olhar arrastado ainda não entregue à personagem.
var _look_pending := Vector2.ZERO
var _canvas: Control
var _can_fullscreen: bool = false


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	_can_fullscreen = GamePlatform.can_fullscreen()
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_controls)
	add_child(_canvas)


func _exit_tree() -> void:
	_release_all()


func _process(_delta: float) -> void:
	var paused := get_tree().paused
	if paused != _was_paused:
		# Trocou entre jogar e tela em close: solta tudo, os botões mudam de lugar
		_was_paused = paused
		_release_all()
		_canvas.queue_redraw()
	if paused:
		_look_pending = Vector2.ZERO
	elif _look_pending != Vector2.ZERO:
		var step := _look_pending * LOOK_SMOOTHING
		if _look_pending.length() < 0.5:
			step = _look_pending
		_look_pending -= step
		ActionCharacterInput.pending_mouse += step


func _buttons() -> Array:
	var buttons: Array = (MENU_BUTTONS if get_tree().paused else PLAY_BUTTONS).duplicate()
	if _can_fullscreen:
		buttons.append(FULLSCREEN_BUTTON)
	return buttons


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_down(event.index, event.position)
		else:
			_touch_up(event.index)
	elif event is InputEventScreenDrag and _touches.has(event.index):
		var touch: Dictionary = _touches[event.index]
		if touch.kind == "stick":
			_set_stick((event.position - _stick_origin) / STICK_RADIUS)
		elif touch.kind == "look" and event.relative.length() < LOOK_JUMP:
			_look_pending += event.relative * LOOK_SCALE


func _touch_down(index: int, at: Vector2) -> void:
	for button: Array in _buttons():
		if at.distance_to(button[1]) <= float(button[2]) + 6.0:
			_touches[index] = {"kind": "button", "action": button[0]}
			if button[0] == FULLSCREEN:
				# Dentro do evento de toque: o navegador só aceita o pedido assim
				GamePlatform.toggle_fullscreen()
			else:
				_send(button[0], true)
			_canvas.queue_redraw()
			return
	if get_tree().paused:
		return
	if at.x < 320.0:
		if _has_kind("stick"):
			return
		_touches[index] = {"kind": "stick"}
		_stick_origin = at
		_set_stick(Vector2.ZERO)
	else:
		_touches[index] = {"kind": "look"}


func _touch_up(index: int) -> void:
	if not _touches.has(index):
		return
	var touch: Dictionary = _touches[index]
	_touches.erase(index)
	if touch.kind == "button":
		if touch.action != FULLSCREEN:
			_send(touch.action, false)
	elif touch.kind == "stick":
		_set_stick(Vector2.ZERO)
	_canvas.queue_redraw()


func _has_kind(kind: String) -> bool:
	for touch: Dictionary in _touches.values():
		if touch.kind == kind:
			return true
	return false


## Aperta ou solta uma ação como se fosse uma tecla (as telas em close leem o evento).
func _send(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


## Analógico de andar: força de cada direção, direto nas ações de movimento.
func _set_stick(vector: Vector2) -> void:
	_stick_vector = vector.limit_length(1.0)
	var strengths := [-_stick_vector.x, _stick_vector.x, -_stick_vector.y, _stick_vector.y]
	for i in MOVES.size():
		var strength := maxf(0.0, strengths[i])
		if strength > STICK_DEADZONE:
			Input.action_press(MOVES[i], strength)
		else:
			Input.action_release(MOVES[i])
	_canvas.queue_redraw()


func _release_all() -> void:
	for touch: Dictionary in _touches.values():
		if touch.kind == "button" and touch.action != FULLSCREEN:
			_send(touch.action, false)
	_touches.clear()
	_look_pending = Vector2.ZERO
	_stick_vector = Vector2.ZERO
	for action: String in MOVES:
		Input.action_release(action)


## Quatro cantos de uma moldura: o desenho de sempre para "tela cheia".
func _draw_fullscreen_icon(center: Vector2, color: Color) -> void:
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var tip := center + corner * 6.0
		_canvas.draw_line(tip, tip - Vector2(corner.x * 4.0, 0), color, 1.5)
		_canvas.draw_line(tip, tip - Vector2(0, corner.y * 4.0), color, 1.5)


func _draw_controls() -> void:
	var held: Array = []
	for touch: Dictionary in _touches.values():
		if touch.kind == "button":
			held.append(touch.action)
	for button: Array in _buttons():
		var center: Vector2 = button[1]
		var radius: float = button[2]
		var down: bool = button[0] in held
		_canvas.draw_circle(center, radius, Color(0.02, 0.02, 0.03, 0.55 if down else 0.3))
		_canvas.draw_arc(center, radius, 0.0, TAU, 40, Color(INK, 0.9 if down else 0.5), 1.0, true)
		if button[0] == FULLSCREEN:
			_draw_fullscreen_icon(center, Color(INK, 0.95 if down else 0.75))
			continue
		var label: String = button[3]
		var font_size := 10 if label.length() > 2 else 12
		var width := FONT.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		_canvas.draw_string(FONT, center + Vector2(-width / 2.0, font_size * 0.35), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(INK, 0.95 if down else 0.75))
	if _has_kind("stick"):
		_canvas.draw_arc(_stick_origin, STICK_RADIUS, 0.0, TAU, 48, Color(INK, 0.4), 1.0, true)
		_canvas.draw_circle(_stick_origin + _stick_vector * STICK_RADIUS, 13.0, Color(INK, 0.35))
