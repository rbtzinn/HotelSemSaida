class_name PlayerMotor
extends CharacterBody2D
## Movimento da personagem, nos dois modos de sala:
## lateral (com gravidade e pulo) ou vista de cima (oito direções, sem gravidade).
## Nunca lê o teclado direto: obedece ao CharacterInput recebido em `input`.

## Época a que a personagem pertence (Helena: 1923, Lia: hoje).
@export var era: Era.Id = Era.Id.PAST_1923
@export var body_color: Color = Color.WHITE
## Tira de 5 quadros de 24x48 (parada + 4 de caminhada), virada para a direita.
## Sem ela, a personagem aparece como um bloco na cor `body_color`.
@export var sprite_sheet: Texture2D
## Arte desenhada: quadros independentes em alta resolução, com duração própria.
## Animações "idle" e "walk"; preserva a geometria de 24x48 do jogo.
@export var drawn_animations: SpriteFrames
## Poses de carregar/usar objetos, com o item desenhado nas mãos.
@export var item_animations: SpriteFrames
@export var walk_fps: float = 8.0
@export var move_speed: float = 90.0
@export var acceleration: float = 900.0
## Velocidade inicial do pulo (negativa = para cima). -280 dá cerca de 40 px de altura.
@export var jump_velocity: float = -280.0
## Tamanho da colisão no modo de cima: só os pés, para passar atrás dos móveis.
@export var top_down_feet_size: Vector2 = Vector2(20, 10)

var input: CharacterInput = CharacterInput.new()
## Objeto que o E vai usar agora. Só ele mostra o prompt, mesmo com outros por perto.
var focused: Interactable = null

## Definido pela Room da cena.
var mode: Room.CameraMode = Room.CameraMode.SIDE_SCROLLER:
	set(value):
		mode = value
		if is_node_ready():
			_apply_mode()

var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _side_shape: Shape2D
var _side_shape_position: Vector2
var _top_down_shape: RectangleShape2D
var _held_item_sprite: Sprite2D
var _item_rendered := false
var _item_name: StringName = &""
var _item_clock: float = 0.0
var _item_action: StringName = &""
var _item_complete: Callable
var _walk_time: float = 0.0
var _drawn_time: float = 0.0
var _drawn_name: StringName = &""
var _traversal: PackedVector2Array = PackedVector2Array()
var _traversal_origin: Vector2
var _cable_stage: StringName = &""
var _cable_time: float = 0.0
var _cable_x: float = 0.0
var _cable_start_y: float = 0.0
var _cable_exit_start: Vector2

@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	$Body.color = body_color
	if sprite_sheet:
		_sprite.texture = sprite_sheet
		_sprite.visible = true
		$Body.visible = false
	if drawn_animations:
		_sprite.hframes = 1
		_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_sprite.visible = true
		$Body.visible = false
	_held_item_sprite = Sprite2D.new()
	_held_item_sprite.position = Vector2(9, -27)
	add_child(_held_item_sprite)
	WorldState.flag_changed.connect(_on_flag_changed)
	_refresh_held_item()
	_side_shape = $CollisionShape2D.shape
	_side_shape_position = $CollisionShape2D.position
	_top_down_shape = RectangleShape2D.new()
	_top_down_shape.size = top_down_feet_size
	_apply_mode()


func _physics_process(delta: float) -> void:
	if is_traversing():
		_advance_traversal(delta)
		return
	if is_using_item():
		velocity = Vector2.ZERO
		_animate(delta)
		if _item_clock >= _item_duration(_item_action):
			var complete := _item_complete
			_item_action = &""
			_item_complete = Callable()
			if complete.is_valid():
				complete.call()
			_refresh_held_item()
			_animate(0.0)
		return
	if mode == Room.CameraMode.TOP_DOWN:
		_move_top_down(delta)
	else:
		_move_side(delta)
	_animate(delta)
	_update_focus()

	if input.is_interact_just_pressed():
		_try_interact()


## Quadro 0 parada; quadros 1 a 4 em ciclo ao andar. Vira para o lado do movimento.
func _animate(delta: float) -> void:
	if not _sprite.visible:
		return
	if velocity.x < -1.0:
		_sprite.flip_h = true
	elif velocity.x > 1.0:
		_sprite.flip_h = false
	_held_item_sprite.position.x = -9.0 if _sprite.flip_h else 9.0

	var walking := velocity.length() > 5.0 if mode == Room.CameraMode.TOP_DOWN else absf(velocity.x) > 5.0
	if _animate_item(delta, walking):
		return
	_held_item_sprite.position.y = -27.0 + (sin(_walk_time * 8.0) if walking else 0.0)
	if drawn_animations:
		_animate_drawn(delta, walking)
		return
	if walking and (is_traversing() or mode == Room.CameraMode.TOP_DOWN or is_on_floor()):
		_walk_time += delta
		_sprite.frame = 1 + int(_walk_time * walk_fps) % 4
	else:
		_walk_time = 0.0
		_sprite.frame = 0


## Percurso guiado: pausa junto da personagem ao trocar de época ou abrir o menu.
func begin_traversal(points: PackedVector2Array) -> void:
	if is_traversing() or points.is_empty():
		return
	_traversal_origin = position
	_traversal = points.duplicate()
	velocity = Vector2.ZERO
	var previous := focused
	focused = null
	if previous:
		previous.refresh_prompt()


func is_traversing() -> bool:
	return not _traversal.is_empty()


func get_save_position() -> Vector2:
	# Um save durante a escada retorna ao patamar, nunca ao meio do vão.
	return _traversal_origin if is_traversing() else position


func _advance_traversal(delta: float) -> void:
	if _cable_stage != &"":
		_advance_cable(delta)
		return
	var destination: Vector2 = _traversal[0]
	var before := global_position
	global_position = global_position.move_toward(destination, 100.0 * delta)
	velocity = (global_position - before) / maxf(delta, 0.001)
	_animate(delta)
	if global_position.is_equal_approx(destination):
		_traversal.remove_at(0)
		if not is_traversing():
			velocity = Vector2.ZERO
			_sprite.frame = 0


func _animate_drawn(delta: float, walking: bool, override: StringName = &"", loop: bool = true) -> void:
	var animation: StringName = override if override != &"" else (&"walk" if walking else &"idle")
	if not drawn_animations.has_animation(animation):
		return
	var count := drawn_animations.get_frame_count(animation)
	if count == 0:
		return
	if _drawn_name != animation:
		_drawn_name = animation
		_drawn_time = 0.0
	_drawn_time += delta
	var speed := maxf(1.0, drawn_animations.get_animation_speed(animation))
	var total := 0.0
	for i in count:
		total += drawn_animations.get_frame_duration(animation, i) / speed
	var time := fmod(_drawn_time, total) if loop else minf(_drawn_time, total - 0.00001)
	var index := 0
	for i in count:
		index = i
		time -= drawn_animations.get_frame_duration(animation, i) / speed
		if time < 0:
			break
	var texture := drawn_animations.get_frame_texture(animation, index)
	if texture:
		_sprite.texture = texture
		_sprite.frame = 0
		var cable_frame := String(animation).begins_with("cable_")
		var baseline := 352.0 if cable_frame else float(texture.get_height())
		_sprite.offset = Vector2(-texture.get_width() / 2.0, -baseline)
		_sprite.scale = Vector2.ONE * (48.0 / (288.0 if cable_frame else texture.get_height()))


func begin_cable_descent(destination: Vector2, cable_x: float) -> void:
	if is_traversing() or drawn_animations == null:
		return
	for animation in [&"cable_enter", &"cable_descend", &"cable_exit"]:
		if not drawn_animations.has_animation(animation):
			return
	begin_traversal(PackedVector2Array([destination]))
	_cable_x = cable_x
	_cable_start_y = global_position.y
	_cable_time = 0.0
	_cable_stage = &"approach"


func _advance_cable(delta: float) -> void:
	var destination: Vector2 = _traversal[0]
	_cable_time += delta
	_sprite.flip_h = false
	match _cable_stage:
		&"approach":
			var entry := Vector2(_cable_x, _cable_start_y)
			var before := global_position
			global_position = global_position.move_toward(entry, 65.0 * delta)
			velocity = (global_position - before) / maxf(delta, 0.001)
			_animate(delta)
			if global_position.is_equal_approx(entry):
				_cable_stage = &"enter"
				_cable_time = 0.0
		&"enter":
			velocity = Vector2.ZERO
			_animate_drawn(delta, false, &"cable_enter", false)
			if _cable_time >= 0.5:
				_cable_stage = &"descend"
				_cable_time = 0.0
		&"descend":
			# Velocidade moderada: cada troca de pegada fica legível em jogo.
			global_position.y = minf(global_position.y + 44.0 * delta, destination.y - 4.0)
			velocity = Vector2(0,44)
			_animate_drawn(delta, false, &"cable_descend")
			if global_position.y >= destination.y - 4.0:
				_cable_stage = &"exit"
				_cable_time = 0.0
				_cable_exit_start = global_position
		&"exit":
			velocity = Vector2.ZERO
			var progress := clampf(_cable_time / 0.5, 0.0, 1.0)
			global_position = _cable_exit_start.lerp(destination, smoothstep(0.0,1.0,progress))
			_animate_drawn(delta, false, &"cable_exit", false)
			if progress >= 1.0:
				_cable_stage = &""
				_traversal.clear()
				_drawn_name = &""
				_animate_drawn(0.0, false)


func _move_side(delta: float) -> void:
	if not is_on_floor():
		velocity.y += _gravity * delta
	elif input.is_jump_just_pressed():
		velocity.y = jump_velocity

	var target_speed := input.get_move().x * move_speed
	velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)
	move_and_slide()


func _move_top_down(delta: float) -> void:
	var target := input.get_move() * move_speed
	velocity = velocity.move_toward(target, acceleration * delta)
	move_and_slide()


func _apply_mode() -> void:
	var collision: CollisionShape2D = $CollisionShape2D
	if mode == Room.CameraMode.TOP_DOWN:
		motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
		collision.shape = _top_down_shape
		collision.position = Vector2(0, -top_down_feet_size.y / 2.0)
	else:
		motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
		collision.shape = _side_shape
		collision.position = _side_shape_position
	velocity = Vector2.ZERO


## Objeto na mão ("" = mãos vazias). Fica no WorldState, então entra no save.
func get_held_item() -> String:
	return str(WorldState.get_flag(_hand_key(), ""))


func set_held_item(item_id: String) -> void:
	WorldState.set_flag(_hand_key(), item_id)


func _hand_key() -> String:
	return "%s.mao" % Era.character_name(era).to_lower()


func _on_flag_changed(key: String, _value: Variant) -> void:
	if key == _hand_key():
		_refresh_held_item()


func _refresh_held_item() -> void:
	var item := get_held_item()
	_held_item_sprite.texture = Items.texture(item)
	var drawn := item_animations != null and item_animations.has_animation(item + "_idle")
	_held_item_sprite.visible = item != "" and not drawn and not is_using_item()
	if _held_item_sprite.texture:
		var width := 9.0 if item == "gelo" else 5.0
		_held_item_sprite.scale = Vector2.ONE * minf(width / _held_item_sprite.texture.get_width(), 8.0 / _held_item_sprite.texture.get_height())


func is_using_item() -> bool:
	return _item_action != &""


func face_toward(point: Vector2) -> void:
	if absf(point.x - global_position.x) > 1.0:
		_sprite.flip_h = point.x < global_position.x


## A consequência só acontece ao terminar o gesto, sem consumir o objeto antes.
func play_item_use(item: String, complete: Callable) -> bool:
	var animation := StringName(item + "_use")
	if is_traversing() or is_using_item() or item_animations == null or not item_animations.has_animation(animation):
		return false
	_item_action = animation
	_item_name = &""
	_item_clock = 0.0
	_item_complete = complete
	velocity = Vector2.ZERO
	var previous := focused
	focused = null
	if previous:
		previous.refresh_prompt()
	_refresh_held_item()
	return true


func _item_duration(animation: StringName) -> float:
	var duration := 0.0
	var speed := maxf(1.0,item_animations.get_animation_speed(animation))
	for index in item_animations.get_frame_count(animation):
		duration += item_animations.get_frame_duration(animation,index) / speed
	return duration


func _animate_item(delta: float, walking: bool) -> bool:
	var item := get_held_item()
	var animation := _item_action if is_using_item() else StringName(item + ("_walk" if walking else "_idle"))
	if item_animations == null or not item_animations.has_animation(animation):
		if _item_rendered:
			_sprite.texture = sprite_sheet
			_sprite.scale = Vector2.ONE
			_sprite.hframes = 1 if drawn_animations else 5
			_sprite.offset = Vector2(-12,-48)
			_sprite.frame = 0
			_item_rendered = false
			_item_name = &""
		return false
	if _item_name != animation:
		_item_name = animation
		_item_clock = 0.0
	_item_clock += delta
	var duration := _item_duration(animation)
	var time := minf(_item_clock,duration-0.00001) if is_using_item() else fmod(_item_clock,duration)
	var speed := maxf(1.0,item_animations.get_animation_speed(animation))
	var index := 0
	for frame in item_animations.get_frame_count(animation):
		index = frame
		time -= item_animations.get_frame_duration(animation,frame) / speed
		if time < 0.0:
			break
	_sprite.hframes = 1
	_sprite.frame = 0
	_sprite.texture = item_animations.get_frame_texture(animation,index)
	_sprite.offset = Vector2(-24,-52)
	_sprite.scale = Vector2.ONE
	_item_rendered = true
	_held_item_sprite.hide()
	return true


## Usa o objeto em foco: o mais próximo, sob a personagem, que aceite a interação.
func _try_interact() -> void:
	if focused:
		focused.interact(self)


## Escolhe o objeto em foco e avisa os dois (o antigo e o novo) para atualizarem o prompt.
func _update_focus() -> void:
	var center := global_position + Vector2(0, -24)
	var best: Interactable = null
	var best_distance := INF
	for node in get_tree().get_nodes_in_group(Interactable.GROUP):
		var interactable := node as Interactable
		if not (interactable.has_body(self) and interactable.can_interact(self)):
			continue
		var distance := center.distance_to(interactable.get_focus_point())
		if distance < best_distance:
			best = interactable
			best_distance = distance
	if best == focused:
		return
	var previous := focused
	focused = best
	if previous:
		previous.refresh_prompt()
	if focused:
		focused.refresh_prompt()
