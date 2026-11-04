@tool
extends HotelBuilder3D
## Galeria lateral da bacia. As duas rampas ligam a soleira seca à oficina.
const ORIGIN := Vector3(15,0,4.6)
const WIDTH := 4.4
const END := 17.0
const LOWER_FLOOR := -1.6
const PRESSURE := "caldeiras.pressao.etapa"
const DRAINS := "caldeiras.drenagem.ramais"
const OUTLETS := ["I", "II", "III"]
const RETURN_LINE := 2
const DISCHARGE_LINES := 5
const BRASS_INK := Color("#ECD09A")
const INSPECTIONS := [
	"O tubo entra inteiro no muro de descarga. O lodo forma um leque do lado de fora da boca.",
	"O tubo se partiu antes de entrar no muro. A água que sai pela fenda escorre de volta para a galeria.",
	"Há uma faixa limpa no fundo do tubo. Do outro lado da parede vem o ruído da queda."
]

var _handles: Array[Node3D] = []
var _gate: StaticBody3D
var _water: MeshInstance3D
var _float: MeshInstance3D
var _motion: Tween


func _build_room() -> void:
	_slab(Vector3(0,-0.25,0), Vector3(5,0,WIDTH), "stone")
	_ramp(5,0,8.2,LOWER_FLOOR)
	_slab(Vector3(8.2,LOWER_FLOOR-0.25,0), Vector3(10.2,LOWER_FLOOR,WIDTH), "stone")
	_ramp(10.2,LOWER_FLOOR,13.4,0)
	_slab(Vector3(13.4,-0.25,0), Vector3(END,0,WIDTH), "stone")
	for z: float in [-0.20, WIDTH]:
		_slab(Vector3(0,-1.9,z), Vector3(END,3.2,z+0.20), "plaster_cream")
	_slab(Vector3(END,-0.25,0), Vector3(END+0.2,3.2,WIDTH), "stone")
	_slab(Vector3(0,3.2,0), Vector3(END,3.4,WIDTH), "stone")
	# Nervuras, luzes de serviço e linhas de cheia nas paredes de alvenaria.
	for x: float in [1.1, 4.8, 9.2, 13.55, 16.2]:
		_block(Vector3(x,3.04,WIDTH/2), Vector3(0.17,0.26,WIDTH), "cast_iron")
		_cylinder(Vector3(x,2.77,WIDTH/2), 0.12, 0.08, 0.15, "brass")
		_sphere(Vector3(x,2.73,WIDTH/2), 0.08, "bulb")
		if not present:
			_omni(Vector3(x,2.52,WIDTH/2), Color("#FFD397"), 1.45, 6.6)
	if present:
		for x: float in [2.3, 9.2, 15.3]:
			_block(Vector3(x,2.42,WIDTH-0.05), Vector3(1.25,0.54,0.08), "night")
			for i in 5:
				_block(Vector3(x-0.54+i*0.27,2.42,WIDTH-0.10), Vector3(0.04,0.54,0.05), "iron")
			_omni(Vector3(x,2.15,WIDTH-0.45), Color("#91B3C8"), 1.05, 6.5)
		for y: float in [-0.40, -0.32]:
			_block(Vector3(9.2,y,WIDTH-0.013), Vector3(7.2,0.025,0.022), "rubble")
	# Canaletas da grade acionada pela boia.
	for z: float in [0.11, WIDTH-0.11]:
		_block(Vector3(5.12,1.52,z), Vector3(0.26,3.25,0.22), "cast_iron")
	_block(Vector3(5.12,3.01,WIDTH/2), Vector3(0.27,0.24,WIDTH), "iron")
	# Poço da boia: a haste e a escala descem até o fundo do canal.
	_cylinder(Vector3(8.65,LOWER_FLOOR,0.24),0.028,0.028,3.72,"brass")
	_block(Vector3(8.65,2.15,0.14),Vector3(0.32,0.08,0.28),"iron")
	_block(Vector3(8.35,-0.53,0.055),Vector3(0.16,2.02,0.11),"enamel")
	for i in 9:
		_block(Vector3(8.35,-1.44+i*0.22,0.114),Vector3(0.11 if i%2 == 0 else 0.065,0.026,0.012),"cast_iron")
	_solid(Vector3(8.18,LOWER_FLOOR,0),Vector3(8.96,2.18,0.41),"FloatWell")
	for x: float in [8.20,8.94]:
		_cylinder(Vector3(x,LOWER_FLOOR,0.40),0.024,0.024,3.78,"iron")
	for y: float in [-1.32,0.66,2.16]:
		_block(Vector3(8.57,y,0.40),Vector3(0.77,0.035,0.035),"brass")
	_label("OFICINA", Vector3(END-0.03,2.22,2.24), 0.19, BRASS_INK, -90)
	_slab(Vector3(15.42,0,1.14), Vector3(16.6,0.88,3.22), "cast_iron")
	_block(Vector3(16.01,0.94,2.18), Vector3(1.3,0.12,2.2), "oak")
	# Haste protegida até o outro lado da galeria. Continua na sala das caldeiras.
	_cylinder(Vector3(0,2.85,4.12),0.047,0.047,16.12,"brass",Vector3(0,0,-90))
	_cylinder(Vector3(16.12,2.85,2.932),0.047,0.047,1.188,"brass",Vector3(90,0,0))
	_cylinder(Vector3(16.12,1.41,2.932),0.047,0.047,1.44,"brass")
	_cylinder(Vector3(15.95,1.41,2.932),0.047,0.047,0.17,"brass",Vector3(0,0,-90))
	for x: float in [0.45,4.8,9.2,13.55,16.12]:
		_block(Vector3(x,2.85,4.25),Vector3(0.085,0.14,0.30),"cast_iron")
	_block(Vector3(15.64,1.010,2.22), Vector3(0.40,0.02,0.50), "paper")
	if present:
		# A mochila mencionada no caderno ficou encostada ao pé da bancada.
		_sphere(Vector3(16.05,0.32,0.90),0.32,"green_velvet",Vector3(1.1,1,0.62))
		_block(Vector3(16.05,0.42,0.72),Vector3(0.43,0.24,0.09),"tarp",Vector3(-9,0,0))
		for x: float in [15.92,16.18]:
			_block(Vector3(x,0.29,0.69),Vector3(0.045,0.28,0.04),"dark_wood")
			_block(Vector3(x,0.30,0.66),Vector3(0.065,0.045,0.025),"brass")
		_solid(Vector3(15.73,0,0.66),Vector3(16.37,0.56,1.10),"Backpack")
	for i in OUTLETS.size():
		_build_outlet(i)
	_block(Vector3(2.35,2.40,0.06),Vector3(3.15,0.38,0.12),"cast_iron")
	_label("COLETOR DE ESGOTAMENTO",Vector3(2.35,2.40,0.128),0.14,BRASS_INK)


func _slab(start: Vector3, end: Vector3, role: String) -> void:
	_part(start,end,role)
	_solid(start,end)


func _ramp(x0: float, y0: float, x1: float, y1: float) -> void:
	var slope := Vector2(x1-x0,y1-y0)
	var normal := Vector3(-slope.y,slope.x,0).normalized()
	var center := Vector3((x0+x1)/2,(y0+y1)/2,WIDTH/2) - normal*0.1
	var size := Vector3(slope.length(),0.2,WIDTH)
	_block(center,size,"stone",Vector3(0,0,rad_to_deg(slope.angle())))
	var floor_body := _solid(center-size/2,center+size/2,"Ramp")
	floor_body.rotation.z = slope.angle()


func _build_outlet(index: int) -> void:
	var x := 0.90 + 1.45*index
	var split := present and index == 1
	# Os tubos saem do piso, dobram e atravessam o muro de descarga.
	_cylinder(Vector3(x,0,0.44), 0.14,0.14,1.38,"copper")
	_sphere(Vector3(x,1.38,0.44),0.153,"brass")
	_cylinder(Vector3(x,1.38,0.44),0.13,0.13,0.18 if split else 0.44,"copper",Vector3(-90,0,0))
	_cylinder(Vector3(x,1.38,0),0.22,0.22,0.09,"iron",Vector3(90,0,0))
	if split:
		_torus(Vector3(x,1.38,0.25),0.105,0.14,"iron",Vector3(90,0,0))
		_block(Vector3(x,0.025,0.83),Vector3(0.50,0.018,0.78),"dark")
	_cylinder(Vector3(x,1.04,0.47),0.066,0.066,0.20,"brass",Vector3(90,0,0))
	_block(Vector3(x,1.89,0.07),Vector3(0.58,0.30,0.13),"cast_iron")
	_label(OUTLETS[index],Vector3(x,1.89,0.145),0.17,BRASS_INK)


## As partes móveis entram depois da união das malhas estáticas da galeria.
func install(room: ChapterRoom3D, water_material: Material) -> void:
	for i in OUTLETS.size():
		var at := Vector3(0.90+1.45*i,1.04,0.67)
		var handle := Node3D.new()
		handle.position = at
		add_child(handle)
		room.box(handle,Vector3(0,0.14,0),Vector3(0.065,0.40,0.08),"brass",present)
		room.box(handle,Vector3(0,0.32,0),Vector3(0.16,0.08,0.11),"enamel",present)
		_handles.append(handle)
		if present:
			room.area(preload("res://scripts/interaction3d/note_interactable_3d.gd"), self,
				"Saida%d" % i, at+Vector3(0,0.32,-0.12),Vector3(0.76,1.30,0.46), {
					"title": "Descarga · Ramal " + OUTLETS[i], "text": INSPECTIONS[i],
					"available_in": 1, "prompt_text": "Inspecionar ramal " + OUTLETS[i]
				})
		else:
			var control := room.area(preload("res://scripts/interaction3d/interactable_3d.gd"), self,
				"Ralo%d" % i, at,Vector3(0.77,0.80,0.30), {
					"available_in": 0, "prompt_text": "Manobrar ralo " + OUTLETS[i]
				})
			control.interacted.connect(_toggle.bind(i))
	_gate = StaticBody3D.new()
	_gate.name = "GradeDaBoia"
	_gate.position = Vector3(5.12,0,WIDTH/2)
	add_child(_gate)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.14,2.84,WIDTH)
	collision.shape = shape
	collision.position.y = 1.35
	_gate.add_child(collision)
	_float = room.box(self,Vector3(8.65,LOWER_FLOOR+0.08,0.24),Vector3(0.34,0.16,0.27),"copper",present)
	for i in 14:
		room.box(_gate,Vector3(0,1.35,-2.08+i*0.32),Vector3(0.07,2.84,0.05),"iron",present)
	for y: float in [0.13,1.55,2.65]:
		room.box(_gate,Vector3(0,y,0),Vector3(0.105,0.075,WIDTH-0.08),"brass",present)
	if not present:
		room.box(self,Vector3(4.43,1.38,0.065),Vector3(0.58,0.72,0.13),"enamel",false)
		var plate := room.label(self,"DESCARGA\nDUPLA",Vector3(4.43,1.38,0.14),28)
		plate.modulate = Color("#32261C")
		room.area(preload("res://scripts/interaction3d/note_interactable_3d.gd"),self,
			"PlacaDaBoia",plate.position,Vector3(0.62,0.76,0.18),{
				"available_in": 0, "prompt_text": "Ler placa da boia", "title": "Coletor · Descarga dupla",
				"text": "Vazão de serviço: duas descargas livres para o exterior. Isolar qualquer ramal que devolva água ao canal.\n\nCom o canal em nível baixo, a boia recolhe a grade e a cunha retém os registros."
			})
	if present:
		_water = MeshInstance3D.new()
		_water.name = "AguaDoCanal"
		var plane := PlaneMesh.new()
		plane.size = Vector2(8.4,WIDTH)
		_water.mesh = plane
		_water.material_override = water_material
		_water.position = Vector3(9.2,0,WIDTH/2)
		_water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_water)
		var card := room.area(preload("res://scripts/interaction3d/note_interactable_3d.gd"), self,
			"FichaDaOficina",Vector3(15.64,1.05,2.22),Vector3(0.54,0.18,0.63),{
				"available_in": 1, "prompt_text": "Ler ficha da bancada", "title": "Oficina · Transmissão da fornalha",
				"text": "2003. É a bancada da foto de Marta. Contei os três cortes na quina com a ponta do dedo.\n\nNa parede, a crosta de ferrugem acaba na altura do meu peito. Abaixo dela o ferro virou farelo. Acima, os ganchos ainda têm óleo.\n\nA manivela tem o mesmo número da portinhola que passei lá atrás. F-2. Vou deixar a mochila aqui.\n\nTomás Reis"
			})
		card.interacted.connect(func(_by: FirstPersonMotor) -> void: WorldState.set_flag("caldeiras.oficina.visitada"))
	_refresh(false)
	WorldState.flag_changed.connect(_on_flag_changed)


func _toggle(_by: FirstPersonMotor, index: int) -> void:
	var mask := int(WorldState.get_flag(DRAINS,0))
	if int(WorldState.get_flag(PRESSURE,0)) != 3:
		get_tree().call_group("hud","show_message","A trava hidráulica está sem pressão.")
	elif mask == DISCHARGE_LINES:
		get_tree().call_group("hud","show_message","A cunha de retenção está assentada.")
	else:
		mask ^= 1 << index
		WorldState.set_flag(DRAINS,mask)
		var message := "O ralo fecha."
		if mask == DISCHARGE_LINES:
			message = "O escoamento enche os dois ramais. A cunha cai no encaixe."
		elif mask & (1 << index):
			message = "O ralo abre."
		get_tree().call_group("hud","show_message",message)


func _on_flag_changed(key: String, _value: Variant) -> void:
	if key == PRESSURE or key == DRAINS:
		_refresh(true)


func _refresh(animate: bool) -> void:
	var stage := int(WorldState.get_flag(PRESSURE,0))
	var mask := int(WorldState.get_flag(DRAINS,0)) if stage == 3 else 0
	if _motion:
		_motion.kill()
	if animate:
		_motion = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	for i in _handles.size():
		_set_pose(_handles[i],"rotation_degrees:z",-90.0 if mask & (1 << i) else 0.0,animate)
	var clear := mask == DISCHARGE_LINES
	_set_pose(_gate,"position:y",2.96 if clear or not present else 0.0,animate)
	if present:
		var level := -0.16
		if stage == -1 or mask & RETURN_LINE:
			level = -0.06
		elif clear:
			level = LOWER_FLOOR + 0.025
		elif mask != 0:
			level = -0.78
		_set_pose(_water,"position:y",level,animate)
		_set_pose(_float,"position:y",maxf(LOWER_FLOOR+0.08,level+0.035),animate)


func _set_pose(part: Node3D, key: NodePath, value: float, animate: bool) -> void:
	if animate:
		_motion.tween_property(part,key,value,0.55)
	else:
		part.set_indexed(key,value)
