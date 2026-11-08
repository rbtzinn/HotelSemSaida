extends SceneTree
## Conferência de encaixe das peças reportadas: cabos, pernas e acervo.
class RawLibrary extends "res://scripts/puzzles/biblioteca/library_room_3d.gd":
	func _merge_static_meshes() -> void:
		pass
class RawProp extends "res://scripts/puzzles/cozinha/kitchen_prop_3d.gd":
	func _merge_static_meshes() -> void:
		pass
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var prop := RawProp.new()
	prop.kind = "shaft_open"
	root.add_child(prop)
	var cables := 0
	for child in prop.get_children():
		if child is MeshInstance3D and child.mesh is CylinderMesh:
			var end: Vector3 = child.transform * Vector3(0, child.mesh.height/2, 0)
			assert(end.y >= 8.099, "Cabo deve chegar à fixação superior: %s" % end)
			cables += 1
	assert(cables == 3, "Três cabos contínuos")
	prop.free()
	for present: bool in [false, true]:
		var room := RawLibrary.new()
		room.present = present
		root.add_child(room)
		# As cadeiras são o modelo do Blender (pés modelados até o assento), apoiadas no piso
		var chairs := 0
		for child in room.get_children():
			if child is Node3D and child.scene_file_path.ends_with("cadeira_biblioteca.glb"):
				assert(absf(child.position.y) < 0.001, "Cadeira apoiada no piso")
				chairs += 1
		assert(chairs == 4, "Quatro cadeiras")
		var niche = room.find_child("NicheBase", false, false)
		var niche_size: Vector3 = niche.get_child(0).shape.size
		var niche_box: AABB = niche.transform * AABB(-niche_size/2, niche_size)
		for child in room.get_children():
			if child is StaticBody3D and str(child.name).begins_with("Bookcase"):
				var size: Vector3 = child.get_child(0).shape.size
				var bounds: AABB = child.transform * AABB(-size/2, size)
				assert(not bounds.intersects(niche_box), "Acervo não invade estante")
		room.free()
	print("PASS: cabos completos, cadeiras sem vãos e acervo fora das estantes")
	quit()
