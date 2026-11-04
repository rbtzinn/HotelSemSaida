@tool
class_name KitchenProp3D
extends HotelBuilder3D
## Peças da Cozinha 3D que mudam com os enigmas (cabine, porta da despensa, forno de hoje,
## fermento, gelo, fresta, buraco...). Cada nó desenha uma peça (`kind`) em torno da própria
## origem; quem a mostra, esconde ou move é o enigma (EraLinked3D, ServiceElevator3D...).

@export var kind: String = "":
	set(value):
		kind = value
		if is_inside_tree():
			_build()

## Pé-direito da cozinha acima do piso da despensa (a cozinha fica em cima).
const KITCHEN: float = 4.5


func _build_room() -> void:
	match kind:
		"cabin_1923":
			_cabin_1923()
		"lever_handle":
			_lever_handle()
		"door_locked":
			_door_locked()
		"door_open":
			_door_open()
		"dough":
			_dough()
		"oven_crumbled":
			_oven_crumbled()
		"oven_petrified":
			_oven_petrified()
		"cabin_present_low":
			_cabin_present_low()
		"shaft_open":
			_shaft_open()
		"yeast_jar":
			_yeast_jar()
		"ice_block":
			_ice_block()
		"stain":
			_stain()
		"crack":
			_crack()
		"hole":
			_hole()
		"hatch_gate":
			_hatch_gate()
		"hatch_gate_torn":
			_hatch_gate_torn()
		"menu_1923":
			_menu_1923()
		"paper_present":
			_paper_present()


## Cardápio do dia preso na parede por um percevejo, rasgado embaixo (origem no centro).
func _menu_1923() -> void:
	_extrude(PackedVector2Array([Vector2(-0.15, -0.21), Vector2(0.15, -0.21), Vector2(0.15, 0.12), Vector2(0.09, 0.15), Vector2(0.02, 0.11), Vector2(-0.06, 0.16), Vector2(-0.15, 0.13)]), 0.0, 0.004, Vector3.ZERO, 0, "paper").rotation_degrees = Vector3(-90, 0, 0)
	for i in 6:
		_part(Vector3(-0.1, 0.12 - i * 0.045, 0.004), Vector3(0.1 - _random(i) * 0.06, 0.128 - i * 0.045, 0.006), "dark_wood")
	_label("CARDÁPIO", Vector3(0, 0.17, 0.006), 0.035, Color("#3A1A10"))
	_sphere(Vector3(0, 0.19, 0.01), 0.012, "brass")


## Hoje: pedaço de papel amarelado, quase sem tinta, preso por um prego torto.
func _paper_present() -> void:
	_extrude(PackedVector2Array([Vector2(-0.12, -0.13), Vector2(0.1, -0.15), Vector2(0.13, 0.1), Vector2(0.03, 0.14), Vector2(-0.11, 0.12)]), 0.0, 0.004, Vector3.ZERO, 0, "paper").rotation_degrees = Vector3(-90, 0, 0)
	for i in 3:
		_part(Vector3(-0.08, 0.05 - i * 0.05, 0.004), Vector3(0.02 + _random(i) * 0.05, 0.056 - i * 0.05, 0.006), "rubble")
	_cylinder(Vector3(0, 0.11, 0.0), 0.006, 0.006, 0.03, "iron", Vector3(80, 0, 0), 6)


## Cabine do elevador de serviço (2 × 2 m), aberta para oeste, com luz dentro.
func _cabin_1923() -> void:
	_part(Vector3(-1, 0, -1), Vector3(1, 0.08, 1), "dark_wood")
	_part(Vector3(0.94, 0, -1), Vector3(1, 2.4, 1), "mahogany")
	_part(Vector3(-1, 0, -1), Vector3(1, 2.4, -0.94), "mahogany")
	_part(Vector3(-1, 0, 0.94), Vector3(1, 2.4, 1), "mahogany")
	_part(Vector3(-1, 2.4, -1), Vector3(1, 2.48, 1), "dark_wood")
	for y: float in [0.9, 1.0]:
		_part(Vector3(0.9, y, -0.9), Vector3(0.94, y + 0.03, 0.9), "brass")
	_part(Vector3(-0.98, 0.08, -1), Vector3(-0.92, 2.4, -0.94), "brass")
	_part(Vector3(-0.98, 0.08, 0.94), Vector3(-0.92, 2.4, 1), "brass")
	_part(Vector3(-0.3, 2.36, -0.3), Vector3(0.3, 2.4, 0.3), "bulb")
	# Cabos que puxam a cabine pelo teto
	for z: float in [-0.25, 0.25]:
		_cylinder(Vector3(0, 2.48, z), 0.02, 0.02, 6.0, "iron", Vector3.ZERO, 6)
	_omni(Vector3(0, 2.1, 0), Color("#F2D49B"), 0.9, 4.0)


## Alavanca (ou freio): haste com punho, presa na base pelo pivô (origem).
func _lever_handle() -> void:
	_cylinder(Vector3.ZERO, 0.025, 0.02, 0.34, "brass", Vector3.ZERO, 8)
	_sphere(Vector3(0, 0.36, 0), 0.045, "lacquer")


## Porta da despensa fechada, com aldrava e cadeado (origem no centro do vão, no piso).
func _door_locked() -> void:
	_part(Vector3(-0.5, 0, -0.03), Vector3(0.5, 2.3, 0.03), "mahogany")
	for y: Vector2 in [Vector2(0.15, 1.0), Vector2(1.2, 2.15)]:
		_part(Vector3(-0.38, y.x, 0.03), Vector3(0.38, y.y, 0.05), "panel")
	_sphere(Vector3(0.38, 1.05, 0.07), 0.04, "brass")
	_part(Vector3(0.18, 1.0, 0.05), Vector3(0.46, 1.08, 0.08), "iron")
	_block(Vector3(0.32, 0.92, 0.1), Vector3(0.09, 0.1, 0.05), "brass")
	_torus(Vector3(0.32, 0.99, 0.1), 0.022, 0.032, "iron", Vector3(0, 0, 90))
	_solid(Vector3(-0.5, 0, -0.06), Vector3(0.5, 2.3, 0.06), "DoorLeaf")


## A mesma porta, aberta para dentro da escada (dobradiça a oeste).
func _door_open() -> void:
	var leaf := _group(Vector3(-0.5, 0, 0), -100.0)
	_child_box(leaf, Vector3(0.5, 1.15, 0), Vector3(1.0, 2.3, 0.06), "mahogany")
	_child_box(leaf, Vector3(0.5, 0.575, -0.04), Vector3(0.76, 0.85, 0.02), "panel")
	_child_box(leaf, Vector3(0.5, 1.675, -0.04), Vector3(0.76, 0.95, 0.02), "panel")


## Massa de pão crescendo dentro do forno aberto (1923).
func _dough() -> void:
	_sphere(Vector3(0, 0.12, 0), 0.32, "dough", Vector3(1.3, 0.55, 1))
	_sphere(Vector3(0.12, 0.2, 0.05), 0.18, "dough", Vector3(1, 0.7, 1))


## Hoje, sem a massa: o fogão desabou num monte baixo de ferro e tijolo. Nada passa
## da altura da colisão (0,4 m): o que se vê é onde se pisa.
func _oven_crumbled() -> void:
	_solid(Vector3(-0.8, 0, -0.5), Vector3(0.8, 0.4, 0.5), "OvenCrumbled")
	_part(Vector3(-0.78, 0, -0.48), Vector3(0.78, 0.22, 0.48), "rubble")
	for i in 9:
		var at := Vector3(-0.6 + _random(i) * 1.2, 0.26, -0.32 + _random(i, 2.0) * 0.64)
		_block(at, Vector3(0.25 + _random(i, 3.0) * 0.3, 0.1, 0.2 + _random(i, 5.0) * 0.2), "cast_iron" if i % 2 == 0 else "rubble", Vector3(_random(i, 6.0) * 8.0, _random(i, 7.0) * 180.0, _random(i, 8.0) * 8.0))
	# Chapa do fogão partida, apoiada no monte
	_part(Vector3(-0.7, 0.3, -0.45), Vector3(0.1, 0.36, 0.4), "cast_iron", Vector3(0, 10, 4))


## Hoje, com a massa: a massa cresceu, endureceu e selou o fogão. Firme como um degrau.
## O tampo é uma crosta lisa na altura exata da colisão (0,84 m), para os pés não afundarem.
func _oven_petrified() -> void:
	_solid(Vector3(-0.84, 0, -0.54), Vector3(0.84, 0.84, 0.54), "OvenPetrified")
	_part(Vector3(-0.8, 0, -0.5), Vector3(0.8, 0.76, 0.5), "cast_iron")
	_part(Vector3(-0.5, 0.15, 0.5), Vector3(0.1, 0.55, 0.52), "cast_iron")
	# A massa petrificada selou o tampo e escorreu pela porta do forno, até o chão
	_part(Vector3(-0.84, 0.76, -0.54), Vector3(0.84, 0.84, 0.54), "petrified")
	for i in 7:
		var x := -0.75 + i * 0.25
		_sphere(Vector3(x, 0.8, 0.54), 0.07 + _random(i) * 0.04, "petrified", Vector3(1.3, 0.6, 0.5))
	_sphere(Vector3(-0.2, 0.36, 0.52), 0.3, "petrified", Vector3(1.4, 0.8, 0.12))
	_sphere(Vector3(-0.25, 0.02, 0.56), 0.2, "petrified", Vector3(1.4, 0.15, 0.25))


## Hoje, sem o elevador travado: o teto podre da cabine fica logo abaixo da portinhola.
func _cabin_present_low() -> void:
	_part(Vector3(-1, -0.1, -1), Vector3(1, 0, 1), "plank")
	_part(Vector3(-1, -2.4, 0.94), Vector3(1, -0.1, 1), "plank")
	_part(Vector3(-1, -2.4, -1), Vector3(1, -0.1, -0.94), "plank")
	_part(Vector3(0.94, -2.4, -1), Vector3(1, -0.1, 1), "plank")
	for z: float in [-0.25, 0.25]:
		_cylinder(Vector3(0, 0, z), 0.02, 0.02, 6.0, "iron", Vector3.ZERO, 6)


## Hoje, com o elevador travado em 1923: a cabine apodreceu presa lá em cima e o poço
## está aberto até a despensa, com os cabos descendo.
func _shaft_open() -> void:
	var top := KITCHEN + 3.6
	_part(Vector3(-1, top, -1), Vector3(1, top + 0.1, 1), "plank", Vector3(4, 0, 3))
	_part(Vector3(-1, top + 0.1, -1), Vector3(1, top + 1.2, -0.94), "plank")
	for z: float in [-0.25, 0.25]:
		_cylinder(Vector3(0, 0.0, z), 0.022, 0.022, top, "iron", Vector3.ZERO, 6)
	# O cabo inclinado também alcança a fixação: compensa a inclinação no comprimento.
	_cylinder(Vector3(0.3, 0.0, 0.0), 0.012, 0.012, top / cos(deg_to_rad(2.0)), "iron", Vector3(0, 0, 2), 6)


func _yeast_jar() -> void:
	_cylinder(Vector3.ZERO, 0.055, 0.05, 0.13, "glass", Vector3.ZERO, 12)
	_cylinder(Vector3(0, 0.02, 0), 0.045, 0.045, 0.08, "flour", Vector3.ZERO, 12)
	_cylinder(Vector3(0, 0.13, 0), 0.058, 0.058, 0.025, "oak", Vector3.ZERO, 12)
	_part(Vector3(-0.04, 0.05, 0.05), Vector3(0.04, 0.1, 0.056), "paper")


func _ice_block() -> void:
	_block(Vector3(0, 0.12, 0), Vector3(0.32, 0.24, 0.28), "ice", Vector3(0, 18, 0))
	_part(Vector3(-0.3, 0.0, -0.25), Vector3(0.3, 0.004, 0.25), "dark")


## Mancha de água onde ficou o último bloco de gelo.
func _stain() -> void:
	_cylinder(Vector3(0, 0.003, 0), 0.45, 0.45, 0.004, "dark", Vector3.ZERO, 20)
	_cylinder(Vector3(0.15, 0.004, 0.1), 0.25, 0.25, 0.004, "dark", Vector3.ZERO, 16)


## Fresta entre as tábuas, por onde sobe uma corrente de ar.
func _crack() -> void:
	_part(Vector3(-0.55,-0.2,-0.60),Vector3(0.55,0,0.60),"floorboards")
	_solid(Vector3(-0.55,-0.2,-0.60),Vector3(0.55,0,0.60),"Planks")
	_part(Vector3(-0.45, 0.001, -0.03), Vector3(0.45, 0.006, 0.03), "dark", Vector3(0, 12, 0))
	_part(Vector3(-0.2, 0.001, 0.02), Vector3(0.25, 0.006, 0.05), "dark", Vector3(0, -20, 0))
	var draft := CPUParticles3D.new()
	draft.amount = 24
	draft.lifetime = 2.5
	draft.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	draft.emission_box_extents = Vector3(0.4, 0.01, 0.04)
	draft.direction = Vector3.UP
	draft.spread = 15.0
	draft.gravity = Vector3.ZERO
	draft.initial_velocity_min = 0.25
	draft.initial_velocity_max = 0.45
	var mote := QuadMesh.new()
	mote.size = Vector2(0.012, 0.012)
	var material := StandardMaterial3D.new()
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.albedo_color = Color(0.85, 0.88, 0.9, 0.55)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mote.material = material
	draft.mesh = mote
	_add(draft)


## O piso apodrecido cedeu: um buraco escuro com tábuas partidas em volta.
func _hole() -> void:
	# Primeiro patamar e escada de ferro, reconhecíveis dos dois lados do alçapão.
	for x: float in [-0.55,0.55]:
		_block(Vector3(x,-0.44,0),Vector3(0.055,0.9,1.2),"oak")
	for z: float in [-0.60,0.60]:
		_block(Vector3(0,-0.44,z),Vector3(1.1,0.9,0.055),"plank")
	for x: float in [-0.35,0.35]:
		_cylinder(Vector3(x,-0.75,-0.37),0.035,0.035,1.17,"iron")
	for i in 4:
		_cylinder(Vector3(-0.35,-0.62+i*0.28,-0.37),0.022,0.022,0.70,"iron",Vector3(0,0,-90),8)
	_part(Vector3(-0.55,-0.77,-0.6),Vector3(0.55,-0.67,0.6),"stone")
	_solid(Vector3(-0.55,-0.77,-0.6),Vector3(0.55,-0.67,0.6),"Landing")
	for i in 8:
		var angle := TAU * i / 8.0 + _random(i) * 0.4
		var at := Vector3(cos(angle), 0, sin(angle)) * 0.62
		_block(at + Vector3(0, -0.04, 0), Vector3(0.12, 0.04, 0.45), "floorboards", Vector3(-25.0 - _random(i, 1.0) * 30.0, -rad_to_deg(angle) + 90.0, 0))


## Grade sanfonada fechando a portinhola (origem no centro do vão, na base). Sólida.
func _hatch_gate() -> void:
	var rust := "brass" if not present else "iron"
	for i in 9:
		var z := -0.5 + i * 0.125
		_part(Vector3(-0.02, 0, z - 0.012), Vector3(0.0, 1.8, z + 0.012), rust)
	# Losangos da sanfona entre as barras, em três fileiras
	for row in 3:
		var y := 0.3 + row * 0.6
		for i in 8:
			var z := -0.4375 + i * 0.125
			for side: float in [-1.0, 1.0]:
				_block(Vector3(-0.03, y + side * 0.15, z), Vector3(0.01, 0.33, 0.01), rust, Vector3(side * 22.0, 0, 0))
	for y: float in [0.02, 0.9, 1.78]:
		_part(Vector3(-0.04, y - 0.02, -0.55), Vector3(0.0, y + 0.02, 0.55), rust)
	_solid(Vector3(-0.05, 0, -0.55), Vector3(0.05, 1.8, 0.55), "Gate")


## Hoje, com o poço aberto: a grade arrancada, caída e torta no chão da cozinha.
func _hatch_gate_torn() -> void:
	var gate := _group(Vector3.ZERO, 70.0)
	for i in 9:
		_child_box(gate, Vector3(-0.5 + i * 0.125, 0.015, 0), Vector3(0.024, 0.02, 1.8), "iron", Vector3(0, _random(i) * 6.0, 0))
	for x: float in [-0.53, 0.53]:
		_child_box(gate, Vector3(x, 0.02, 0), Vector3(0.04, 0.03, 1.8), "iron")
