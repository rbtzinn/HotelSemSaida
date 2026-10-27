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


func _ready() -> void:
	$Body.color = body_color
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


## Usa o primeiro objeto interativo sob a personagem que aceite a interação.
func _try_interact() -> void:
	for node in get_tree().get_nodes_in_group(Interactable.GROUP):
		var interactable := node as Interactable
		if interactable.has_body(self) and interactable.can_interact(self):
			interactable.interact(self)
			return
