@tool
class_name HotelBuilder3D
extends Node3D
## Base das salas 3D montadas por código. Separa o que se vê do que colide:
## `_part` e companhia desenham peças sem colisão; `_solid` cria a colisão invisível,
## com a mesma planta das salas 2D. As peças são recriadas a cada carregamento e não
## ficam salvas na cena. Subclasses montam a sala em `_build_room()`.

## Liga a versão em ruínas (hoje).
@export var present: bool = false:
	set(value):
		present = value
		if is_inside_tree():
			_build()

## Planta das salas 2D: 32 px = 1 m.
const PX: float = 1.0 / 32.0

## Desligado, as peças criadas não projetam sombra (ex.: o lustre, que tem a luz por dentro).
var _cast_shadows: bool = true


func _ready() -> void:
	_build()


func _build() -> void:
	for child in get_children():
		if child.has_meta("generated"):
			remove_child(child)
			child.queue_free()
	_build_room()
	_merge_static_meshes()


## Sobrescreva nas subclasses.
func _build_room() -> void:
	pass


func _material(role: String) -> Material:
	return HotelMaterials.get_material(role, present)


## Caixa entre dois cantos (metros), girada em graus em torno do próprio centro.
func _part(from: Vector3, to: Vector3, role: String, rotation_deg: Vector3 = Vector3.ZERO, material: Material = null) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = (to - from).abs()
	return _mesh(mesh, (from + to) / 2.0, role, rotation_deg, material)


## Caixa pelo centro e tamanho.
func _block(center: Vector3, size: Vector3, role: String, rotation_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _mesh(mesh, center, role, rotation_deg)


## Cilindro (ou cone, com raios diferentes) com a base em `base`.
func _cylinder(base: Vector3, bottom_radius: float, top_radius: float, height: float, role: String, rotation_deg: Vector3 = Vector3.ZERO, sides: int = 16) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = bottom_radius
	mesh.top_radius = top_radius
	mesh.height = height
	mesh.radial_segments = sides
	mesh.rings = 1
	var center := base + Basis.from_euler(rotation_deg * PI / 180.0) * Vector3(0, height / 2.0, 0)
	return _mesh(mesh, center, role, rotation_deg)


func _sphere(center: Vector3, radius: float, role: String, scale_factor: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	var instance := _mesh(mesh, center, role)
	instance.scale = scale_factor
	return instance


func _torus(center: Vector3, inner_radius: float, outer_radius: float, role: String, rotation_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner_radius
	mesh.outer_radius = outer_radius
	mesh.rings = 24
	mesh.ring_segments = 8
	return _mesh(mesh, center, role, rotation_deg)


## Prisma vertical a partir de um contorno no plano (x, z) local, entre as alturas y0 e y1.
func _extrude(points: PackedVector2Array, y0: float, y1: float, origin: Vector3, rotation_y_deg: float, role: String) -> MeshInstance3D:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var triangles := Geometry2D.triangulate_polygon(points)
	# Faces fechadas com normais explícitas e uma única orientação por face.
	for i in range(0, triangles.size(), 3):
		for cap in [0, 1]:
			tool.set_normal(Vector3.UP if cap == 1 else Vector3.DOWN)
			var order := [0, 1, 2] if cap == 1 else [2, 1, 0]
			for k: int in order:
				var point := points[triangles[i + k]]
				tool.add_vertex(Vector3(point.x, y1 if cap == 1 else y0, point.y))
	var clockwise := Geometry2D.is_polygon_clockwise(points)
	for i in points.size():
		var a := points[i]
		var b := points[(i + 1) % points.size()]
		var edge := b - a
		var outward := Vector3(edge.y, 0, -edge.x).normalized()
		tool.set_normal(-outward if clockwise else outward)
		var quad := [Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(b.x, y1, b.y), Vector3(a.x, y1, a.y)]
		var order := [0, 1, 2, 0, 2, 3] if clockwise else [0, 2, 1, 0, 3, 2]
		for k: int in order:
			tool.add_vertex(quad[k])
	# Todas as peças unidas usam índices; sem eles o append_from descartava as faces
	# deste prisma quando o material já continha caixas indexadas.
	tool.index()
	var instance := MeshInstance3D.new()
	instance.mesh = tool.commit()
	instance.position = origin
	instance.rotation_degrees.y = rotation_y_deg
	instance.material_override = _material(role)
	_add(instance)
	return instance


## Colisão invisível entre dois cantos.
func _solid(from: Vector3, to: Vector3, solid_name: String = "Solid") -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = solid_name
	body.position = (from + to) / 2.0
	var shape := BoxShape3D.new()
	shape.size = (to - from).abs()
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	_add(body)
	return body


func _solid_cylinder(base: Vector3, radius: float, height: float, solid_name: String = "Solid") -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = solid_name
	body.position = base + Vector3(0, height / 2.0, 0)
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	_add(body)
	return body


func _omni(at: Vector3, color: Color, energy: float, light_range: float, shadows: bool = false) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.position = at
	light.light_color = color
	light.light_energy = energy
	light.omni_range = light_range
	light.omni_attenuation = 1.4
	light.shadow_enabled = shadows
	_add(light)
	return light


func _spot(at: Vector3, look_target: Vector3, color: Color, energy: float, light_range: float, angle: float) -> SpotLight3D:
	var light := SpotLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.spot_range = light_range
	light.spot_angle = angle
	light.shadow_enabled = true
	light.light_volumetric_fog_energy = 3.0
	_add(light)
	light.look_at_from_position(at, look_target, Vector3.UP)
	return light


func _label(text: String, at: Vector3, size: float, color: Color, rotation_y_deg: float = 0.0) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.rotation_degrees.y = rotation_y_deg
	label.pixel_size = size / 64.0
	label.font_size = 64
	label.modulate = color
	label.outline_size = 0
	label.shaded = true
	label.double_sided = false
	_add(label)
	return label


## Nó vazio para montar uma peça composta (sofá, relógio) e girá-la inteira.
func _group(at: Vector3, yaw_deg: float) -> Node3D:
	var holder := Node3D.new()
	holder.position = at
	holder.rotation_degrees.y = yaw_deg
	_add(holder)
	return holder


func _child_box(holder: Node3D, center: Vector3, size: Vector3, role: String, rotation_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = center
	instance.rotation_degrees = rotation_deg
	instance.material_override = _material(role)
	holder.add_child(instance)
	return instance


## Cilindro filho de um grupo, centrado em `center`.
func _child_cylinder(holder: Node3D, center: Vector3, radius: float, height: float, role: String) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = center
	instance.material_override = _material(role)
	holder.add_child(instance)
	return instance


func _mesh(mesh: Mesh, center: Vector3, role: String, rotation_deg: Vector3 = Vector3.ZERO, material: Material = null) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = center
	instance.rotation_degrees = rotation_deg
	instance.material_override = material if material else _material(role)
	if not _cast_shadows:
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add(instance)
	return instance


func _add(node: Node) -> void:
	node.set_meta("generated", true)
	add_child(node)


## Junta todas as peças estáticas que dividem o mesmo material (e a mesma regra de sombra)
## numa malha só. São centenas de caixas e cilindros; desenhar cada um separado custava
## centenas de chamadas de desenho por quadro, multiplicadas pelas sombras.
func _merge_static_meshes() -> void:
	var tools := {}
	var materials := {}
	var parts: Array[MeshInstance3D] = []
	for node in find_children("*", "MeshInstance3D", true, false):
		var instance := node as MeshInstance3D
		if not _is_generated(instance) or instance.material_override == null:
			continue
		var shadows := instance.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var key := "%d:%s" % [instance.material_override.get_instance_id(), shadows]
		if not tools.has(key):
			var tool := SurfaceTool.new()
			tool.begin(Mesh.PRIMITIVE_TRIANGLES)
			tools[key] = tool
			materials[key] = [instance.material_override, shadows]
		var local := global_transform.affine_inverse() * instance.global_transform if is_inside_tree() else _local_transform(instance)
		for surface in instance.mesh.get_surface_count():
			(tools[key] as SurfaceTool).append_from(instance.mesh, surface, local)
		parts.append(instance)
	for instance in parts:
		instance.get_parent().remove_child(instance)
		instance.queue_free()
	for key: String in tools:
		var merged := MeshInstance3D.new()
		merged.name = "Merged"
		merged.mesh = (tools[key] as SurfaceTool).commit()
		merged.material_override = materials[key][0]
		if not materials[key][1]:
			merged.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_add(merged)


## Peça criada por esta sala. Para em outra sala/peça montada por código dentro dela
## (ex.: a porta ou a alavanca da Cozinha): essas se movem e somem com os enigmas,
## então não podem virar parte da malha fixa.
func _is_generated(node: Node) -> bool:
	var generated := false
	while node and node != self:
		if node is HotelBuilder3D:
			return false
		if node.has_meta("generated"):
			generated = true
		node = node.get_parent()
	return generated


## Transformação de uma peça em relação a esta sala, sem depender da árvore.
func _local_transform(node: Node3D) -> Transform3D:
	var result := node.transform
	var parent := node.get_parent()
	while parent and parent != self:
		result = (parent as Node3D).transform * result
		parent = parent.get_parent()
	return result


## Sorteio estável: a mesma sala sai sempre igual.
func _random(index: int, salt: float = 0.0) -> float:
	return fposmod(sin(float(index) * 12.9898 + salt * 78.233) * 43758.5453, 1.0)
