class_name PlayerMotor
extends CharacterBody2D
## Movimento da personagem, nos dois modos de sala:
## lateral (com gravidade e pulo) ou vista de cima (oito direções, sem gravidade).
## Nunca lê o teclado direto: obedece ao CharacterInput recebido em `input`.

## Época a que a personagem pertence (Helena: 1923, Lia: hoje).
@export var era: Era.Id = Era.Id.PAST_1923
@export var body_color: Color = Color.WHITE
@export var move_speed: float = 90.0
@export var acceleration: float = 900.0
## Velocidade inicial do pulo (negativa = para cima). -280 dá cerca de 40 px de altura.
@export var jump_velocity: float = -280.0
## Tamanho da colisão no modo de cima: só os pés, para passar atrás dos móveis.
@export var top_down_feet_size: Vector2 = Vector2(20, 10)

var input: CharacterInput = CharacterInput.new()

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
var _held_item_rect: ColorRect


func _ready() -> void:
	$Body.color = body_color
	_held_item_rect = ColorRect.new()
	_held_item_rect.size = Vector2(8, 8)
	_held_item_rect.position = Vector2(8, -28)
	_held_item_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_held_item_rect)
	WorldState.flag_changed.connect(_on_flag_changed)
	_refresh_held_item()
	_side_shape = $CollisionShape2D.shape
	_side_shape_position = $CollisionShape2D.position
	_top_down_shape = RectangleShape2D.new()
	_top_down_shape.size = top_down_feet_size
	_apply_mode()


func _physics_process(delta: float) -> void:
	if mode == Room.CameraMode.TOP_DOWN:
		_move_top_down(delta)
	else:
		_move_side(delta)

	if input.is_interact_just_pressed():
		_try_interact()


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
	_held_item_rect.visible = item != ""
	_held_item_rect.color = Items.color(item)


## Usa o primeiro objeto interativo sob a personagem que aceite a interação.
func _try_interact() -> void:
	for node in get_tree().get_nodes_in_group(Interactable.GROUP):
		var interactable := node as Interactable
		if interactable.has_body(self) and interactable.can_interact(self):
			interactable.interact(self)
			return
