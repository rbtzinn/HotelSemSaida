@tool
class_name MaintenanceRoom3D
extends HotelBuilder3D
## Sala de manutenção sob a despensa, com corredor de serviço para a Biblioteca.
## A Cozinha fica na ala oeste e a Biblioteca na nordeste: o corredor sai pela parede sul,
## vira e passa por baixo do Saguão até a escada de serviço da Biblioteca.

## Vão da parede sul (x) que leva ao corredor.
const CORRIDOR_DOOR := Vector2(3.7, 5.3)
## Trecho longo do corredor: faixa livre em z e fim em x (escada da Biblioteca).
const CORRIDOR_Z := Vector2(10.6, 12.2)
const CORRIDOR_END: float = 27.0
const CORRIDOR_HEIGHT: float = 2.8

## Modelos do Blender (tools/blender/make_props.py); hoje, madeira velha e metal enferrujado.
const MODELS := "res://art/models/"
const AGED := {"oak": "plank", "brass": "iron", "copper": "iron"}

func _build_room() -> void:
	_part(Vector3(-0.3, -0.25, -0.3), Vector3(9.3, 0, 9.3), "stone")
	_solid(Vector3(-0.3, -0.25, -0.3), Vector3(9.3, 0, 9.3), "Floor")
	for x: float in [-0.15, 9.15]:
		_block(Vector3(x, 1.8, 4.5), Vector3(0.3, 3.6, 9.6), "plaster_cream")
		_solid(Vector3(x-0.15, 0, -0.3), Vector3(x+0.15, 3.6, 9.3), "Wall")
	_block(Vector3(4.5, 1.8, -0.15), Vector3(9.6, 3.6, 0.3), "plaster_cream")
	_solid(Vector3(-0.3, 0, -0.3), Vector3(9.3, 3.6, 0), "Wall")
	# Parede sul com o vão do corredor de serviço.
	var door := CORRIDOR_DOOR
	for span: Vector2 in [Vector2(-0.3, door.x), Vector2(door.y, 9.3)]:
		_part(Vector3(span.x, 0, 9.0), Vector3(span.y, 3.6, 9.3), "plaster_cream")
		_solid(Vector3(span.x, 0, 9.0), Vector3(span.y, 3.6, 9.3), "WallSouth")
	_part(Vector3(door.x, CORRIDOR_HEIGHT, 9.0), Vector3(door.y, 3.6, 9.3), "plaster_cream")
	_solid(Vector3(door.x, CORRIDOR_HEIGHT, 9.0), Vector3(door.y, 3.6, 9.3), "CorridorLintel")
	_build_corridor()
	_build_ceiling_hatch()
	_build_time_clock()
	_build_storage()
	for x: float in [1, 4.5, 8]:
		_block(Vector3(x, 3.42, 4.5), Vector3(0.18, 0.28, 9), "cast_iron")
	for y: float in [2.5, 2.8, 3.05]:
		_cylinder(Vector3(0.25, y, 0.1), 0.06, 0.06, 8.6, "copper", Vector3(90, 0, 0), 10)
		for z: float in [1, 4, 7]:
			_torus(Vector3(0.25, y, z), 0.065, 0.085, "iron", Vector3(90, 0, 0))
	# Bancada com morsa (o meio do tampo fica livre para a chave de 1951)
	_model(MODELS + "bancada_oficina.glb", Vector3(6.4, 0, 0.7), Vector3.ZERO, 1.0, AGED if present else {})
	_solid(Vector3(4.8, 0, 0.25), Vector3(8, 0.9, 1.15), "Workbench")
	_label("MANUTENÇÃO", Vector3(6.4, 2.3, 0.04), 0.16, Color("#C9973B"))
	# Painel elétrico, manômetro e ferramentas presas na parede.
	_block(Vector3(8.92, 1.6, 6.1), Vector3(0.08, 1.2, 0.8), "iron")
	for i in 4:
		_block(Vector3(8.85, 1.22+i*0.23, 6.1), Vector3(0.04, 0.08, 0.45), "brass")
	_cylinder(Vector3(8.75, 2.3, 6.1), 0.18, 0.18, 0.06, "brass", Vector3(0, 0, 90))
	_cylinder(Vector3(8.7, 2.3, 6.1), 0.15, 0.15, 0.02, "ivory", Vector3(0, 0, 90))
	_block(Vector3(8.65, 2.34, 6.1), Vector3(0.02, 0.1, 0.01), "iron", Vector3(20, 0, 0))
	for z: float in [2.8, 5.0]:
		_torus(Vector3(0.4, 2.8, z), 0.15, 0.18, "iron", Vector3(0, 0, 90))
		for angle: float in [0, 60, 120]:
			_block(Vector3(0.4, 2.8, z), Vector3(0.025, 0.3, 0.025), "iron", Vector3(angle, 0, 0))
	for i in 5:
		var x := 5.2+i*0.5
		_block(Vector3(x, 1.65, 0.06), Vector3(0.04, 0.33, 0.025), "iron")
		_torus(Vector3(x, 1.86, 0.08), 0.035, 0.05, "iron", Vector3(90, 0, 0))
	# Armários de ferramentas e caixas; a chave fica na bancada livre.
	for x: float in [1.5, 3.1]:
		_model(MODELS + "armario_ferramentas.glb", Vector3(x, 0, 0.45), Vector3.ZERO, 1.0, AGED if present else {})
		_solid(Vector3(x-0.65, 0, 0.1), Vector3(x+0.65, 2.1, 0.8), "Locker")
	for i in 6:
		var at := Vector3(7.8, 0.22+(i%2)*0.46, 3.0+(i/2)*0.7)
		_block(at, Vector3(0.8, 0.44, 0.6), "plank", Vector3(0, _random(i)*6, 0))
	_solid(Vector3(7.3, 0, 2.6), Vector3(8.3, 0.9, 5), "Crates")
	# Poço de descida e escada de retorno à despensa.
	for x: float in [1.2, 1.9]:
		_cylinder(Vector3(x, 0, 7.2), 0.035, 0.035, 4.25, "iron")
	for i in 15:
		_cylinder(Vector3(1.2, 0.2+i*0.28, 7.2), 0.022, 0.022, 0.7, "iron", Vector3(0, 0, -90), 8)
	if present:
		for i in 14:
			_block(Vector3(0.6+_random(i)*2, 0.08, 3+_random(i, 3)*3), Vector3(0.25, 0.12, 0.4), "rubble", Vector3(0, _random(i, 5)*170, 10))
		_omni(Vector3(4.5, 2.8, 4), Color("#6A7E96"), 0.55, 11)
		_part(Vector3(0.5, 0.01, 4.2), Vector3(2.5, 0.018, 5.5), "dark")
	else:
		_omni(Vector3(4.5, 3.0, 4), Color("#F2D49B"), 1.6, 11)
	_cylinder(Vector3(4.5, 3.2, 4), 0.18, 0.11, 0.2, "iron")
	_sphere(Vector3(4.5, 3.15, 4), 0.08, "bulb")


## Corredor de serviço: desce para o sul, vira para o leste e segue sob o Saguão.
## No fim, a escada e a porta de ferro da Biblioteca (usada com E no patamar inferior).
func _build_corridor() -> void:
	var d := CORRIDOR_DOOR
	var cz := CORRIDOR_Z
	var top := CORRIDOR_HEIGHT
	var mid := (cz.x + cz.y) / 2.0
	var wall := "plaster_cream" if not present else "stone"
	_part(Vector3(d.x - 0.3, -0.25, 9.3), Vector3(CORRIDOR_END + 0.3, 0, cz.y + 0.3), "stone")
	_solid(Vector3(d.x - 0.3, -0.25, 9.3), Vector3(CORRIDOR_END + 0.3, 0, cz.y + 0.3), "CorridorFloor")
	_part(Vector3(d.x - 0.3, top, 9.3), Vector3(CORRIDOR_END + 0.3, top + 0.2, cz.y + 0.3), "stone")
	_solid(Vector3(d.x - 0.3, top, 9.3), Vector3(CORRIDOR_END + 0.3, top + 0.2, cz.y + 0.3), "CorridorCeiling")
	# Paredes: oeste do trecho curto (e fundo do longo), leste do curto, norte e sul do longo, fim.
	for wall_box: Array in [
		[Vector3(d.x - 0.3, 0, 9.3), Vector3(d.x, top, cz.y + 0.3)],
		[Vector3(d.y, 0, 9.3), Vector3(d.y + 0.3, top, cz.x)],
		[Vector3(d.y, 0, cz.x - 0.3), Vector3(CORRIDOR_END + 0.3, top, cz.x)],
		[Vector3(d.x - 0.3, 0, cz.y), Vector3(CORRIDOR_END + 0.3, top, cz.y + 0.3)],
		[Vector3(CORRIDOR_END, 0, cz.x - 0.3), Vector3(CORRIDOR_END + 0.3, top, cz.y + 0.3)],
	]:
		_part(wall_box[0], wall_box[1], wall)
		_solid(wall_box[0], wall_box[1], "CorridorWall")
	# Canos de vapor ao longo da parede norte, da Cozinha até a Biblioteca.
	for y: float in [2.25, 2.5]:
		_cylinder(Vector3(d.y + 0.3, y, cz.x + 0.1), 0.05, 0.05, CORRIDOR_END - d.y - 0.3, "copper",
			Vector3(0, 0, -90), 10)
		for x: float in [8.0, 13.0, 18.0, 23.0]:
			_torus(Vector3(x, y, cz.x + 0.1), 0.055, 0.075, "iron", Vector3(0, 0, 90))
	# Placa na curva e placa no meio, para o jogador saber por onde passa.
	_label("BIBLIOTECA  →", Vector3(d.x + 0.02, 1.9, mid), 0.1, Color("#C9973B"), 90)
	_label("SOB O SAGUÃO — NÃO FUMAR", Vector3(15.5, 1.9, cz.y - 0.02), 0.08,
		Color("#C9973B") if not present else Color("#5A5040"), 180)
	if present:
		_part(Vector3(11.0, 0.005, cz.x + 0.2), Vector3(14.2, 0.012, cz.y - 0.3), "dark")
		for i in 10:
			var at := Vector3(7.0 + _random(i, 7) * 17.0, 0.04, cz.x + 0.25 + _random(i, 8) * 1.1)
			_block(at, Vector3(0.22, 0.08, 0.3), "rubble", Vector3(0, _random(i, 9) * 170, 0))
	for x: float in [7.5, 15.5, 23.5]:
		_cylinder(Vector3(x, top - 0.18, mid), 0.1, 0.06, 0.18, "iron")
		_sphere(Vector3(x, top - 0.25, mid), 0.06, "bulb")
		if not present:
			_omni(Vector3(x, top - 0.4, mid), Color("#F2D49B"), 0.9, 6.0)
	if present:
		_omni(Vector3(16.0, 2.2, mid), Color("#6A7E96"), 0.35, 12.0)
	# Escada de acesso à Biblioteca no fim do corredor.
	var width := cz.y - cz.x
	for i in 6:
		_block(Vector3(CORRIDOR_END - 0.9 + i * 0.14, 0.07 + i * 0.14, mid), Vector3(0.3, 0.14, width), "stone")
	_block(Vector3(CORRIDOR_END - 0.05, 1.4, mid), Vector3(0.08, 2.6, width - 0.1), "iron")
	_label("BIBLIOTECA — SERVIÇO", Vector3(CORRIDOR_END - 0.1, 2.55, mid), 0.1, Color("#C9973B"), -90)
	for z: float in [cz.x + 0.06, cz.y - 0.06]:
		_block(Vector3(CORRIDOR_END - 0.1, 1.35, z), Vector3(0.12, 2.7, 0.12), "brass")
	_solid(Vector3(CORRIDOR_END - 1.05, 0, cz.x), Vector3(CORRIDOR_END, 0.84, cz.y), "ServiceStairs")


## Relógio de ponto dos funcionários na parede oeste, com o escaninho das fichas.
## A ficha de Otília (MaintenanceLevel3D) é a leitura; aqui só o móvel.
func _build_time_clock() -> void:
	var wood := "oak" if not present else "plank"
	_part(Vector3(0.0, 1.15, 3.75), Vector3(0.28, 1.75, 4.25), wood)
	_cylinder(Vector3(0.28, 1.55, 4.0), 0.16, 0.16, 0.03, "brass", Vector3(0, 0, 90), 20)
	_cylinder(Vector3(0.3, 1.55, 4.0), 0.13, 0.13, 0.01, "ivory", Vector3(0, 0, 90), 20)
	_block(Vector3(0.315, 1.58, 4.0), Vector3(0.005, 0.08, 0.012), "lacquer", Vector3(25, 0, 0))
	_block(Vector3(0.315, 1.55, 4.03), Vector3(0.005, 0.012, 0.07), "lacquer")
	_part(Vector3(0.05, 1.2, 3.85), Vector3(0.3, 1.3, 4.15), "cast_iron")
	_part(Vector3(0.24, 1.75, 3.9), Vector3(0.3, 1.82, 4.1), "brass")
	# Escaninho: 3 x 4 casas, poucas fichas (hoje, quase todas apodrecidas)
	# Fundo e laterais; a frente fica aberta para as fichas aparecerem
	_part(Vector3(0.0, 1.0, 4.45), Vector3(0.03, 1.9, 5.45), wood)
	for z: float in [4.45, 5.43]:
		_part(Vector3(0.0, 1.0, z), Vector3(0.2, 1.9, z + 0.02), wood)
	_part(Vector3(0.0, 1.88, 4.45), Vector3(0.2, 1.9, 5.45), wood)
	for row in 4:
		var y := 1.05 + row * 0.22
		_part(Vector3(0.0, y, 4.45), Vector3(0.2, y + 0.015, 5.45), "dark_wood")
		for col in 3:
			var z := 4.55 + col * 0.31
			if present and (row + col) % 3 != 0:
				continue
			if not present and (row * 3 + col) % 4 == 3:
				continue
			_part(Vector3(0.12, y + 0.02, z), Vector3(0.14, y + 0.2, z + 0.2), "paper", Vector3(0, 0, -6))
	_label("PONTO", Vector3(0.29, 1.95, 4.0), 0.07, Color("#C9973B") if not present else Color("#4A463E"), 90)


## Boiler de água quente, estante de latas e balde no canto: a sala é de trabalho.
func _build_storage() -> void:
	var tank := Vector3(8.35, 0, 8.35)
	_model(MODELS + "aquecedor.glb", tank, Vector3.ZERO, 1.0, {"copper": "iron", "brass": "iron"} if present else {})
	_solid_cylinder(tank, 0.48, 2.3, "Tank")
	# Estante de latas na parede sul, ao lado do boiler
	var frame := "dark_wood" if not present else "plank"
	_part(Vector3(6.0, 0, 8.95), Vector3(7.6, 1.9, 9.0), frame)
	for x: float in [6.0, 7.56]:
		_part(Vector3(x, 0, 8.55), Vector3(x + 0.04, 1.9, 9.0), frame)
	for y: float in [0.45, 0.95, 1.45]:
		_part(Vector3(6.0, y, 8.55), Vector3(7.6, y + 0.04, 9.0), "oak" if not present else "plank")
		for i in 6:
			if present and _random(i, y) < 0.4:
				continue
			_cylinder(Vector3(6.2 + i * 0.25, y + 0.04, 8.75), 0.08, 0.08, 0.17, "iron" if i % 2 else "copper", Vector3.ZERO, 10)
	_solid(Vector3(6.0, 0, 8.55), Vector3(7.6, 1.9, 9.0), "CanShelf")
	# Balde com esfregão junto aos armários
	_cylinder(Vector3(2.55, 0, 1.25), 0.17, 0.2, 0.3, "iron", Vector3.ZERO, 12)
	_cylinder(Vector3(2.5, 0.2, 1.25), 0.015, 0.015, 1.3, "oak", Vector3(0, 0, 14), 6)
	_solid_cylinder(Vector3(2.55, 0, 1.25), 0.2, 0.3, "Bucket")
	if present:
		# Infiltração escorrendo do teto até o piso
		_part(Vector3(3.0, 0.005, 2.2), Vector3(4.6, 0.012, 3.6), "dark")
		_part(Vector3(3.7, 2.0, 0.005), Vector3(4.1, 3.6, 0.012), "dark")


## Vão real sobre a escada: a laje termina nas bordas, em vez de tapar a subida.
func _build_ceiling_hatch() -> void:
	var opening := Rect2(1.0, 6.7, 1.1, 1.2)
	for rect: Rect2 in [Rect2(0, 0, 9, opening.position.y), Rect2(0, opening.end.y, 9, 9-opening.end.y), Rect2(0, opening.position.y, opening.position.x, opening.size.y), Rect2(opening.end.x, opening.position.y, 9-opening.end.x, opening.size.y)]:
		var start := Vector3(rect.position.x, 3.6, rect.position.y)
		var end := Vector3(rect.end.x, 3.8, rect.end.y)
		_part(start, end, "stone")
		_solid(start, end, "CeilingAroundHatch")
	# Madeira do piso da despensa vista pela abertura e o pequeno poço de ligação.
	for x: float in [0.93, 2.17]:
		_block(Vector3(x, 3.7, 7.3), Vector3(0.14, 0.28, 1.48), "oak")
		_block(Vector3(x, 4.1, 7.3), Vector3(0.1, 0.6, 1.4), "plank")
	for z: float in [6.63, 7.97]:
		_block(Vector3(1.55, 3.7, z), Vector3(1.35, 0.28, 0.14), "oak")
		_block(Vector3(1.55, 4.1, z), Vector3(1.35, 0.6, 0.1), "plank")
	# Tampa aberta apoiada ao lado do vão. A madeira está lascada no presente.
	var lid := _group(Vector3(2.18, 3.81, 7.3), 0)
	lid.rotation_degrees.z = 75
	for i in 5:
		_child_box(lid, Vector3(0.52, 0, -0.48+i*0.24), Vector3(1.04, 0.055, 0.22), "plank" if present else "oak")
	for x: float in [0.12, 0.85]:
		_child_box(lid, Vector3(x, -0.04, 0), Vector3(0.07, 0.035, 1.2), "iron")
	if present:
		for i in 5:
			_block(Vector3(1.05+i*0.2, 3.78, 6.77), Vector3(0.12, 0.06, 0.28), "plank", Vector3(12+i*3, 0, 0))
	# A câmara superior permanece escura, sem iluminar artificialmente a saída.
	_part(Vector3(0.9, 4.6, 6.6), Vector3(2.2, 4.65, 8), "dark")
