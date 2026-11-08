class_name CoplanarFix
extends RefCounted
## Tira o "piscar" de superfícies sobrepostas (z-fighting). Duas caixas de materiais diferentes
## com faces no mesmo plano, viradas para o mesmo lado e se sobrepondo, brigam pelo mesmo pixel
## e piscam quando a câmera se move. Para cada par assim, a caixa menor fica por cima: a face
## dela anda 2 mm para fora. Se a menor não puder mudar (já está na malha fixa da sala), a outra
## recua 2 mm.
## Só caixas sem rotação (ou com rotação de 90° em y) entram; as giradas quase nunca coincidem.

const EPSILON: float = 0.0015
const NUDGE: float = 0.002

## Quantos pares a última chamada corrigiu (para os testes e o relatório).
static var last_fixed: int = 0
static var total_fixed: int = 0
static var total_msec: int = 0


## Uma caixa do cenário: onde está (no espaço de `space`), o material e se pode mudar.
class Box:
	var node: MeshInstance3D
	var box: AABB
	var material: int
	var movable: bool


static func collect(root: Node, space: Node3D, movable: bool, filter: Callable = Callable()) -> Array[Box]:
	var result: Array[Box] = []
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var instance := node as MeshInstance3D
		if not instance.mesh is BoxMesh or instance.material_override == null:
			continue
		if filter.is_valid() and not filter.call(instance):
			continue
		var local := _relative(instance, space)
		if not _axis_aligned(local.basis):
			continue
		var entry := Box.new()
		entry.node = instance
		entry.box = local * AABB(-(instance.mesh as BoxMesh).size / 2.0, (instance.mesh as BoxMesh).size)
		entry.material = instance.material_override.get_instance_id()
		entry.movable = movable
		result.append(entry)
	return result


## Corrige os pares coplanares entre `boxes` (que podem misturar fixas e móveis).
static func resolve(boxes: Array[Box], space: Node3D) -> int:
	var started := Time.get_ticks_usec()
	var fixed := 0
	# Empurrar uma face pode encostá-la em outra a 2 mm; outra passada resolve o novo par
	for attempt in 4:
		var found := _resolve_pass(boxes, space)
		fixed += found
		if found == 0:
			break
	last_fixed = fixed
	total_fixed += fixed
	total_msec += (Time.get_ticks_usec() - started) / 1000
	return fixed


static func _resolve_pass(boxes: Array[Box], space: Node3D) -> int:
	var fixed := 0
	for axis in 3:
		for side: int in [-1, 1]:
			var planes := {}
			for entry in boxes:
				var key := roundi(_face(entry.box, axis, side) / EPSILON)
				if not planes.has(key):
					planes[key] = []
				(planes[key] as Array).append(entry)
			for key: int in planes:
				var group: Array = planes[key]
				if planes.has(key + 1):
					group = group + (planes[key + 1] as Array)
				if group.size() > 1:
					fixed += _resolve_group(group, axis, side, space)
	return fixed


static func _resolve_group(group: Array, axis: int, side: int, space: Node3D) -> int:
	# Varredura por um dos eixos do plano: só compara caixas que se cruzam nele (prateleiras com
	# centenas de lombadas no mesmo plano ficavam lentas comparando todas com todas)
	var sweep := (axis + 1) % 3
	group.sort_custom(func(a: Box, b: Box) -> bool: return a.box.position[sweep] < b.box.position[sweep])
	var fixed := 0
	for i in group.size():
		var a: Box = group[i]
		for j in range(i + 1, group.size()):
			var b: Box = group[j]
			if b.box.position[sweep] >= a.box.end[sweep]:
				break
			if a == b or a.material == b.material or not (a.movable or b.movable):
				continue
			var face_a := _face(a.box, axis, side)
			var face_b := _face(b.box, axis, side)
			if absf(face_a - face_b) > EPSILON or not _overlap(a.box, b.box, axis):
				continue
			var small := a if _area(a.box, axis) <= _area(b.box, axis) else b
			var big := b if small == a else a
			if small.movable:
				_push(small, axis, side, NUDGE, space)
			else:
				_push(big, axis, side, -NUDGE, space)
			fixed += 1
	return fixed


static func _face(box: AABB, axis: int, side: int) -> float:
	return box.position[axis] + (box.size[axis] if side > 0 else 0.0)


static func _area(box: AABB, axis: int) -> float:
	var size := box.size
	size[axis] = 1.0
	return size.x * size.y * size.z


## As faces se sobrepõem nos dois eixos do plano (com folga, para não pegar só a quina).
static func _overlap(a: AABB, b: AABB, axis: int) -> bool:
	for other in 3:
		if other == axis:
			continue
		var low := maxf(a.position[other], b.position[other])
		var high := minf(a.end[other], b.end[other])
		if high - low <= 0.001:
			return false
	return true


## Move a face `side` da caixa `amount` metros para fora (negativo: para dentro).
static func _push(entry: Box, axis: int, side: int, amount: float, space: Node3D) -> void:
	var mesh := (entry.node.mesh as BoxMesh).duplicate() as BoxMesh
	var direction := Vector3.ZERO
	direction[axis] = 1.0
	var local := (space.global_basis * direction) * entry.node.global_basis
	var local_axis := 0
	for i in 3:
		if absf(local[i]) > absf(local[local_axis]):
			local_axis = i
	var size := mesh.size
	size[local_axis] = maxf(size[local_axis] + amount, 0.0005)
	mesh.size = size
	entry.node.mesh = mesh
	var shift := Vector3.ZERO
	shift[axis] = side * amount / 2.0
	entry.node.global_position += space.global_basis * shift
	# Atualiza a caixa para os próximos pares
	if side > 0:
		entry.box.size[axis] += amount
	else:
		entry.box.position[axis] -= amount
		entry.box.size[axis] += amount


static func _relative(node: Node3D, space: Node3D) -> Transform3D:
	var result := node.transform
	var parent := node.get_parent()
	while parent and parent != space:
		if parent is Node3D:
			result = (parent as Node3D).transform * result
		parent = parent.get_parent()
	return result


static func _axis_aligned(basis: Basis) -> bool:
	for column in 3:
		var v := basis[column].normalized()
		var hits := 0
		for i in 3:
			if absf(absf(v[i]) - 1.0) < 0.001:
				hits += 1
		if hits != 1:
			return false
	return true
