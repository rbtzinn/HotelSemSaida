@tool
class_name LibraryRoom3D
extends HotelBuilder3D
## Biblioteca e arquivo reservado: mesma planta, materiais e luz do hotel nas duas épocas.
const W: float = 18.0
const D: float = 13.0
const H: float = 6.0
## Livre da estante lateral; o livro, a placa e as interações usam a mesma origem.
const NICHE_ORIGIN := Vector3(2.2, 0, 10.9)

func _build_room() -> void:
	_part(Vector3(-0.3, -0.25, -3.3), Vector3(W+0.3, 0, D+0.3), "floorboards")
	_solid(Vector3(-0.3, -0.25, -3.3), Vector3(W+0.3, 0, D+0.3), "Floor")
	for x: float in [-0.15, W+0.15]:
		_block(Vector3(x, H/2, 5), Vector3(0.3, H, 16.6), "wallpaper")
		_solid(Vector3(x-0.15, 0, -3.3), Vector3(x+0.15, H, D+0.3), "Wall")
	for z: float in [-3.15, D+0.15]:
		_block(Vector3(W/2, H/2, z), Vector3(W+0.6, H, 0.3), "wallpaper")
		_solid(Vector3(-0.3, 0, z-0.15), Vector3(W+0.3, H, z+0.15), "Wall")
	_part(Vector3(-0.3, H, -3.3), Vector3(W+0.3, H+0.2, D+0.3), "ceiling")
	# Parede do arquivo, interrompida pelo vão da estante secreta.
	for span: Vector2 in [Vector2(0, 8), Vector2(10, 18)]:
		_part(Vector3(span.x, 0, -0.25), Vector3(span.y, H, 0), "wainscot")
		_solid(Vector3(span.x, 0, -0.25), Vector3(span.y, H, 0), "ArchiveWall")
	_part(Vector3(8, 3.2, -0.25), Vector3(10, H, 0), "wainscot")
	_solid(Vector3(8, 3.2, -0.25), Vector3(10, H, 0), "ArchiveLintel")
	# Rodapés, painéis e teto em caixotões.
	for z: float in [-3.0, 12.95]:
		_block(Vector3(9, 0.15, z), Vector3(18, 0.3, 0.08), "dark_wood")
		_block(Vector3(9, 1.15, z), Vector3(18, 0.06, 0.08), "brass")
	for x: float in [0.06, 17.94]:
		_block(Vector3(x, 0.15, 5), Vector3(0.1, 0.3, 16), "dark_wood")
		_block(Vector3(x, 1.15, 5), Vector3(0.1, 0.06, 16), "brass")
	for x: float in [0, 3, 6, 9, 12, 15, 18]:
		_block(Vector3(x, H-0.17, 6.4), Vector3(0.14, 0.34, 13), "dark_wood")
	for z: float in [0, 3, 6, 9, 12.9]:
		_block(Vector3(9, H-0.17, z), Vector3(18, 0.34, 0.14), "dark_wood")
	# Estantes altas nas laterais, com corredores largos.
	for z: float in [1.7, 4.3, 7.0, 9.7]:
		_shelf(Vector3(0.75, 0, z), 90, 2.2, 3.7, 20+int(z))
		_shelf(Vector3(17.25, 0, z), -90, 2.2, 3.7, 40+int(z))
	for x: float in [1.6, 6.7, 12.2, 15.8]:
		_shelf(Vector3(x, 0, 0.55), 0, 2.0, 3.1, 60+int(x))
	# A estante de livros interativos fica separada do cenário fixo.
	_block(Vector3(4.3, 1.34, 0.66), Vector3(2.7, 0.08, 0.7), "mahogany")
	_block(Vector3(4.3, 2.05, 0.3), Vector3(2.7, 0.08, 0.08), "mahogany")
	for x: float in [2.95, 5.65]:
		_block(Vector3(x, 1.75, 0.45), Vector3(0.08, 1.1, 0.8), "mahogany")
	_label("COLEÇÃO PARTICULAR", Vector3(4.3, 2.3, 0.37), 0.1, Color("#C9973B"))
	# Mesas de leitura, cadeiras, candelabros e escaninho do bibliotecário.
	for x: float in [5, 13]:
		_table(Vector3(x, 0, 6.8))
		for z: float in [5.5, 8.2]:
			_chair(Vector3(x, 0, z), 0 if z<6 else 180)
		if not present:
			_cylinder(Vector3(x+0.5, 0.96, 6.6), 0.15, 0.12, 0.04, "brass")
			_cylinder(Vector3(x+0.5, 1, 6.6), 0.02, 0.02, 0.4, "brass")
			_block(Vector3(x+0.5, 1.45, 6.6), Vector3(0.42, 0.18, 0.22), "green_velvet")
			_omni(Vector3(x+0.5, 1.33, 6.6), Color("#F2D49B"), 0.9, 4.0)
	# Tapete comprido na passagem central.
	var rug := HotelMaterials.rug_material("runner", present, Vector2(9, 7), Vector2(1.4, 4.4))
	_part(Vector3(7.6, 0.008, 2.6), Vector3(10.4, 0.02, 11.4), "rug", Vector3.ZERO, rug)
	# Acervo independente da estante, com uma abertura legível sob o tampo.
	var n := NICHE_ORIGIN
	_block(n+Vector3(0, 0.65, 0), Vector3(0.95, 1.3, 0.9), "dark_wood")
	_solid(n+Vector3(-0.475, 0, -0.45), n+Vector3(0.475, 1.3, 0.45), "NicheBase")
	_block(n+Vector3(0, 1.53, 0), Vector3(1.1, 0.1, 1.08), "marble")
	for x: float in [-0.5, 0.5]:
		for z: float in [-0.49, 0.49]:
			_block(n+Vector3(x, 1.39, z), Vector3(0.055, 0.2, 0.06), "dark_wood")
	# Placa presa na face do móvel, voltada para o corredor.
	_block(n+Vector3(0.49, 1.06, 0), Vector3(0.025, 0.2, 0.5), "lacquer")
	_label("ACERVO", n+Vector3(0.508, 1.06, 0), 0.075, Color("#E8DCC0"), 90)
	# Janelas altas. Vidro no passado, tábuas e luar no presente.
	for z: float in [3.0, 7.0, 10.5]:
		_block(Vector3(17.81, 3.5, z), Vector3(0.06, 2.6, 1.7), "night")
		for edge: float in [-0.9, 0.9]:
			_block(Vector3(17.74, 3.5, z+edge), Vector3(0.12, 2.85, 0.1), "brass")
		_block(Vector3(17.72, 3.5, z), Vector3(0.12, 2.8, 0.05), "brass")
		_block(Vector3(17.72, 3.2, z), Vector3(0.12, 0.06, 1.8), "brass")
		for edge: float in [-1.1, 1.1]:
			_block(Vector3(17.5, 3.2, z+edge), Vector3(0.3, 3.5, 0.35), "velvet")
		if present:
			for i in 2:
				_block(Vector3(17.65, 2.8+i*0.7, z), Vector3(0.1, 0.15, 1.7), "plank", Vector3(8, 0, 10-i*15))
			_spot(Vector3(17.4, 4.6, z), Vector3(9, 0, z-1), Color("#9FB4C8"), 3.0, 14, 20)
	# Entrada com letreiro e moldura, em frente ao corredor central.
	_block(Vector3(9, 1.25, 12.92), Vector3(1.6, 2.5, 0.1), "mahogany")
	for x: float in [8.08, 9.92]:
		_block(Vector3(x, 1.35, 12.85), Vector3(0.14, 2.7, 0.18), "brass")
	_block(Vector3(9, 2.7, 12.85), Vector3(2, 0.15, 0.18), "brass")
	_label("BIBLIOTECA", Vector3(9, 2.48, 12.72), 0.11, Color("#C9973B"), 180)
	# Arquivo escondido: armários, mesa e documentos, acessível pela estante móvel.
	for x: float in [2, 5, 13, 16]:
		_shelf(Vector3(x, 0, -2.7), 0, 2.2, 2.7, 90+int(x))
	_table(Vector3(9, 0, -1.8))
	_block(Vector3(6.95, 1.2, -2.925), Vector3(1.34, 2.4, 0.15), "iron")
	for x: float in [6.24, 7.66]:
		_block(Vector3(x, 1.25, -2.85), Vector3(0.09, 2.5, 0.15), "dark_wood")
	_block(Vector3(6.95, 2.46, -2.85), Vector3(1.51, 0.1, 0.15), "dark_wood")
	_block(Vector3(6.95, 1.87, -2.836), Vector3(0.86, 0.22, 0.028), "lacquer")
	_label("CALDEIRAS", Vector3(6.95, 1.87, -2.815), 0.10, Color("#E1C28C"))
	_sphere(Vector3(7.46, 1.07, -2.80), 0.054, "brass")
	_label("ARQUIVO RESERVADO", Vector3(9, 2.6, -2.94), 0.12, Color("#C9973B"))
	for z: float in [3.0, 8.7]:
		_cylinder(Vector3(9, H-0.8, z), 0.025, 0.025, 0.8, "brass")
		_torus(Vector3(9, H-0.95, z), 0.45, 0.5, "brass")
		for i in 6:
			var a := TAU*i/6.0
			var at := Vector3(9+cos(a)*0.45, H-1.05, z+sin(a)*0.45)
			_sphere(at, 0.07, "bulb")
		if not present:
			_omni(Vector3(9, H-1.2, z), Color("#F2D49B"), 2.4, 10, true)
	if present:
		_omni(Vector3(9, 4, 6), Color("#6A7E96"), 0.5, 16)
		for i in 30:
			var at := Vector3(1+_random(i, 1)*16, 0.03, 1+_random(i, 2)*11)
			_block(at, Vector3(0.18, 0.025, 0.27), "paper", Vector3(0, _random(i, 3)*180, 0))
		for i in 8:
			_block(Vector3(0.2+_random(i)*1.6, 0.1, 2+_random(i, 2)*9), Vector3(0.3, 0.2, 0.6), "plank", Vector3(10, _random(i, 4)*90, 20))
	else:
		_omni(Vector3(9, 3.7, 6), Color("#A8794F"), 0.6, 16)
		_omni(Vector3(4.3, 2.8, 2.0), Color("#F2D49B"), 0.85, 4.5)

func _shelf(at: Vector3, yaw: float, width: float, height: float, seed_index: int) -> void:
	var holder := _group(at, yaw)
	_child_box(holder, Vector3(0, height/2, -0.28), Vector3(width, height, 0.08), "dark_wood")
	for side: float in [-1, 1]:
		_child_box(holder, Vector3(side*width/2, height/2, 0), Vector3(0.12, height, 0.65), "mahogany")
	for row in 5:
		var y := 0.12+row*(height-0.25)/4
		_child_box(holder, Vector3(0, y, 0), Vector3(width, 0.07, 0.7), "mahogany")
		if row==4:
			continue
		for i in 9:
			if present and (i+row+seed_index)%4==0:
				continue
			var book_h := 0.3+_random(i+row*11, seed_index)*0.22
			var role: String = ["green_velvet", "mahogany", "velvet", "oak"][posmod(i+row+seed_index, 4)]
			var x := -width/2+0.22+i*(width-0.4)/9
			_child_box(holder, Vector3(x, y+0.035+book_h/2, 0.08), Vector3(0.12, book_h, 0.3), role)
			_child_box(holder, Vector3(x, y+0.12, 0.237), Vector3(0.1, 0.012, 0.01), "brass")
	var body := _solid(Vector3(-width/2, 0, -0.35), Vector3(width/2, height, 0.35), "Bookcase")
	body.transform = holder.transform * body.transform

func _table(at: Vector3) -> void:
	_block(at+Vector3(0, 0.92, 0), Vector3(2.9, 0.1, 1.2), "mahogany")
	_block(at+Vector3(0, 0.98, 0), Vector3(2.6, 0.025, 1), "green_velvet")
	for x: float in [-1.25, 1.25]:
		for z: float in [-0.4, 0.4]:
			_cylinder(at+Vector3(x, 0, z), 0.055, 0.08, 0.9, "mahogany")
	_solid(at+Vector3(-1.45, 0, -0.6), at+Vector3(1.45, 0.99, 0.6), "ReadingTable")

func _chair(at: Vector3, yaw: float) -> void:
	var holder := _group(at, yaw)
	_child_box(holder, Vector3(0, 0.48, 0), Vector3(0.55, 0.13, 0.55), "green_velvet")
	_child_box(holder, Vector3(0, 0.93, -0.25), Vector3(0.55, 0.8, 0.1), "mahogany")
	for x: float in [-0.22, 0.22]:
		for z: float in [-0.22, 0.22]:
			_child_cylinder(holder, Vector3(x, 0.225, z), 0.025, 0.45, "mahogany")
	_solid(at+Vector3(-0.3, 0, -0.3), at+Vector3(0.3, 1.35, 0.3), "Chair")
