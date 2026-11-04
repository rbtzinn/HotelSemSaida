@tool
class_name MaintenanceRoom3D
extends HotelBuilder3D
## Sala de manutenção sob a despensa, com corredor de serviço para a Biblioteca.
func _build_room() -> void:
	_part(Vector3(-0.3,-0.25,-0.3),Vector3(9.3,0,9.3),"stone")
	_solid(Vector3(-0.3,-0.25,-0.3),Vector3(9.3,0,9.3),"Floor")
	for x: float in [-0.15,9.15]:
		_block(Vector3(x,1.8,4.5),Vector3(0.3,3.6,9.6),"plaster_cream")
		_solid(Vector3(x-0.15,0,-0.3),Vector3(x+0.15,3.6,9.3),"Wall")
	for z: float in [-0.15,9.15]:
		_block(Vector3(4.5,1.8,z),Vector3(9.6,3.6,0.3),"plaster_cream")
		_solid(Vector3(-0.3,0,z-0.15),Vector3(9.3,3.6,z+0.15),"Wall")
	_build_ceiling_hatch()
	for x: float in [1,4.5,8]:
		_block(Vector3(x,3.42,4.5),Vector3(0.18,0.28,9),"cast_iron")
	for y: float in [2.5,2.8,3.05]:
		_cylinder(Vector3(0.25,y,0.1),0.06,0.06,8.6,"copper",Vector3(90,0,0),10)
		for z: float in [1,4,7]:
			_torus(Vector3(0.25,y,z),0.065,0.085,"iron",Vector3(90,0,0))
	_part(Vector3(4.8,0.78,0.25),Vector3(8,0.9,1.15),"oak")
	for x: float in [5,7.8]:
		_block(Vector3(x,0.4,0.7),Vector3(0.1,0.8,0.8),"iron")
	_solid(Vector3(4.8,0,0.25),Vector3(8,0.9,1.15),"Workbench")
	_label("MANUTENÇÃO",Vector3(6.4,2.3,0.04),0.16,Color("#C9973B"))
	# Painel elétrico, manômetro e ferramentas presas na parede.
	_block(Vector3(8.92,1.6,6.1),Vector3(0.08,1.2,0.8),"iron")
	for i in 4:
		_block(Vector3(8.85,1.22+i*0.23,6.1),Vector3(0.04,0.08,0.45),"brass")
	_cylinder(Vector3(8.75,2.3,6.1),0.18,0.18,0.06,"brass",Vector3(0,0,90))
	_cylinder(Vector3(8.7,2.3,6.1),0.15,0.15,0.02,"ivory",Vector3(0,0,90))
	_block(Vector3(8.65,2.34,6.1),Vector3(0.02,0.1,0.01),"iron",Vector3(20,0,0))
	for z: float in [2.8,5.0]:
		_torus(Vector3(0.4,2.8,z),0.15,0.18,"iron",Vector3(0,0,90))
		for angle: float in [0,60,120]:
			_block(Vector3(0.4,2.8,z),Vector3(0.025,0.3,0.025),"iron",Vector3(angle,0,0))
	for i in 5:
		var x := 5.2+i*0.5
		_block(Vector3(x,1.65,0.06),Vector3(0.04,0.33,0.025),"iron")
		_torus(Vector3(x,1.86,0.08),0.035,0.05,"iron",Vector3(90,0,0))
	# Armários de ferramentas e caixas; a chave fica na bancada livre.
	for x: float in [1.5,3.1]:
		_block(Vector3(x,1.05,0.45),Vector3(1.3,2.1,0.7),"iron")
		_solid(Vector3(x-0.65,0,0.1),Vector3(x+0.65,2.1,0.8),"Locker")
		for y: float in [0.4,1.7]:
			_block(Vector3(x,y,0.82),Vector3(0.9,0.04,0.03),"brass")
		_sphere(Vector3(x+0.35,1,0.85),0.035,"brass")
	for i in 6:
		var at := Vector3(7.8,0.22+(i%2)*0.46,3.0+(i/2)*0.7)
		_block(at,Vector3(0.8,0.44,0.6),"plank",Vector3(0,_random(i)*6,0))
	_solid(Vector3(7.3,0,2.6),Vector3(8.3,0.9,5),"Crates")
	# Escada de acesso à Biblioteca, porta usada com E no patamar inferior.
	for i in 6:
		_block(Vector3(4.5,0.07+i*0.14,8.1+i*0.14),Vector3(1.6,0.14,0.3),"stone")
	_block(Vector3(4.5,1.45,8.95),Vector3(1.6,2.7,0.08),"iron")
	_label("BIBLIOTECA — SERVIÇO",Vector3(4.5,2.95,8.9),0.1,Color("#C9973B"),180)
	for x: float in [3.6,5.4]:
		_block(Vector3(x,1.45,8.9),Vector3(0.12,2.9,0.12),"brass")

	_solid(Vector3(3.65,0,7.95),Vector3(5.35,0.84,9),"ServiceStairs")
	# Poço de descida e escada de retorno à despensa.
	for x: float in [1.2,1.9]:
		_cylinder(Vector3(x,0,7.2),0.035,0.035,4.25,"iron")
	for i in 15:
		_cylinder(Vector3(1.2,0.2+i*0.28,7.2),0.022,0.022,0.7,"iron",Vector3(0,0,-90),8)
	if present:
		for i in 14:
			_block(Vector3(0.6+_random(i)*2,0.08,3+_random(i,3)*3),Vector3(0.25,0.12,0.4),"rubble",Vector3(0,_random(i,5)*170,10))
		_omni(Vector3(4.5,2.8,4),Color("#6A7E96"),0.55,11)
		_part(Vector3(0.5,0.01,4.2),Vector3(2.5,0.018,5.5),"dark")
	else:
		_omni(Vector3(4.5,3.0,4),Color("#F2D49B"),1.6,11)
	_cylinder(Vector3(4.5,3.2,4),0.18,0.11,0.2,"iron")
	_sphere(Vector3(4.5,3.15,4),0.08,"bulb")


## Vão real sobre a escada: a laje termina nas bordas, em vez de tapar a subida.
func _build_ceiling_hatch() -> void:
	var opening := Rect2(1.0,6.7,1.1,1.2)
	for rect: Rect2 in [Rect2(0,0,9,opening.position.y),Rect2(0,opening.end.y,9,9-opening.end.y),Rect2(0,opening.position.y,opening.position.x,opening.size.y),Rect2(opening.end.x,opening.position.y,9-opening.end.x,opening.size.y)]:
		var start := Vector3(rect.position.x,3.6,rect.position.y)
		var end := Vector3(rect.end.x,3.8,rect.end.y)
		_part(start,end,"stone")
		_solid(start,end,"CeilingAroundHatch")
	# Madeira do piso da despensa vista pela abertura e o pequeno poço de ligação.
	for x: float in [0.93,2.17]:
		_block(Vector3(x,3.7,7.3),Vector3(0.14,0.28,1.48),"oak")
		_block(Vector3(x,4.1,7.3),Vector3(0.1,0.6,1.4),"plank")
	for z: float in [6.63,7.97]:
		_block(Vector3(1.55,3.7,z),Vector3(1.35,0.28,0.14),"oak")
		_block(Vector3(1.55,4.1,z),Vector3(1.35,0.6,0.1),"plank")
	# Tampa aberta apoiada ao lado do vão. A madeira está lascada no presente.
	var lid := _group(Vector3(2.18,3.81,7.3),0)
	lid.rotation_degrees.z = 75
	for i in 5:
		_child_box(lid,Vector3(0.52,0,-0.48+i*0.24),Vector3(1.04,0.055,0.22),"plank" if present else "oak")
	for x: float in [0.12,0.85]:
		_child_box(lid,Vector3(x,-0.04,0),Vector3(0.07,0.035,1.2),"iron")
	if present:
		for i in 5:
			_block(Vector3(1.05+i*0.2,3.78,6.77),Vector3(0.12,0.06,0.28),"plank",Vector3(12+i*3,0,0))
	# A câmara superior permanece escura, sem iluminar artificialmente a saída.
	_part(Vector3(0.9,4.6,6.6),Vector3(2.2,4.65,8),"dark")
