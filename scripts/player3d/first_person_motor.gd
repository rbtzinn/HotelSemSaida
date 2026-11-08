class_name FirstPersonMotor
extends CharacterBody3D
## Personagem em primeira pessoa. Pede comandos a um CharacterInput (como o PlayerMotor 2D),
## então o mesmo roteador solo serve aqui e cada uma pode ter o próprio jogador no co-op.
## A câmera fica nos olhos; quando a época desta personagem fica ativa, ela vira a câmera atual.
## Mira com um raio: o Interactable3D no centro da tela recebe o E. Zonas de proximidade
## (ex.: o piso da despensa para deixar o gelo) valem quando nada está na mira.

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
## Velocidade nos percursos guiados (descer pelos cabos), em m/s.
@export var traversal_speed: float = 1.4

const BODY_RADIUS: float = 0.3
const BODY_HEIGHT: float = 1.7
## Camada das personagens (como no 2D) e dos Interactable3D (camada 4).
const CHARACTER_LAYER: int = 1 << 1
const INTERACT_LAYER: int = 1 << 3

## Distância entre passos (m) e quanto já se andou desde o último.
const STEP_LENGTH: float = 0.7
var _step_distance: float = 0.0
var input: CharacterInput = CharacterInput.new()
## Objeto na mira que aceita interação agora (null se nenhum).
var focused: Interactable3D = null

var _head: Node3D
var _camera: Camera3D
var _ray: RayCast3D
var _held_view: Node3D
var _traversal: PackedVector3Array = PackedVector3Array()
var _traversal_origin: Vector3
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	collision_layer = CHARACTER_LAYER
	collision_mask = 1
	# Gruda no chão ao descer a escada, em vez de sair voando a cada degrau
	floor_snap_length = 0.4
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
		light.light_energy = 4.0
		light.spot_range = 16.0
		light.spot_angle = 28.0
		light.shadow_enabled = true
		light.position = Vector3(0.18, -0.2, 0)
		_camera.add_child(light)

	_held_view = Node3D.new()
	_held_view.name = "HeldItem"
	_held_view.position = Vector3(0.26, -0.27, -0.5)
	_camera.add_child(_held_view)
	WorldState.flag_changed.connect(_on_flag_changed)
	_refresh_held_view()

	EraManager.era_changed.connect(_on_era_changed)
	_on_era_changed(EraManager.current_era)


func get_camera() -> Camera3D:
	return _camera


## Direção para onde ela olha, no plano do chão.
func get_forward() -> Vector3:
	var forward := -global_transform.basis.z
	forward.y = 0.0
	return forward.normalized()


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

	if is_traversing():
		_advance_traversal(delta)
		return

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
	_footsteps(delta)

	_update_focus()
	if focused and input.is_interact_just_pressed():
		focused.interact(self)


## Um passo a cada STEP_LENGTH andados no chão, só da personagem que está sendo jogada.
func _footsteps(delta: float) -> void:
	if era != EraManager.current_era or not is_on_floor():
		return
	var speed := Vector2(velocity.x, velocity.z).length()
	if speed < 0.5:
		_step_distance = STEP_LENGTH * 0.6
		return
	_step_distance += speed * delta
	if _step_distance >= STEP_LENGTH:
		_step_distance = 0.0
		Audio.play_one_of("passo", 6, -14.0, 0.08)


# --- Objeto na mão ---------------------------------------------------------------------

## Objeto na mão ("" = mãos vazias). Fica no WorldState, então entra no save.
func get_held_item() -> String:
	return str(WorldState.get_flag(_hand_key(), ""))


func set_held_item(item_id: String) -> void:
	WorldState.set_flag(_hand_key(), item_id)


func _hand_key() -> String:
	return "%s.mao" % Era.character_name(era).to_lower()


func _on_flag_changed(key: String, _value: Variant) -> void:
	if key == _hand_key():
		_refresh_held_view()


## O objeto aparece na mão, no canto de baixo da tela.
func _refresh_held_view() -> void:
	for child in _held_view.get_children():
		child.queue_free()
	var item := get_held_item()
	if item == "":
		return
	var instance := MeshInstance3D.new()
	var material := StandardMaterial3D.new()
	material.albedo_color = Items.color(item)
	match item:
		"pinhao_f2", "coroa_f2":
			instance.mesh = preload("res://scripts/puzzles/caldeiras/gear_model_3d.gd").mesh_for(item)
			instance.scale = Vector3.ONE * 0.42
			instance.rotation_degrees = Vector3(12, -22, 9)
			material.metallic = 0.55
		"chave_biblioteca", "chave_quadro":
			var key_mesh := BoxMesh.new()
			key_mesh.size = Vector3(0.16, 0.02, 0.025)
			instance.mesh = key_mesh
			material.metallic = 0.8
			var ring := MeshInstance3D.new()
			var ring_mesh := TorusMesh.new()
			ring_mesh.inner_radius = 0.02
			ring_mesh.outer_radius = 0.03
			ring.mesh = ring_mesh
			ring.position.x = -0.1
			ring.material_override = material
			ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			instance.add_child(ring)
			var tooth := MeshInstance3D.new()
			var tooth_mesh := BoxMesh.new()
			tooth_mesh.size = Vector3(0.025, 0.02, 0.055)
			tooth.mesh = tooth_mesh
			tooth.position = Vector3(0.06, 0, 0.02)
			tooth.material_override = material
			tooth.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			instance.add_child(tooth)
		"atlas", "livro_botanica", "livro_cronicas", "livro_diarios":
			var book_mesh := BoxMesh.new()
			book_mesh.size = Vector3(0.2, 0.045, 0.28)
			instance.mesh = book_mesh
			material.roughness = 0.7
			var pages := MeshInstance3D.new()
			var pages_mesh := BoxMesh.new()
			pages_mesh.size = Vector3(0.19, 0.027, 0.265)
			pages.mesh = pages_mesh
			pages.position.x = 0.008
			var paper := StandardMaterial3D.new()
			paper.albedo_color = Color("#E8DCC0")
			pages.material_override = paper
			instance.add_child(pages)
		"gelo":
			var box := BoxMesh.new()
			box.size = Vector3(0.2, 0.16, 0.18)
			instance.mesh = box
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.albedo_color = Color(0.78, 0.9, 0.97, 0.75)
			material.roughness = 0.08
			instance.rotation_degrees = Vector3(8, 25, 4)
		"fermento":
			var jar := CylinderMesh.new()
			jar.top_radius = 0.05
			jar.bottom_radius = 0.055
			jar.height = 0.12
			instance.mesh = jar
			material.roughness = 0.4
			var lid := MeshInstance3D.new()
			var lid_mesh := CylinderMesh.new()
			lid_mesh.top_radius = 0.058
			lid_mesh.bottom_radius = 0.058
			lid_mesh.height = 0.025
			lid.mesh = lid_mesh
			lid.position.y = 0.07
			var lid_material := StandardMaterial3D.new()
			lid_material.albedo_color = Color("#8A5A2A")
			lid.material_override = lid_material
			instance.add_child(lid)
		_:
			var other := BoxMesh.new()
			other.size = Vector3(0.1, 0.1, 0.1)
			instance.mesh = other
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_held_view.add_child(instance)


# --- Percursos guiados (descer pelos cabos) ---------------------------------------------

## Leva a personagem por uma sequência de pontos, sem física e sem comandos.
## Trocar de época ou pausar congela o percurso junto com a personagem.
func begin_traversal(points: PackedVector3Array) -> void:
	if is_traversing() or points.is_empty():
		return
	_traversal_origin = global_position
	_traversal = points.duplicate()
	velocity = Vector3.ZERO
	_set_focus(null)


func is_traversing() -> bool:
	return not _traversal.is_empty()


## Um save no meio dos cabos volta ao ponto de partida, nunca ao meio do poço.
func get_save_position() -> Vector3:
	return _traversal_origin if is_traversing() else global_position


func _advance_traversal(delta: float) -> void:
	var destination: Vector3 = _traversal[0]
	global_position = global_position.move_toward(destination, traversal_speed * delta)
	if global_position.is_equal_approx(destination):
		_traversal.remove_at(0)
		velocity = Vector3.ZERO


# --- Mira e interação --------------------------------------------------------------------

func _update_focus() -> void:
	_ray.force_raycast_update()
	var hit := _ray.get_collider()
	var target: Interactable3D = hit if hit is Interactable3D else null
	if target and not target.can_interact(self):
		target = null
	if target == null:
		# Nada na mira: vale uma zona de proximidade onde ela esteja
		for zone in get_tree().get_nodes_in_group(Interactable3D.PROXIMITY_GROUP):
			var candidate := zone as Interactable3D
			if candidate.contains(self) and candidate.can_interact(self):
				target = candidate
				break
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
