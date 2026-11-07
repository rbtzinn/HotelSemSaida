class_name Cutscene
extends CanvasLayer
## Cutscene no motor: uma câmera própria percorre o cenário 3D em tomadas, com faixas de cinema
## e legendas, e depois devolve a visão aos olhos da personagem ativa. Pausa o jogo enquanto toca.
## E, Enter ou Esc pulam. Cada cutscene toca uma vez: liga `cena.<id>` no WorldState (entra no
## save, não vai pela rede).
##
## Tomada (Dictionary): "from"/"to" (posição da câmera), "look_from"/"look_to" (para onde olha),
## ou "from_xform"/"to_xform" (Transform3D prontos); "time" (s); "caption" (legenda);
## "era" (Era.Id da tomada; sem a chave, fica a época atual); "fade" (escurece antes da tomada).

signal finished

const PREFIX := "cena."
const BAR_HEIGHT := 0.12
const BAR_TIME := 0.6

## Desligado nos testes sem janela, para não pausar os percursos automáticos; o teste das
## cutscenes liga de novo.
static var enabled: bool = DisplayServer.get_name() != "headless"

var _id: String
var _shots: Array
var _camera: Camera3D
var _top: ColorRect
var _bottom: ColorRect
var _caption: Label
var _black: ColorRect
var _tween: Tween
var _start_era: Era.Id
var _done := false


static func seen(id: String) -> bool:
	return WorldState.is_set(PREFIX + id)


static func is_playing(tree: SceneTree) -> bool:
	return not tree.get_nodes_in_group("cutscene").is_empty()


## Toca a cutscene, se ainda não foi vista. Devolve null quando não toca.
static func play(tree: SceneTree, id: String, shots: Array) -> Cutscene:
	if not enabled or seen(id) or is_playing(tree) or tree.current_scene == null or shots.is_empty():
		return null
	var scene := Cutscene.new()
	scene._id = id
	scene._shots = shots
	tree.root.add_child(scene)
	return scene


func _ready() -> void:
	add_to_group("cutscene")
	add_to_group("room_overlay")
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_start_era = EraManager.current_era
	WorldState.set_flag(PREFIX + _id)
	get_tree().paused = true
	get_tree().call_group("hud", "set", "visible", false)

	_camera = Camera3D.new()
	_camera.name = "CutsceneCamera"
	_camera.fov = 62.0
	_camera.near = 0.05
	_camera.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().current_scene.add_child(_camera)

	_black = _rect(Color(0, 0, 0, 0))
	_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	_top = _rect(Color.BLACK)
	_top.anchor_right = 1.0
	_bottom = _rect(Color.BLACK)
	_bottom.anchor_right = 1.0
	_bottom.anchor_top = 1.0
	_bottom.anchor_bottom = 1.0
	_caption = Label.new()
	_caption.add_theme_font_override("font", preload("res://art/fonts/interface_font.tres"))
	_caption.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_caption.add_theme_font_size_override("font_size", 12)
	_caption.add_theme_color_override("font_color", Color("#EAE2CF"))
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.anchor_left = 0.08
	_caption.anchor_right = 0.92
	_caption.anchor_top = 1.0 - BAR_HEIGHT
	_caption.anchor_bottom = 1.0
	_caption.modulate.a = 0.0
	add_child(_caption)
	_play_shot(0)


func _rect(color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
	return rect


func _process(_delta: float) -> void:
	# As faixas acompanham o tamanho da janela
	var height := get_viewport().get_visible_rect().size.y
	var amount := _top.get_meta("amount", 0.0) as float
	_top.offset_bottom = height * BAR_HEIGHT * amount
	_bottom.offset_top = -height * BAR_HEIGHT * amount
	# Alguma tela que despausou ao fechar não pode soltar o jogo no meio da cena
	if not _done:
		get_tree().paused = true


func _bars_to(value: float) -> void:
	_tween.tween_method(func(amount: float) -> void: _top.set_meta("amount", amount),
		_top.get_meta("amount", 0.0), value, BAR_TIME)


func _play_shot(index: int) -> void:
	if _done:
		return
	if index >= _shots.size():
		_finish()
		return
	var shot: Dictionary = _shots[index]
	var from := _xform(shot, "from")
	var to := _xform(shot, "to")
	var time := float(shot.get("time", 4.0))
	_tween = create_tween()
	if index == 0:
		_bars_to(1.0)
	var fade := bool(shot.get("fade", shot.has("era") and int(shot.era) != EraManager.current_era))
	if fade:
		_tween.tween_property(_black, "color:a", 1.0, 0.35)
	_tween.tween_callback(func() -> void:
		if shot.has("era") and int(shot.era) != EraManager.current_era:
			EraManager.set_era(int(shot.era))
		_camera.global_transform = from
		_camera.make_current()
		_caption.text = str(shot.get("caption", ""))
		_caption.modulate.a = 0.0)
	if fade:
		_tween.tween_property(_black, "color:a", 0.0, 0.45)
	_tween.tween_method(func(weight: float) -> void:
		_camera.global_transform = from.interpolate_with(to, _ease(weight)), 0.0, 1.0, time)
	if str(shot.get("caption", "")) != "":
		var caption := create_tween()
		caption.tween_interval(0.8 if fade else 0.3)
		caption.tween_property(_caption, "modulate:a", 1.0, 0.6)
		caption.tween_interval(maxf(time - 2.2, 0.4))
		caption.tween_property(_caption, "modulate:a", 0.0, 0.5)
	_tween.tween_callback(_play_shot.bind(index + 1))


static func _ease(weight: float) -> float:
	return weight * weight * (3.0 - 2.0 * weight)


func _xform(shot: Dictionary, key: String) -> Transform3D:
	if shot.has(key + "_xform"):
		return shot[key + "_xform"]
	var at: Vector3 = shot[key]
	var look: Vector3 = shot["look_" + key]
	return Transform3D(Basis.looking_at(look - at, Vector3.UP), at)


func _unhandled_input(event: InputEvent) -> void:
	if _done:
		return
	for action in ["interact", "ui_accept", "ui_cancel", "pause"]:
		if event.is_action_pressed(action):
			get_viewport().set_input_as_handled()
			skip()
			return


func skip() -> void:
	if _done:
		return
	if _tween:
		_tween.kill()
	_finish()


func _finish() -> void:
	_done = true
	var out := create_tween()
	out.tween_property(_black, "color:a", 1.0, 0.3)
	out.tween_callback(func() -> void:
		_caption.modulate.a = 0.0
		_top.set_meta("amount", 0.0)
		EraManager.set_era(_start_era)
		if is_instance_valid(_camera):
			_camera.queue_free()
		get_tree().call_group("hud", "set", "visible", true))
	out.tween_property(_black, "color:a", 0.0, 0.4)
	out.tween_callback(func() -> void:
		finished.emit()
		remove_from_group("room_overlay")
		remove_from_group("cutscene")
		UIUtil.unpause_after_release(get_tree())
		queue_free())
