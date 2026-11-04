extends HotelBuilder3D
## Lado de serviço da F-2. O eixo X local percorre o casco e Z aponta para o corredor.
const GALLERY := preload("res://scripts/puzzles/caldeiras/drain_gallery_3d.gd")
const WORKSHOP := preload("res://scripts/puzzles/caldeiras/workshop_gears_3d.gd")
const CONTROL := preload("res://scripts/interaction3d/interactable_3d.gd")
const NOTE := preload("res://scripts/interaction3d/note_interactable_3d.gd")
const SETTINGS := ["caldeiras.tiragem.admissao", "caldeiras.tiragem.chamine"]
const NAMES := ["Admissão", "Chaminé"]
const NUMERALS := ["I", "II", "III", "IV"]
const SEATS := [2, 1] # Entalhes contados a partir da articulação de cada haste.
const BOX_OPEN := "caldeiras.limpeza.aberta"
const COMPLETE := "caldeiras.concluida"
const DOOR_AT := Vector3(-0.88,-0.53,0.10)
const DOOR_SIZE := Vector3(0.78,0.60,0.04)
const INK := Color("#EAD5A0")

var _wheels: Array[Node3D] = []
var _door: StaticBody3D
var _wheel_motion: Array[Tween] = [null,null]

func _build_room() -> void:
	for i in SETTINGS.size():
		var at := _hub(i)
		_block(at+Vector3(0,0.035,-0.23),Vector3(0.77,0.82,0.24),"cast_iron")
		_solid(at+Vector3(-0.385,-0.375,-0.35),at+Vector3(0.385,0.445,-0.11),"DialPlate")
		_cylinder(at+Vector3(0,0,-0.12),0.06,0.06,0.13,"brass",Vector3(90,0,0))
		_torus(at,0.145,0.18,"copper",Vector3(90,0,0))
		_label(NAMES[i].to_upper(),at+Vector3(0,0.36,-0.103),0.075,INK)
		for n in NUMERALS.size():
			var axis := Vector3.UP.rotated(Vector3.BACK,_angle(n))
			_label(NUMERALS[n],at+axis*0.258+Vector3(0,0,-0.103),0.071,INK)
	# As articulações ficam em extremidades opostas. Os anéis gastos só aparecem hoje.
	if present:
		for i in SETTINGS.size():
			var y := 0.125 if i == 0 else -0.125
			_block(Vector3(0,y,-0.24),Vector3(0.64,0.115,0.033),"iron")
			var direction := 1.0 if i == 0 else -1.0
			_cylinder(Vector3(-direction*0.275,y,-0.23),0.05,0.048,0.038,"copper",Vector3(90,0,0))
			for n in NUMERALS.size():
				var mark := Vector3(direction*(-0.16+n*0.105),y,-0.217)
				_cylinder(mark,0.032,0.032,0.008,"dark",Vector3(90,0,0))
				if n == SEATS[i]:
					_torus(mark+Vector3(0,0,0.011),0.030,0.046,"ivory",Vector3(90,0,0))
	_build_cleanout()

func _build_cleanout() -> void:
	var back := DOOR_AT+Vector3(0,0,-0.67)
	_block(back,Vector3(0.88,0.70,0.12),"iron")
	_solid(back-Vector3(0.44,0.35,0.06),back+Vector3(0.44,0.35,0.06),"CleanoutBack")
	for x: float in [-0.421,0.421]:
		var jamb := DOOR_AT+Vector3(x,0,-0.33)
		_block(jamb,Vector3(0.07,0.70,0.62),"iron")
		_solid(jamb-Vector3(0.035,0.35,0.31),jamb+Vector3(0.035,0.35,0.31),"CleanoutSide")
		_block(DOOR_AT+Vector3(x,0.32,0),Vector3(0.047,1.29,0.076),"brass")
	for y: float in [-0.326,0.326]:
		var edge := DOOR_AT+Vector3(0,y,-0.33)
		_block(edge,Vector3(0.80,0.06,0.62),"cast_iron")
		_solid(edge-Vector3(0.40,0.03,0.31),edge+Vector3(0.40,0.03,0.31),"CleanoutLip")
	if present:
		var base := DOOR_AT+Vector3(-0.14,-0.20,-0.22)
		_cylinder(base-Vector3(0.18,0,0),0.062,0.062,0.24,"tarp",Vector3(0,0,-90))
		_cylinder(base+Vector3(0.06,0,0),0.062,0.095,0.10,"iron",Vector3(0,0,-90))
		_cylinder(base+Vector3(0.16,0,0),0.079,0.079,0.012,"enamel",Vector3(0,0,-90))
		_block(base+Vector3(-0.05,0.065,0),Vector3(0.054,0.015,0.029),"brass")
		var page := DOOR_AT+Vector3(0.19,-0.13,-0.26)
		_block(page,Vector3(0.235,0.29,0.025),"paper",Vector3(-12,0,-6))
		_label("T. REIS",page+Vector3(0,0.04,0.027),0.045,Color("#433423"))

func install(room: ChapterRoom3D) -> void:
	for i in SETTINGS.size():
		var wheel := Node3D.new()
		wheel.position = _hub(i)
		add_child(wheel)
		for spoke: float in [0,60,120]:
			room.box(wheel,Vector3.ZERO,Vector3(0.026,0.31,0.035),"brass",present).rotation_degrees.z = spoke
		room.box(wheel,Vector3(0,0.16,0.022),Vector3(0.037,0.091,0.03),"enamel",present)
		_wheels.append(wheel)
		_pose_wheel(i,false)
		if not present:
			var dial := room.area(CONTROL,self,"Regular%d" % i,wheel.position,Vector3(0.49,0.46,0.15),{
				"available_in":0,"prompt_text":"Regular " + NAMES[i].to_lower()
			})
			dial.interacted.connect(_turn_dial.bind(i))
	_door = StaticBody3D.new()
	_door.name = "TampaLimpeza"
	_door.position = DOOR_AT
	add_child(_door)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = DOOR_SIZE
	collision.shape = shape
	_door.add_child(collision)
	room.box(_door,Vector3.ZERO,DOOR_SIZE,"iron",present)
	room.box(_door,Vector3(0,-0.10,0.073),Vector3(0.27,0.046,0.042),"brass",present)
	for x: float in [-0.11,0.11]:
		room.box(_door,Vector3(x,-0.10,0.045),Vector3(0.041,0.046,0.06),"brass",present)
	room.label(_door,"F-2   LIMPEZA",Vector3(0,0.10,0.024),33)
	if present:
		var pull := room.area(CONTROL,_door,"Puxador",Vector3(0,0,0.073),Vector3(0.75,0.55,0.080),{
			"available_in":1,"done_flag":BOX_OPEN,"prompt_text":"Abrir caixa de limpeza"
		})
		pull.interacted.connect(_pull)
		var page := room.area(NOTE,self,"BilheteTomas",DOOR_AT+Vector3(0,-0.125,-0.20),Vector3(0.71,0.29,0.22),{
			"available_in":1,"required_flag":BOX_OPEN,"prompt_text":"Ler bilhete junto à lanterna",
			"title":"Última folha do caderno · Tomás Reis, 2003",
			"text":"Deixei a lanterna virada para a fresta. Da oficina dava para ver o risco no chão. Quando cheguei à mochila, a luz tinha apagado. Voltei tateando a haste. Do outro lado da chapa, alguém bateu o mesmo número de vezes que os meus passos.\n\nOntem voltei pela Biblioteca. Me ajoelhei diante do elevador do saguão. Aquilo preso debaixo da cabine era uma correia de máquina fotográfica. A fivela ainda brilhava.\n\nTomás"
		})
		page.interacted.connect(_read_last_page)
		if WorldState.is_set(BOX_OPEN):
			_door.position.y += 0.66
	WorldState.flag_changed.connect(_on_flag)

func _hub(i: int) -> Vector3:
	return Vector3(0.88+0.82*i,-0.005,-0.16)

func _angle(n: int) -> float:
	return deg_to_rad(81.0-54.0*n)

func _notch(i: int) -> int:
	return clampi(int(WorldState.get_flag(SETTINGS[i],0)),0,NUMERALS.size()-1)

func _turn_dial(by: FirstPersonMotor, i: int) -> void:
	if by.era != Era.Id.PAST_1923:
		return
	if int(WorldState.get_flag(GALLERY.PRESSURE,0)) != 3:
		_say("O pino hidráulico está caído. Falta pressão no coletor.")
		return
	if int(WorldState.get_flag(GALLERY.DRAINS,0)) != GALLERY.DISCHARGE_LINES:
		_say("A trava da drenagem segura os volantes.")
		return
	var next := (_notch(i)+1) % NUMERALS.size()
	WorldState.set_flag(SETTINGS[i],next)
	_say("%s · entalhe %s." % [NAMES[i],NUMERALS[next]])

func _pull(_by: FirstPersonMotor) -> void:
	if not WorldState.is_set(WORKSHOP.OPEN):
		_say("A portinhola de inspeção ainda está baixada sobre o ferrolho.")
	elif _notch(0) != SEATS[0] or _notch(1) != SEATS[1]:
		_say("A tampa levanta um dedo. Os pinos das hastes ainda prendem o ferrolho.")
	else:
		WorldState.set_flag(BOX_OPEN)
		_say("A tampa corre nas guias. Há uma lanterna entre as cinzas frias.")

func _read_last_page(_by: FirstPersonMotor) -> void:
	if not WorldState.is_set(COMPLETE):
		WorldState.set_flag(COMPLETE)
		_say("Casa das Caldeiras · Registro de Tomás encontrado.")

func _on_flag(key: String, _value: Variant) -> void:
	var i := SETTINGS.find(key)
	if i >= 0:
		_pose_wheel(i,is_visible_in_tree())
	elif present and key == BOX_OPEN and WorldState.is_set(BOX_OPEN):
		create_tween().set_trans(Tween.TRANS_SINE).tween_property(_door,"position:y",DOOR_AT.y+0.66,0.65)

func _pose_wheel(i: int, animate: bool) -> void:
	var angle := _angle(_notch(i))
	if _wheel_motion[i]:
		_wheel_motion[i].kill()
	if animate:
		_wheel_motion[i] = create_tween()
		_wheel_motion[i].tween_property(_wheels[i],"rotation:z",angle,0.22)
	else:
		_wheels[i].rotation.z = angle

func _say(message: String) -> void:
	get_tree().call_group("hud","show_message",message)
