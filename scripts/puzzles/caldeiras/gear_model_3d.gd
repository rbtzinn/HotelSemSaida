extends RefCounted
## Mesmo perfil na mão, no depósito e nos eixos. O furo atravessa as duas faces.
const PINION := "pinhao_f2"
const CROWN := "coroa_f2"
static var _meshes: Dictionary = {}

static func mesh_for(id: String) -> ArrayMesh:
	if _meshes.has(id):
		return _meshes[id]
	var teeth := 12 if id == PINION else 20
	var pitch := teeth * 0.011
	var bore := 0.036 if id == PINION else 0.055
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in teeth * 4:
		var a := TAU*i/(teeth*4.0)
		var b := TAU*(i+1)/(teeth*4.0)
		var unit_a := Vector3(cos(a),sin(a),0)
		var unit_b := Vector3(cos(b),sin(b),0)
		var oa := unit_a*(pitch + (0.014 if i%4 in [1,2] else -0.014))
		var ob := unit_b*(pitch + (0.014 if (i+1)%4 in [1,2] else -0.014))
		var ia := unit_a*bore
		var ib := unit_b*bore
		var half := Vector3(0,0,0.027)
		_quad(tool,ia+half,ib+half,ob+half,oa+half)
		_quad(tool,oa-half,ob-half,ib-half,ia-half)
		_quad(tool,oa+half,ob+half,ob-half,oa-half)
		_quad(tool,ib+half,ia+half,ia-half,ib-half)
	tool.index()
	var mesh := tool.commit()
	_meshes[id] = mesh
	return mesh

static func _quad(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	tool.set_normal((c-a).cross(b-a).normalized())
	for point: Vector3 in [a,b,c,a,c,d]:
		tool.add_vertex(point)
