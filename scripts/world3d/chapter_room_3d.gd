class_name ChapterRoom3D
extends Room3D
## Montagem das interações de salas 3D. As peças mutáveis ficam fora das malhas fixas.
func make_world(scene_script: Script, present: bool) -> Node3D:
	var world: Node3D = scene_script.new()
	world.name = "WorldToday" if present else "World1923"
	world.set("present",present)
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
		result.set(key,properties[key])
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
	result.material_override = HotelMaterials.get_material(role,present)
	parent.add_child(result)
	return result

func label(parent: Node3D, value: String, at: Vector3, size: int = 30) -> Label3D:
	var result := Label3D.new()
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
	box(holder,Vector3.ZERO,Vector3(0.18,0.02,0.025),"brass",present)
	box(holder,Vector3(-0.11,0,0),Vector3(0.07,0.025,0.07),"brass",present)
	box(holder,Vector3(0.07,0,0.025),Vector3(0.025,0.025,0.04),"brass",present)
	return holder
