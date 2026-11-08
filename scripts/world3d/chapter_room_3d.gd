class_name ChapterRoom3D
extends Room3D
## Montagem das interações de salas 3D. As peças mutáveis ficam fora das malhas fixas.

func _ready() -> void:
	_fix_surfaces()
	super()


## Peças do nível (portas, objetos dos enigmas) encostadas no cenário fixo não podem piscar.
func _fix_surfaces() -> void:
	for world in get_children():
		if not world is HotelBuilder3D:
			continue
		var builder := world as HotelBuilder3D
		var boxes: Array[CoplanarFix.Box] = builder.surface_boxes.duplicate()
		boxes.append_array(CoplanarFix.collect(builder, builder, true,
			func(node: Node) -> bool: return node.name != "Merged" and not node.has_meta("generated")))
		CoplanarFix.resolve(boxes, builder)
func make_world(scene_script: Script, present: bool) -> Node3D:
	var world: Node3D = scene_script.new()
	world.name = "WorldToday" if present else "World1923"
	world.set("present", present)
	var visibility := EraVisibility.new()
	visibility.era = Era.Id.PRESENT if present else Era.Id.PAST_1923
	world.add_child(visibility)
	add_child(world)
	return world

func area(scene_script: Script, parent: Node3D, node_name: String, at: Vector3, size: Vector3, properties: Dictionary = {}) -> Area3D:
	var result: Area3D = scene_script.new()
	result.name = node_name
	result.position = at
	for key: String in properties:
		result.set(key, properties[key])
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	result.add_child(collision)
	parent.add_child(result)
	return result

func box(parent: Node3D, at: Vector3, size: Vector3, role: String, present: bool) -> MeshInstance3D:
	var result := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	result.mesh = mesh
	result.position = at
	result.material_override = HotelMaterials.get_material(role, present)
	parent.add_child(result)
	return result

func label(parent: Node3D, value: String, at: Vector3, size: int = 30) -> Label3D:
	var result := Label3D.new()
	result.font = preload("res://art/fonts/sign_font.tres")
	result.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	result.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	result.text = value
	result.position = at
	result.font_size = size
	result.pixel_size = 0.002
	result.modulate = Color("#D4BD87")
	result.outline_size = 0
	result.shaded = true
	parent.add_child(result)
	return result

func marker(node_name: String, at: Vector3, yaw: float = 0) -> void:
	var result := Marker3D.new()
	result.name = node_name
	result.position = at
	result.rotation.y = yaw
	add_child(result)

func key_visual(parent: Node3D, at: Vector3, present: bool) -> Node3D:
	var holder := Node3D.new()
	holder.position = at
	parent.add_child(holder)
	box(holder, Vector3.ZERO, Vector3(0.18, 0.02, 0.025), "brass", present)
	var bow := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.023
	ring.outer_radius = 0.038
	ring.rings = 16
	ring.ring_segments = 8
	bow.mesh = ring
	bow.position.x = -0.112
	bow.material_override = HotelMaterials.get_material("brass", present)
	holder.add_child(bow)
	box(holder, Vector3(0.07, 0, 0.025), Vector3(0.025, 0.025, 0.04), "brass", present)
	for part: MeshInstance3D in holder.get_children():
		part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return holder
