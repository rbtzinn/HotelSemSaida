extends Node
## Abertura de uma partida nova. A câmera e a época do voo são locais a cada tela.

const EXTERIOR := preload("res://scripts/world3d/opening_exterior_3d.gd")
const SIGN := preload("res://art/fonts/sign_font.tres")
const FONT := preload("res://art/fonts/interface_font.tres")
const SKY := preload("res://shaders/sky_env_night.gdshader")
const GOLD := Color("#F2CB88")
const SILVER := Color("#C0D6ED")
const INK := Color("#F5EBDD")

const WINDOW_CUT: float = 4.85
const WIDE_SHOT: float = 9.7
const ERA_CUT: float = 11.6
const DESCENT: float = 17.4
const RETURN_CUT: float = 20.55
const END: float = 22.0
const EXTERIOR_ORIGIN := Vector3(230, 0, 0)
const WIDE_POSITION := Vector3(10.5, 18.2, 36.5)
const WIDE_TARGET := Vector3(0, 9.35, 3.4)

enum Shot { LOBBY, EXTERIOR_1923, EXTERIOR_TODAY, RETURN }

var _room: Node3D
var _past: Node3D
var _today: Node3D
var _lia: Node3D
var _hud: CanvasLayer
var _room_environment: EraEnvironment
var _start_camera: Camera3D
var _player_camera: Camera3D
var _camera := Camera3D.new()
var _outside_1923: Node3D
var _outside_today: Node3D
var _overlay := Control.new()
var _skip_button := Button.new()
var _title_shade := GradientTexture2D.new()
var _shot := Shot.LOBBY
var _elapsed: float = 0.0
var _owns_pause: bool = false


static func start_in(room: Node) -> void:
	var opening := new()
	opening.name = "Opening"
	room.add_child(opening)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_room = get_parent() as Node3D
	_past = _room.get_node("World1923") as Node3D
	_today = _room.get_node("WorldToday") as Node3D
	_lia = _room.get_node("Lia") as Node3D
	_hud = _room.get_node("HUD") as CanvasLayer
	_room_environment = _room.get_node("WorldEnvironment") as EraEnvironment
	_start_camera = (_room.get_node("Helena") as FirstPersonMotor).get_camera()
	var actor := _room.get_node(Era.character_name(EraManager.current_era)) as FirstPersonMotor
	_player_camera = actor.get_camera()
	_owns_pause = not get_tree().paused
	get_tree().paused = true
	_hud.hide()
	_past.show()
	_today.hide()
	_lia.hide()
	add_child(_camera)
	_camera.near = 0.055
	_camera.far = 120.0
	_camera.environment = _room_environment.for_era(Era.Id.PAST_1923)
	_camera.global_transform = _start_camera.global_transform
	_camera.make_current()
	Audio.play_room_ambience(Era.Id.PAST_1923, 0.45)
	_outside_1923 = _build_exterior(false)
	_outside_today = _build_exterior(true)
	_build_overlay()


func _build_exterior(present: bool) -> Node3D:
	var facade := EXTERIOR.new()
	facade.present = present
	facade.position = EXTERIOR_ORIGIN
	facade.hide()
	add_child(facade)
	return facade


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_skip()


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= END:
		_finish()
		return

	if _elapsed >= RETURN_CUT:
		if _shot != Shot.RETURN:
			_begin_return()
		_move_into_player()
	elif _elapsed >= WINDOW_CUT:
		if _shot == Shot.LOBBY:
			_show_exterior(false)
		if _elapsed >= ERA_CUT and _shot == Shot.EXTERIOR_1923:
			_show_exterior(true)
		_move_outside()
	else:
		_move_to_window()

	_overlay.queue_redraw()


func _move_to_window() -> void:
	var start := _start_camera.global_transform
	var window := LobbyRoom3D.WINDOWS[1]
	var end := Vector3(LobbyRoom3D.EAST - 0.3, 3.43, (window.x + window.y) / 2.0)
	var t := smoothstep(0.25, WINDOW_CUT, _elapsed)
	var at := start.origin.bezier_interpolate(Vector3(10.2, 2.5, 5.3), Vector3(15.7, 3.8, 6.5), end, t)
	var ahead := Transform3D(Basis.looking_at(Vector3(1.0, 0.06, 0.19)), at)
	_camera.global_transform = Transform3D(start.basis, at).interpolate_with(
		ahead, smoothstep(0.3, 2.15, _elapsed))
	_camera.fov = lerpf(_start_camera.fov, 59.0, t)


func _show_exterior(present: bool) -> void:
	_shot = Shot.EXTERIOR_TODAY if present else Shot.EXTERIOR_1923
	_past.hide()
	_outside_1923.visible = not present
	_outside_today.visible = present
	_camera.environment = _exterior_environment(present)
	Audio.play_room_ambience(Era.Id.PRESENT if present else Era.Id.PAST_1923, 0.65)
	if present:
		Audio.play("troca_epoca", -12.0, 0.0)


func _exterior_environment(present: bool) -> Environment:
	var sky_shader := ShaderMaterial.new()
	sky_shader.shader = SKY
	sky_shader.set_shader_parameter("star_energy", 0.6 if present else 0.85)
	sky_shader.set_shader_parameter("moon_energy", 0.85 if present else 1.1)
	sky_shader.set_shader_parameter("moon_direction", Vector3(-0.63, 0.105, -0.76))
	var sky := Sky.new()
	sky.sky_material = sky_shader
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#A2B5D8") if present else Color("#F1D4B0")
	env.ambient_light_energy = 0.96 if present else 0.58
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.fog_enabled = true
	env.fog_density = 0.007 if present else 0.003
	env.fog_light_color = Color("#242F42") if present else Color("#221C21")
	env.fog_sky_affect = 0.0
	env.glow_enabled = true
	env.glow_bloom = 0.04
	return env


func _move_outside() -> void:
	var at := WIDE_POSITION
	var target := WIDE_TARGET
	var fov := 51.0
	if _elapsed < WIDE_SHOT:
		var t := smoothstep(WINDOW_CUT, WIDE_SHOT, _elapsed)
		at = Vector3(5.2, 5.1, 13.4).bezier_interpolate(
			Vector3(9.0, 7.0, 16.0), Vector3(15.4, 15.6, 25.7), WIDE_POSITION, t)
		target = Vector3(0, 5.15, 7.5).lerp(WIDE_TARGET, t)
		fov = lerpf(60.0, fov, t)
	elif _elapsed > DESCENT:
		var t := smoothstep(DESCENT, RETURN_CUT, _elapsed)
		at = WIDE_POSITION.bezier_interpolate(Vector3(10.5, 15.7, 26.5), Vector3(4.4, 6.5, 15.3),
			Vector3(0.6, 2.45, 9.1), t)
		target = WIDE_TARGET.lerp(Vector3(0, 2.05, 7.6), t)
		fov = lerpf(fov, 64.0, t)
	_camera.look_at_from_position(at + EXTERIOR_ORIGIN, target + EXTERIOR_ORIGIN)
	_camera.fov = fov


func _begin_return() -> void:
	_shot = Shot.RETURN
	_outside_1923.hide()
	_outside_today.hide()
	var present := EraManager.current_era == Era.Id.PRESENT
	_past.visible = not present
	_today.visible = present
	_lia.visible = present
	_camera.environment = null
	Audio.play_room_ambience(EraManager.current_era, 0.55)
	_move_into_player()


func _move_into_player() -> void:
	var player_view := _player_camera.global_transform
	var lift := player_view.basis * Vector3(0.25, 0.56, 0.42)
	var settle := smoothstep(RETURN_CUT, END - 0.15, _elapsed)
	_camera.global_transform = Transform3D(player_view.basis, player_view.origin + lift * (1.0 - settle))
	_camera.fov = lerpf(64.0, _player_camera.fov, settle)


func _skip() -> void:
	if _elapsed < RETURN_CUT:
		_elapsed = END - 0.75
		_begin_return()
		_overlay.queue_redraw()


func _finish() -> void:
	_player_camera.make_current()
	_hud.show()
	ActionCharacterInput.pending_mouse = Vector2.ZERO
	if _owns_pause:
		get_tree().paused = false
		_owns_pause = false
	queue_free()


func _exit_tree() -> void:
	if _owns_pause:
		get_tree().paused = false


func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 60
	add_child(layer)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_titles)
	layer.add_child(_overlay)
	var shade := Gradient.new()
	shade.set_color(0, Color("#06070c00"))
	shade.set_color(1, Color("#06070cbd"))
	_title_shade.gradient = shade
	_title_shade.fill_to = Vector2(0, 1)
	_title_shade.width = 2
	_title_shade.height = 256

	_skip_button.text = "Pular abertura" if GamePlatform.is_touch() else "Pular abertura  ·  %s" % Settings.binding_label("pause").replace("Escape", "Esc")
	_skip_button.focus_mode = Control.FOCUS_NONE
	_skip_button.add_theme_font_override("font", FONT)
	_skip_button.add_theme_font_size_override("font_size", 12)
	_skip_button.add_theme_color_override("font_color", INK)
	var plate := StyleBoxFlat.new()
	plate.bg_color = Color("#141519e8")
	plate.border_color = Color("#c3a16b80")
	plate.set_border_width_all(1)
	plate.set_corner_radius_all(3)
	plate.set_content_margin(SIDE_LEFT, 11.0)
	plate.set_content_margin(SIDE_RIGHT, 11.0)
	plate.set_content_margin(SIDE_TOP, 5.0)
	plate.set_content_margin(SIDE_BOTTOM, 5.0)
	var hover := plate.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#3b3025")
	_skip_button.add_theme_stylebox_override("normal", plate)
	_skip_button.add_theme_stylebox_override("hover", hover)
	_skip_button.add_theme_stylebox_override("pressed", hover)
	_skip_button.pressed.connect(_skip)
	_overlay.add_child(_skip_button)
	_overlay.resized.connect(_position_skip)
	_position_skip()


func _position_skip() -> void:
	_skip_button.size = _skip_button.get_combined_minimum_size()
	_skip_button.position = _overlay.size - _skip_button.size - Vector2(12, 7)


func _draw_titles() -> void:
	var size := _overlay.size
	if size.x < 1.0 or size.y < 1.0:
		return
	var unit := minf(size.x / 640.0, size.y / 360.0)
	var frame := 21.0 * unit
	var bars := Color("#08090c")
	_overlay.draw_rect(Rect2(0, 0, size.x, frame), bars)
	_overlay.draw_rect(Rect2(0, size.y - frame, size.x, frame), bars)
	if _elapsed >= 6.65 and _elapsed < 14.4:
		var present := _elapsed >= ERA_CUT
		var age := _elapsed - (ERA_CUT if present else 6.65)
		var alpha := smoothstep(0.0, 0.42, age) * (1.0 - smoothstep(13.85, 14.4, _elapsed))
		var label := "Hoje" if present else "1923"
		var accent := SILVER if present else GOLD
		var baseline := size.y - frame - 18.0 * unit
		var from := Vector2(24.0 * unit, baseline - 7.0 * unit)
		_overlay.draw_line(from, from + Vector2(21.0 * unit, 0), Color(accent, alpha), 1.0, true)
		_draw_line(SIGN, label, Vector2(53.0 * unit, baseline), int(23.0 * unit), Color(INK, alpha))
	if _elapsed >= 13.9 and _elapsed < 19.1:
		var alpha := smoothstep(13.9, 14.65, _elapsed) * (1.0 - smoothstep(18.25, 19.1, _elapsed))
		var y := size.y * 0.78
		_overlay.draw_texture_rect(_title_shade, Rect2(0, size.y * 0.56, size.x, size.y * 0.44 - frame),
			false, Color(1, 1, 1, alpha))
		_draw_centered(SIGN, "HOTEL SEM SAÍDA", y, int(37.0 * unit), Color(INK, alpha))
		_draw_centered(FONT, "O que Helena muda em 1923, Lia encontra hoje.",
			y + 23.0 * unit, int(13.0 * unit), Color(SILVER, alpha))

	var fade := 1.0 - smoothstep(0.0, 0.5, _elapsed)
	if _elapsed >= WINDOW_CUT - 0.25 and _elapsed < WINDOW_CUT + 0.42:
		fade = smoothstep(WINDOW_CUT - 0.25, WINDOW_CUT, _elapsed) 			* (1.0 - smoothstep(WINDOW_CUT, WINDOW_CUT + 0.42, _elapsed))
	elif _elapsed >= RETURN_CUT - 0.48:
		fade = smoothstep(RETURN_CUT - 0.48, RETURN_CUT, _elapsed) 			* (1.0 - smoothstep(RETURN_CUT, RETURN_CUT + 0.65, _elapsed))
	_overlay.draw_rect(Rect2(Vector2.ZERO, size), Color(0.023, 0.025, 0.035, fade))


func _draw_centered(font: Font, caption: String, y: float, font_size: int, color: Color) -> void:
	var width := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_draw_line(font, caption, Vector2((_overlay.size.x - width) / 2.0, y), font_size, color)


func _draw_line(font: Font, caption: String, at: Vector2, font_size: int, color: Color) -> void:
	_overlay.draw_string_outline(font, at, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4,
		Color(0.02, 0.022, 0.03, color.a * 0.85))
	_overlay.draw_string(font, at, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
