extends SceneTree
## Superfícies sobrepostas: duas caixas de materiais diferentes com a face no mesmo plano
## deixam de brigar (a menor fica 2 mm por cima); nas salas, nenhum par sobra depois da correção.
## Rodar: Godot_console.exe --headless --path . --fixed-fps 60 --script res://tools/test_coplanar.gd

const FIX := "res://scripts/world3d/coplanar_fix.gd"
const ROOMS := ["saguao_3d", "biblioteca_3d", "salao_3d"]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var fix: Script = load(FIX)
	var space := Node3D.new()
	root.add_child(space)
	var wall := _box(space, Vector3(0, 1.5, 0), Vector3(4, 3, 0.2), Color.RED)
	var trim := _box(space, Vector3(0, 1.0, 0.0), Vector3(3, 0.05, 0.2), Color.BLUE)
	var boxes: Array = fix.collect(space, space, true)
	assert(fix.resolve(boxes, space) == 2, "Rodapé e parede: duas faces no mesmo plano (frente e trás)")
	assert(is_equal_approx((trim.mesh as BoxMesh).size.z, 0.204), "A peça menor cresce 2 mm de cada lado")
	assert(is_equal_approx((wall.mesh as BoxMesh).size.z, 0.2), "A parede não muda")
	assert(fix.resolve(fix.collect(space, space, true), space) == 0, "Depois de corrigir, nada sobra")
	space.queue_free()

	# Nas salas, depois de carregar, não sobra par a corrigir entre as peças do nível e o cenário
	for room: String in ROOMS:
		change_scene_to_file("res://scenes/rooms/%s.tscn" % room)
		await scene_changed
		for i in 3:
			await process_frame
		for world_name in ["World1923", "WorldToday"]:
			var builder = current_scene.get_node(world_name)
			var all: Array = builder.surface_boxes.duplicate()
			all.append_array(fix.collect(builder, builder, true,
				func(node: Node) -> bool: return node.name != "Merged" and not node.has_meta("generated")))
			var left: int = fix.resolve(all, builder)
			assert(left == 0, "%s/%s: %d pares sobraram" % [room, world_name, left])
	print("PASS: superfícies sobrepostas corrigidas (caixas soltas e salas)")
	quit()


func _box(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	node.material_override = material
	parent.add_child(node)
	return node
