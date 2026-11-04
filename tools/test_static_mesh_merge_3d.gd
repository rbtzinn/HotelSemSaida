extends SceneTree
## Caixas e prismas com o mesmo material devem preservar todas as faces após a união.
func _initialize() -> void:
 _run.call_deferred()

func _run() -> void:
 var builder = load("res://scripts/world3d/hotel_builder_3d.gd").new()
 root.add_child(builder)
 var box = builder._part(Vector3.ZERO, Vector3.ONE, "lacquer")
 var prism = builder._extrude(PackedVector2Array([Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]), 0.6, 1.0, Vector3(3,0,0), 0, "lacquer")
 var expected: int = box.mesh.get_faces().size() + prism.mesh.get_faces().size()
 var normals: PackedVector3Array = prism.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
 for normal in normals:
  assert(normal.length() > 0.99, "Normais do prisma não podem se anular")
 builder._merge_static_meshes()
 var actual := 0
 for child in builder.get_children():
  if child is MeshInstance3D:
   actual += child.mesh.get_faces().size()
 assert(actual == expected, "A união perdeu faces: %d de %d" % [actual,expected])
 print("PASS: união preserva as faces do corpo e tampa do piano; normais válidas")
 quit()
