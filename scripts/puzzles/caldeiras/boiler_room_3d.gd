@tool
extends HotelBuilder3D
## Galeria dos foguistas. A bacia fica abaixo da passarela seca, nas duas épocas.

const GOLD := Color("#F1CD86")
const VALVES := ["RETORNO", "VAPOR", "PURGA"]
const FIRST_WHEEL := Vector3(6,1.4,0.61)
const VALVE_SPACING := 1.45
const FEED_PIVOT := Vector3(10.8,1.18,0.44)
const DIAL := Vector3(10.8,1.98,0.36)
const SUPPLY_X := 3.95
const RETURN_X := 4.47
const SUMP := Rect2(9.8, 4.2, 3.6, 4.8)
const GALLERY_DOOR := Vector2(5.8,7.8)


func _build_room() -> void:
	var end := SUMP.end
	_masonry(Vector3(0,-0.25,0), Vector3(15,0,SUMP.position.y), "stone")
	_masonry(Vector3(0,-0.25,end.y), Vector3(15,0,12), "stone")
	_masonry(Vector3(0,-0.25,SUMP.position.y), Vector3(SUMP.position.x,0,end.y), "stone")
	_masonry(Vector3(end.x,-0.25,SUMP.position.y), Vector3(15,0,end.y), "stone")
	_masonry(Vector3(0,0,-0.24), Vector3(15,5.4,0), "plaster_cream")
	_masonry(Vector3(0,0,12), Vector3(15,5.4,12.24), "plaster_cream")
	_masonry(Vector3(-0.24,0,0), Vector3(0,5.4,12), "plaster_cream")
	_masonry(Vector3(15,0,0), Vector3(15.24,5.4,GALLERY_DOOR.x), "plaster_cream")
	_masonry(Vector3(15,0,GALLERY_DOOR.y), Vector3(15.24,5.4,12), "plaster_cream")
	_masonry(Vector3(15,2.6,GALLERY_DOOR.x), Vector3(15.24,5.4,GALLERY_DOOR.y), "plaster_cream")
	for z: float in [GALLERY_DOOR.x,GALLERY_DOOR.y]:
		_block(Vector3(14.98,1.3,z),Vector3(0.14,2.6,0.11),"cast_iron")
	_block(Vector3(14.98,2.63,6.8),Vector3(0.15,0.10,2.14),"iron")
	_block(Vector3(14.88,2.85,6.8),Vector3(0.20,0.30,1.31),"lacquer")
	_label("DRENAGEM",Vector3(14.77,2.85,6.8),0.12,GOLD,-90)
	_masonry(Vector3(0,5.4,0), Vector3(15,5.6,12), "ceiling")
	for z: float in [1.5, 5.8, 10.3]:
		_block(Vector3(7.5,5.12,z), Vector3(15,0.35,0.13), "cast_iron")
		_block(Vector3(7.5,4.92,z), Vector3(15,0.07,0.31), "iron")
		_window(z)
		_cylinder(Vector3(6.4,4.35,z), 0.018, 0.018, 0.54, "iron")
		_cylinder(Vector3(6.4,4.18,z), 0.24, 0.06, 0.17, "enamel")
		_sphere(Vector3(6.4,4.16,z), 0.085, "bulb")
		if not present:
			_omni(Vector3(6.4,3.88,z), Color("#FFCE8B"), 2.5, 10)
	for z: float in [0.95, 6.15]:
		_furnace(z)
	# Comando por haste da F-2, alinhado à parede sul da galeria de drenagem.
	_pipe_run([Vector3(15,2.85,8.72),Vector3(3.54,2.85,8.72),
		Vector3(3.54,2.85,8.15),Vector3(3.54,1.85,8.15)],0.047)
	_build_sump()
	_build_manifold()
	# Dutos de vapor suspensos, com flanges e tirantes em cada viga.
	for x: float in [SUPPLY_X, RETURN_X]:
		_cylinder(Vector3(x,4.38,0), 0.12, 0.12, 12, "copper", Vector3(90,0,0))
		for z: float in [1.5, 5.8, 10.3]:
			_torus(Vector3(x,4.38,z), 0.115, 0.155, "brass", Vector3(90,0,0))
			_cylinder(Vector3(x,4.51,z), 0.022, 0.022, 0.4, "iron")
	# Dois ramais em alturas diferentes permitem cruzar a frente do painel.
	_pipe_run([Vector3(SUPPLY_X,4.38,0.4), Vector3(SUPPLY_X,3.4,0.4),
		Vector3(5.22,3.4,0.4), Vector3(5.22,0.66,0.4)], 0.10)
	_pipe_run([Vector3(RETURN_X,4.38,0.4), Vector3(RETURN_X,3.85,0.4),
		Vector3(11.52,3.85,0.4), Vector3(11.52,0.66,0.4)], 0.10)
	_block(Vector3(6,1.22,11.94), Vector3(1.6,2.44,0.12), "dark_wood")
	for x: float in [5.15, 6.85]:
		_block(Vector3(x,1.3,11.86), Vector3(0.12,2.6,0.14), "iron")
	_block(Vector3(6,2.56,11.86), Vector3(1.82,0.12,0.14), "iron")
	_sphere(Vector3(6.59,1.08,11.83), 0.055, "brass")
	_label("ARQUIVO", Vector3(6,1.86,11.87), 0.11, GOLD, 180)
	if present:
		_omni(Vector3(7.6,3.8,4), Color("#8BA8BE"), 0.95, 14)


func _masonry(start: Vector3, end: Vector3, role: String) -> void:
	_part(start, end, role)
	_solid(start, end)


func _furnace(z: float) -> void:
	var front := z + 3.1
	_masonry(Vector3(0.85,0,z-0.05), Vector3(3.45,0.52,front+0.08), "stone")
	_cylinder(Vector3(2.15,1.47,z), 1.08, 1.08, 3.1, "cast_iron", Vector3(90,0,0), 28)
	var shell := _solid_cylinder(Vector3.ZERO, 1.08, 3.1, "Boiler")
	shell.rotation.x = PI/2
	shell.position = Vector3(2.15,1.47,z+1.55)
	var hatch := _solid_cylinder(Vector3.ZERO, 0.62, 0.11, "Firebox")
	hatch.rotation.x = PI/2
	hatch.position = Vector3(2.15,1.4,front+0.055)
	for header_x: float in [SUPPLY_X, RETURN_X]:
		var port_z := z + (1.30 if header_x == SUPPLY_X else 2.36)
		var elbow_y := 3.12 if header_x == SUPPLY_X else 3.52
		_pipe_run([Vector3(2.45,2.47,port_z), Vector3(2.45,elbow_y,port_z),
			Vector3(header_x,elbow_y,port_z), Vector3(header_x,4.38,port_z)], 0.085)
	for offset: float in [0.12, 1.08, 2.12, 3.05]:
		_torus(Vector3(2.15,1.47,z+offset), 1.055, 1.105, "copper", Vector3(90,0,0))
	_cylinder(Vector3(2.15,2.48,z+0.5), 0.31, 0.31, 2.92, "iron")
	_torus(Vector3(2.15,2.74,z+0.5), 0.29, 0.35, "brass")
	_cylinder(Vector3(2.15,1.4,front), 0.62, 0.62, 0.075, "iron", Vector3(90,0,0))
	_torus(Vector3(2.15,1.4,front+0.08), 0.52, 0.62, "copper", Vector3(90,0,0))
	for i in 5:
		var x := 2.15 + (i - 2) * 0.145
		_block(Vector3(x,1.4,front+0.081), Vector3(0.073,0.54-abs(i-2)*0.1,0.008), "dark" if present else "street")
	for i in 10:
		var a := TAU * i / 10.0
		_sphere(Vector3(2.15+cos(a)*0.9,1.47+sin(a)*0.9,front+0.015), 0.045, "brass")
	if not present:
		_omni(Vector3(2.15,1.25,front+0.45), Color("#E78242"), 1.6, 4)


## Cada tubo termina no centro da conexão seguinte.
func _pipe_run(points: PackedVector3Array, radius: float) -> void:
	for i in range(1, points.size()):
		var start := points[i-1]
		var end := points[i]
		var tube := _cylinder(Vector3.ZERO, radius, radius, start.distance_to(end), "copper")
		tube.position = (start+end)*0.5
		tube.quaternion = Quaternion(Vector3.UP, start.direction_to(end))
		if i < points.size()-1:
			_sphere(end, radius*1.16, "brass")


func _window(z: float) -> void:
	_block(Vector3(14.95,3.6,z), Vector3(0.07,1.7,1.85), "night")
	for offset: float in [-0.94, -0.32, 0.32, 0.94]:
		_block(Vector3(14.89,3.6,z+offset), Vector3(0.09,1.8,0.055), "iron")
	for y: float in [2.72, 3.54, 4.48]:
		_block(Vector3(14.85,y,z), Vector3(0.12,0.07,1.98), "iron")
	if present:
		_spot(Vector3(14.6,4,z), Vector3(10.5,0,z-0.5), Color("#A4BFD8"), 3.2, 12, 36)


func _build_sump() -> void:
	var start := SUMP.position
	var end := SUMP.end
	var mid := SUMP.get_center()
	_masonry(Vector3(start.x,-1.65,start.y), Vector3(end.x,-1.55,end.y), "stone")
	for x: float in [start.x, end.x]:
		var outer_x := x - 0.12 if x == start.x else x + 0.12
		_masonry(Vector3(x,-1.55,start.y), Vector3(outer_x,-0.25,end.y), "stone")
		_block(Vector3(x,0.94,mid.y), Vector3(0.07,0.075,SUMP.size.y-0.08), "brass")
		_block(Vector3(x,0.45,mid.y), Vector3(0.045,0.055,SUMP.size.y-0.08), "iron")
		_solid(Vector3(x-0.06,0,start.y), Vector3(x+0.06,1.05,end.y), "Railing")
		for z: float in [start.y, mid.y, end.y]:
			_cylinder(Vector3(x,0,z), 0.05, 0.042, 0.98, "iron")
	for z: float in [start.y, end.y]:
		var outer_z := z - 0.12 if z == start.y else z + 0.12
		_masonry(Vector3(start.x,-1.55,z), Vector3(end.x,-0.25,outer_z), "stone")
		_block(Vector3(mid.x,0.94,z), Vector3(SUMP.size.x-0.08,0.075,0.07), "brass")
		_block(Vector3(mid.x,0.45,z), Vector3(SUMP.size.x-0.08,0.055,0.045), "iron")
		_solid(Vector3(start.x,0,z-0.06), Vector3(end.x,1.05,z+0.06), "Railing")
	# Gradil do ralo aparece sob a linha de água quando a pressão estabiliza.
	_block(Vector3(mid.x,-1.37,mid.y), Vector3(1.44,0.36,1.44), "iron")
	for i in 8:
		_block(Vector3(mid.x-0.6+i*0.17,-1.16,mid.y), Vector3(0.07,0.06,1.25), "brass")


func _build_manifold() -> void:
	_masonry(Vector3(4.98,0,0), Vector3(11.82,2.65,0.25), "cast_iron")
	_cylinder(Vector3(5.22,0.66,0.4), 0.13, 0.13, 6.3, "copper", Vector3(0,0,-90))
	for i in VALVES.size():
		var x := FIRST_WHEEL.x + VALVE_SPACING * i
		_cylinder(Vector3(x,0.66,0.4), 0.08, 0.08, 1.06, "copper")
		_cylinder(Vector3(x,FIRST_WHEEL.y,0.37), 0.105, 0.105, FIRST_WHEEL.z-0.37, "brass", Vector3(90,0,0))
		_block(Vector3(x,1.99,0.28), Vector3(1.04,0.27,0.045), "enamel")
		_label(VALVES[i], Vector3(x,1.99,0.31), 0.12, Color("#302921"))
	# Manômetro principal e suas marcas de escala.
	_cylinder(Vector3(10.8,1.98,0.24), 0.38, 0.38, 0.1, "brass", Vector3(90,0,0), 32)
	_cylinder(Vector3(10.8,1.98,0.34), 0.33, 0.33, 0.02, "enamel", Vector3(90,0,0), 32)
	for i in 9:
		var a := deg_to_rad(-120.0 + 30*i)
		_block(Vector3(10.8+0.27*sin(a),1.98+0.27*cos(a),0.366), Vector3(0.012,0.06,0.009), "iron", Vector3(0,0,-rad_to_deg(a)))
	# Tomada de pressão do coletor, com eixo para o registro e pino do ponteiro.
	_cylinder(Vector3(DIAL.x,0.66,0.31), 0.068, 0.068, 0.98, "copper")
	_cylinder(Vector3(FEED_PIVOT.x,FEED_PIVOT.y,0.31), 0.07, 0.07, FEED_PIVOT.z-0.31, "brass", Vector3(90,0,0))
	_cylinder(DIAL, 0.032, 0.032, 0.038, "brass", Vector3(90,0,0))
	_label("ALIMENTAÇÃO", Vector3(10.83,0.92,0.49), 0.095, GOLD)
	_block(Vector3(10.83,0.92,0.39), Vector3(0.92,0.16,0.18), "lacquer")
	_block(Vector3(7.45,3,0.055), Vector3(3.25,0.43,0.09), "lacquer")
	for x: float in [5.94, 8.96]:
		_sphere(Vector3(x,3,0.10), 0.032, "brass")
	_label("CASA DAS CALDEIRAS", Vector3(7.45,3,0.112), 0.21, GOLD)
