class_name ElevatorCab3D
extends RefCounted
## Cabine do elevador principal, parada num andar (Quartos ou Salão). Só peças visuais: as
## laterais encostam nas paredes do poço e o teto fica acima da cabeça, então nada nela precisa
## de colisão. O alçapão do teto fica sobre a escada de marinheiro.

const SHAFT := Vector2(15.4, 17.1)
const BACK: float = 0.4
const FRONT: float = 1.95
const ROOF: float = 2.55
const HATCH := Rect2(16.15, 0.45, 0.7, 0.6)


static func build(parent: Node3D, present: bool) -> Node3D:
	var cab := Node3D.new()
	cab.name = "Cabine"
	parent.add_child(cab)
	var x0 := SHAFT.x + 0.1
	var x1 := SHAFT.y - 0.1
	var wood := "mahogany" if not present else "plank"
	var metal := "brass" if not present else "iron"
	# Piso da cabine, rente ao patamar, com a moldura do alçapão de baixo
	_part(cab, Vector3(x0, -0.02, BACK + 0.15), Vector3(x1, 0.005, FRONT), wood, present)
	_part(cab, Vector3(HATCH.position.x, 0.005, HATCH.position.y + 0.15), Vector3(HATCH.end.x, 0.012, HATCH.end.y + 0.15), metal, present)
	# Laterais encostadas no poço
	for x: float in [x0, x1 - 0.05]:
		_part(cab, Vector3(x, 0, BACK + 0.15), Vector3(x + 0.05, ROOF, FRONT), wood, present)
		_part(cab, Vector3(x - 0.005, 0.95, BACK + 0.15), Vector3(x + 0.055, 1.0, FRONT), metal, present)
	# Teto com o alçapão aberto (tampa levantada)
	_part(cab, Vector3(x0, ROOF, BACK + 0.05), Vector3(HATCH.position.x, ROOF + 0.06, FRONT), wood, present)
	_part(cab, Vector3(HATCH.end.x, ROOF, BACK + 0.05), Vector3(x1, ROOF + 0.06, FRONT), wood, present)
	_part(cab, Vector3(HATCH.position.x, ROOF, HATCH.end.y), Vector3(HATCH.end.x, ROOF + 0.06, FRONT), wood, present)
	var lid := _part(cab, Vector3(HATCH.position.x, ROOF + 0.06, HATCH.end.y - 0.03), Vector3(HATCH.end.x, ROOF + 0.66, HATCH.end.y), wood, present)
	lid.rotation_degrees.x = -12.0
	# Painel de botões ao lado da porta
	_part(cab, Vector3(x1 - 0.06, 1.1, FRONT - 0.3), Vector3(x1 - 0.04, 1.5, FRONT - 0.12), metal, present)
	# Cabos que somem para o alto
	for x: float in [15.95, 16.55]:
		_part(cab, Vector3(x, ROOF + 0.06, 1.2), Vector3(x + 0.02, 3.2, 1.22), "iron", present)
	return cab


static func _part(cab: Node3D, from: Vector3, to: Vector3, role: String, present: bool) -> MeshInstance3D:
	var piece := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = (to - from).abs()
	piece.mesh = mesh
	piece.position = (from + to) / 2.0
	piece.material_override = HotelMaterials.get_material(role, present)
	cab.add_child(piece)
	return piece
