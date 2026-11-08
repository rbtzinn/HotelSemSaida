extends ChapterRoom3D
## A posição da pressão é o estado salvo: -1 = ruptura, 0..2 = volantes já abertos, 3 = regime.
## A ordem só é conferida depois do terceiro volante: o ponteiro sobe a cada um, certo ou não,
## e só no fim a partida firma ou a união rompe. Sem retorno a cada passo, chutar custa caro.
const PLANT := preload("res://scripts/puzzles/caldeiras/boiler_room_3d.gd")
const GALLERY := preload("res://scripts/puzzles/caldeiras/drain_gallery_3d.gd")
const CONTROL := preload("res://scripts/interaction3d/interactable_3d.gd")
const NOTE := preload("res://scripts/interaction3d/note_interactable_3d.gd")
const DOOR := preload("res://scripts/interaction3d/door_3d.gd")
const PRESSURE := GALLERY.PRESSURE
const RUPTURE := -1
## Quais volantes já foram abertos nesta partida (bit = índice) e se algum saiu da ordem.
const OPENED := "caldeiras.pressao.abertos"
const MISTAKE := "caldeiras.pressao.erro"
const START_ORDER := [2, 0, 1]
const MARKS := ["Dois talhos paralelos", "Três talhos paralelos", "Um único talho"]

var _water: MeshInstance3D
var _wheels: Array[Node3D] = []
var _needles: Array[Node3D] = []
var _couplings: Array[Node3D] = []
var _feed_handles: Array[Node3D] = []
var _motion: Tween


func _ready() -> void:
	StoryTrigger.attach(self, "caldeiras.concluida", StoryCutscenes.boilers_end)
	for present: bool in [false, true]:
		var world := make_world(PLANT, present)
		area(DOOR, world, "ParaArquivo", Vector3(6, 1.22, 11.84), Vector3(1.6, 2.44, 0.22), {
			"target_scene": "res://scenes/rooms/biblioteca_3d.tscn",
			"target_spawn": "DasCaldeiras", "prompt_text": "Voltar ao arquivo"
		})
		for index in PLANT.VALVES.size():
			_build_valve(world, index, present)
		_build_instruments(world, present)
		if present:
			_build_water(world)
		var gallery := GALLERY.new()
		gallery.name = "Galeria"
		gallery.position = GALLERY.ORIGIN
		gallery.present = present
		world.add_child(gallery)
		gallery.install(self, _water.material_override if present else null)
		var workshop := preload("res://scripts/puzzles/caldeiras/workshop_gears_3d.gd").new()
		workshop.name = "Transmissao"
		gallery.add_child(workshop)
		workshop.install(self, world, present)
		var draft := preload("res://scripts/puzzles/caldeiras/furnace_draft_3d.gd").new()
		draft.name = "TiragemF2"
		draft.present = present
		draft.position = Vector3(3.70, 1.52, 8.15)
		draft.rotation.y = PI/2
		world.add_child(draft)
		draft.install(self)
	marker("DoArquivo", Vector3(6, 0, 10.65))
	_apply_pressure(_stage(), false)
	WorldState.flag_changed.connect(_on_flag_changed)
	super()


func _build_valve(world: Node3D, index: int, present: bool) -> void:
	var at: Vector3 = PLANT.FIRST_WHEEL + Vector3.RIGHT * PLANT.VALVE_SPACING * index
	var wheel := Node3D.new()
	wheel.position = at
	world.add_child(wheel)
	var rim := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.235
	ring.outer_radius = 0.29
	ring.rings = 24
	ring.ring_segments = 8
	rim.mesh = ring
	rim.rotation.x = PI/2
	rim.material_override = HotelMaterials.get_material("copper", present)
	wheel.add_child(rim)
	for angle: float in [0, 60, 120]:
		box(wheel, Vector3.ZERO, Vector3(0.035, 0.52, 0.045), "brass", present).rotation_degrees.z = angle
	box(wheel, Vector3(0, 0.24, 0.035), Vector3(0.072, 0.09, 0.065), "ivory", present)
	_wheels.append(wheel)
	var valve_name: String = PLANT.VALVES[index].capitalize()
	if present:
		var count := START_ORDER.find(index) + 1
		for i in count:
			var scratch := box(world, Vector3(at.x+(i-(count-1)*0.5)*0.075, 1.79, 0.251), Vector3(0.024, 0.10, 0.014), "ivory", true)
			scratch.rotation_degrees.z = -17
		area(NOTE, world, "Marca%d" % index, Vector3(at.x, 1.60, 0.45), Vector3(1.04, 1.10, 0.4), {
			"prompt_text": "Examinar " + valve_name.to_lower(), "available_in": 1,
			"title": "Coletor de partida · " + valve_name,
			"text": "%s no ferro, sob o esmalte descascado.\n\nA borda de cada corte tem a largura da ponta de um punção." % MARKS[index]
		})
	else:
		var control := area(CONTROL, world, "Valvula%d" % index, at, Vector3(0.75, 0.68, 0.26), {
			"prompt_text": "Girar " + valve_name.to_lower(), "available_in": 0
		})
		control.interacted.connect(_turn.bind(index))


func _build_instruments(world: Node3D, present: bool) -> void:
	var gauge := Node3D.new()
	gauge.position = PLANT.DIAL + Vector3(0, 0, 0.03)
	world.add_child(gauge)
	box(gauge, Vector3(0, 0.12, 0), Vector3(0.031, 0.24, 0.018), "mahogany", present)
	_needles.append(gauge)
	var handle: Node3D
	if present:
		handle = Node3D.new()
		handle.position = PLANT.FEED_PIVOT
		world.add_child(handle)
	else:
		# A área gira com o punho. Assim, E também funciona na ponta erguida.
		var feed := area(CONTROL, world, "RegistroGeral", PLANT.FEED_PIVOT, Vector3(0.55, 0.20, 0.20), {
			"available_in": 0, "prompt_text": "Manobrar alimentação"
		})
		(feed.get_child(0) as CollisionShape3D).position.x = 0.17
		feed.interacted.connect(_isolate)
		handle = feed
	box(handle, Vector3(0.16, 0, 0), Vector3(0.4, 0.055, 0.075), "brass", present)
	box(handle, Vector3(0.32, 0, 0), Vector3(0.15, 0.12, 0.09), "enamel", present)
	_feed_handles.append(handle)
	# União curta no ramal de alívio. A luva cai para o lado quando a junta cede.
	var joint := Vector3(9.85, 1.47, 0.42)
	box(world, joint+Vector3(0, -0.47, 0), Vector3(0.14, 0.84, 0.14), "copper", present)
	box(world, joint+Vector3(0, 0.45, 0), Vector3(0.14, 0.8, 0.14), "copper", present)
	var sleeve := box(world, joint, Vector3(0.21, 0.19, 0.21), "brass", present)
	_couplings.append(sleeve)
	if not present:
		box(world, Vector3(4.2, 1.5, 0.055), Vector3(1.18, 0.68, 0.11), "enamel", false)
		var plate := label(world, "AURORA\nINSTRUÇÃO DE PARTIDA", Vector3(4.2, 1.5, 0.115), 26)
		plate.modulate = Color("#312923")
		area(NOTE, world, "PlacaPartida", plate.position, Vector3(1.2, 0.72, 0.18), {
			"prompt_text": "Ler placa de partida", "title": "Grand Hotel Aurora · Oficina de vapor",
			"text": "Na partida a frio, observar a ordem puncionada no coletor antes da esmaltação.\n\nEm caso de ruptura da união, fechar a alimentação para comutar ao ramal de reserva."
		})


func _build_water(world: Node3D) -> void:
	var mid := PLANT.SUMP.get_center()
	_water = MeshInstance3D.new()
	_water.name = "AguaDaBacia"
	_water.position = Vector3(mid.x, -0.62, mid.y)
	var plane := PlaneMesh.new()
	plane.size = PLANT.SUMP.size
	_water.mesh = plane
	var surface := StandardMaterial3D.new()
	surface.albedo_color = Color("#254652")
	surface.metallic = 0.35
	surface.roughness = 0.24
	var ripples := NoiseTexture2D.new()
	ripples.width = 128
	ripples.height = 128
	ripples.seamless = true
	ripples.as_normal_map = true
	var noise := FastNoiseLite.new()
	noise.frequency = 0.045
	ripples.noise = noise
	surface.normal_enabled = true
	surface.normal_texture = ripples
	surface.normal_scale = 0.45
	surface.uv1_scale = Vector3(1.5, 3, 1)
	_water.material_override = surface
	_water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(_water)


func _stage() -> int:
	return clampi(int(WorldState.get_flag(PRESSURE, 0)), RUPTURE, START_ORDER.size())


func _turn(_by: FirstPersonMotor, index: int) -> void:
	var stage := _stage()
	var opened := int(WorldState.get_flag(OPENED, 0))
	if stage == RUPTURE:
		_say("A junta cedeu. O vapor escapa pelo ramal.")
		return
	if stage == START_ORDER.size():
		_say("O ponteiro se mantém na faixa de serviço.")
		return
	if opened & (1 << index):
		_say("O volante já está aberto até o batente.")
		return
	if index != START_ORDER[stage]:
		WorldState.set_flag(MISTAKE, true)
	WorldState.set_flag(OPENED, opened | (1 << index))
	if stage + 1 < START_ORDER.size():
		WorldState.set_flag(PRESSURE, stage + 1)
		_say("O volante cede. O ponteiro sobe uma marca.")
	elif WorldState.is_set(MISTAKE):
		WorldState.set_flag(PRESSURE, RUPTURE)
		_say("O ponteiro passa da faixa vermelha. Um estalo seco: a luva salta do cano de alívio.")
	else:
		WorldState.set_flag(PRESSURE, START_ORDER.size())
		_say("O ponteiro se firma. A bomba volta a puxar água.")


func _isolate(_by: FirstPersonMotor) -> void:
	if _stage() == RUPTURE:
		WorldState.set_flag(OPENED, 0)
		WorldState.set_flag(MISTAKE, false)
		WorldState.set_flag(PRESSURE, 0)
		_say("Você fecha a alimentação. O ramal de reserva assume e o ponteiro volta a zero.")
	else:
		_say("O registro de emergência está armado.")


func _say(message: String) -> void:
	get_tree().call_group("hud", "show_message", message)


func _on_flag_changed(key: String, _value: Variant) -> void:
	if key == PRESSURE or key == OPENED:
		_apply_pressure(_stage(), true)


func _apply_pressure(stage: int, animate: bool) -> void:
	if _motion:
		_motion.kill()
	if animate:
		_motion = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	var opened := int(WorldState.get_flag(OPENED, 0))
	for i in _wheels.size():
		var valve := i % START_ORDER.size()
		var open := stage == START_ORDER.size() or (opened & (1 << valve)) != 0
		_pose(_wheels[i], "rotation_degrees:z", -85.0 if open else 0.0, animate)
	for gauge in _needles:
		_pose(gauge, "rotation_degrees:z", -120.0 if stage == RUPTURE else 120.0 - 60.0*stage, animate)
	for sleeve in _couplings:
		_pose(sleeve, "rotation_degrees:z", -44.0 if stage == RUPTURE else 0.0, animate)
		_pose(sleeve, "position:x", 10.00 if stage == RUPTURE else 9.85, animate)
	for handle in _feed_handles:
		_pose(handle, "rotation_degrees:z", 55.0 if stage == RUPTURE else 0.0, animate)
	var level := -0.62
	if stage == RUPTURE:
		level = -0.08
	elif stage == START_ORDER.size():
		level = -1.34
	_pose(_water, "position:y", level, animate)


func _pose(node: Node3D, property: NodePath, value: float, animate: bool) -> void:
	if animate:
		_motion.tween_property(node, property, value, 0.35)
	else:
		node.set_indexed(property, value)
