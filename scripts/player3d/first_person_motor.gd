class_name FirstPersonMotor
extends CharacterBody3D
## Personagem em primeira pessoa. Pede comandos a um CharacterInput (como o PlayerMotor 2D),
## então o mesmo roteador solo serve aqui e cada uma pode ter o próprio jogador no co-op.
## A câmera fica nos olhos; quando a época desta personagem fica ativa, ela vira a câmera atual.
## Mira com um raio: o Interactable3D no centro da tela recebe o E.

@export var era: Era.Id = Era.Id.PAST_1923
@export var move_speed: float = 3.2
@export var acceleration: float = 18.0
@export var jump_velocity: float = 4.2
## Radianos por pixel de mouse.
@export var look_sensitivity: float = 0.0025
@export var eye_height: float = 1.6
## Alcance da mão, em metros.
@export var reach: float = 2.4
## Lanterna presa à câmera (a Lia, hoje).
@export var flashlight: bool = false

const BODY_RADIUS: float = 0.3
const BODY_HEIGHT: float = 1.7
## Camada de colisão dos Interactable3D (camada 4).
const INTERACT_LAYER: int = 1 << 3

var input: CharacterInput = CharacterInput.new()
## Objeto na mira que aceita interação agora (null se nenhum).
var focused: Interactable3D = null

var _head: Node3D
var _camera: Camera3D
var _ray: RayCast3D
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	var shape := CapsuleShape3D.new()
	shape.radius = BODY_RADIUS
	shape.height = BODY_HEIGHT
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = BODY_HEIGHT / 2.0
	add_child(collision)

	_head = Node3D.new()
	_head.name = "Head"
	_head.position.y = eye_height
	add_child(_head)
	_camera = Camera3D.new()
	_camera.name = "Camera3D"
	_camera.fov = 70.0
	_camera.near = 0.05
	_head.add_child(_camera)

	_ray = RayCast3D.new()
	_ray.target_position = Vector3(0, 0, -reach)
	_ray.collision_mask = INTERACT_LAYER | 1
	_ray.collide_with_areas = true
	_ray.add_exception(self)
	_camera.add_child(_ray)

	if flashlight:
		var light := SpotLight3D.new()
		light.name = "Lanterna"
		light.light_color = Color("#E8E2D0")
		light.light_energy = 2.5
		light.spot_range = 14.0
		light.spot_angle = 24.0
		light.shadow_enabled = true
		light.position = Vector3(0.18, -0.2, 0)
		_camera.add_child(light)

	EraManager.era_changed.connect(_on_era_changed)
	_on_era_changed(EraManager.current_era)


func get_camera() -> Camera3D:
	return _camera


func _on_era_changed(active_era: Era.Id) -> void:
	if active_era == era:
		_camera.make_current()
		_push_prompt()
	else:
		focused = null


func _physics_process(delta: float) -> void:
	var look := input.get_look()
	rotate_y(-look.x * look_sensitivity)
	_head.rotation.x = clampf(_head.rotation.x - look.y * look_sensitivity, deg_to_rad(-85.0), deg_to_rad(85.0))

	var move := input.get_move()
	var direction := (transform.basis * Vector3(move.x, 0, move.y)).normalized() * minf(move.length(), 1.0)
	var target := direction * move_speed
	velocity.x = move_toward(velocity.x, target.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target.z, acceleration * delta)
	if is_on_floor():
		if input.is_jump_just_pressed():
			velocity.y = jump_velocity
	else:
		velocity.y -= _gravity * delta
	move_and_slide()

	_update_focus()
	if focused and input.is_interact_just_pressed():
		focused.interact(self)


func _update_focus() -> void:
	_ray.force_raycast_update()
	var hit := _ray.get_collider()
	var target: Interactable3D = hit if hit is Interactable3D else null
	if target and not target.can_interact(self):
		target = null
	_set_focus(target)


func _set_focus(target: Interactable3D) -> void:
	if target == focused:
		return
	focused = target
	if EraManager.current_era == era:
		_push_prompt()


## O HUD é um só: quem está ativa manda o aviso do que tem na mira (ou nada).
func _push_prompt() -> void:
	if is_inside_tree():
		get_tree().call_group("hud", "show_prompt", focused.get_prompt() if focused else "")
