extends SceneTree
## A faixa de madeira não pode dividir o mesmo plano visível com os azulejos.
class RawKitchen extends "res://scripts/puzzles/cozinha/kitchen_room_3d.gd":
	func _merge_static_meshes() -> void:
		pass

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for present: bool in [false,true]:
		var room := RawKitchen.new()
		room.present = present
		root.add_child(room)
		# Amostra o meio da área atrás do fogão e a faixa no alto dos azulejos.
		for y: float in [5.4,6.02,6.5]:
			var planes: Array[float] = []
			for child in room.get_children():
				if not child is MeshInstance3D or not child.mesh is BoxMesh:
					continue
				if not child.rotation.is_zero_approx():
					continue
				var bounds: AABB = child.mesh.get_aabb()
				bounds.position += child.position
				if bounds.position.x < 15 and bounds.end.x > 15 and bounds.position.y < y and bounds.end.y > y and bounds.end.z <= 0.05 and bounds.end.z >= 0:
					for z in planes:
						if is_equal_approx(z,bounds.end.z):
							push_error("Duas faces da parede no mesmo plano: y=%s z=%s" % [y,z])
							quit(1)
							return
					planes.append(bounds.end.z)
			assert(not planes.is_empty(),"Revestimento presente na amostra")
		room.free()
	print("PASS: parede e faixa sem faces sobrepostas nas duas épocas")
	quit()
