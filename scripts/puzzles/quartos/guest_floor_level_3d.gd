class_name GuestFloorLevel3D
extends ChapterRoom3D
## Quartos (2º andar): porta de pavimento, bandeira do 207, diário de Helena e chave mestra do 214.
## Helena chega pela escada principal de 1923; Lia, pela escada de marinheiro do poço do elevador.
## Solução no GDD ("Andares de cima").

const ACTION := preload("res://scripts/interaction3d/interactable_3d.gd")
const MESSAGE := preload("res://scripts/interaction3d/message_interactable_3d.gd")
const NOTE := preload("res://scripts/interaction3d/note_interactable_3d.gd")
const DOOR := preload("res://scripts/interaction3d/door_3d.gd")
const PICKUP := preload("res://scripts/interaction3d/item_pickup_3d.gd")
const LOBBY := "res://scenes/rooms/saguao_3d.tscn"
const BALLROOM := "res://scenes/rooms/salao_3d.tscn"
## Andar da cabine do elevador principal quando ela está parada aqui (ver BallroomLevel3D).
const THIS_FLOOR := 1

const PAVEMENT := "quartos.pavimento.calcado"
const WEDGE_TAKEN := "quartos.cunha.pega"
const TRANSOM := "quartos.bandeira.aberta"
const HANGER := "quartos.cabide.pego"
const DOOR_207 := "quartos.207.aberto"
## Onde está o diário: 0 escrivaninha, 1 gaveta, 2 guarda-roupa, 3 fundo falso da mala, 4 com Helena.
const DIARY := "quartos.diario.local"
const DIARY_READ := "quartos.diario.lido"
const KEY_TAKEN := "quartos.chave_mestra.retirada"
const KEY_HIDDEN := "quartos.chave_mestra.escondida"
const KEY_FOUND := "quartos.chave_mestra.pega"
const DOOR_214 := "quartos.214.aberto"
const DONE := "quartos.concluido"
## Flag do Salão: a partitura que Helena guarda é a que Caio anota em 1951.
const SCORE_SAVED := "salao.partitura.guardada"

const ON_DESK := 0
const WITH_HELENA := 4
const STORAGE_NAMES := ["", "na gaveta", "no guarda-roupa", "no fundo falso da mala"]

const DESK := GuestFloorRoom3D.DESK
const WARDROBE := GuestFloorRoom3D.WARDROBE
const TRUNK := GuestFloorRoom3D.TRUNK
const DIARY_TEXT := "14 de março de 1923.\n\nO lustre do Saguão acende hoje pela primeira vez. Dizem que o hotel inteiro vai brilhar.\n\n" \
	+ "Às 3 h da madrugada ouvi música no salão de baile, no andar de cima. Quatro notas, sempre as mesmas. Subi a escada e o salão estava vazio, com as cadeiras sobre as mesas.\n\n" \
	+ "O Sr. Amaral, o gerente, toca a valsa no piano do Saguão toda noite e depois sobe para dar corda no relógio da torre. A camareira jura que a chave do cofre mora com o pêndulo.\n\n" \
	+ "Amanhã vou embora. Já escrevi isso ontem.\n\nH."

var _landing_doors: Array[StaticBody3D] = []
var _cabs: Array[Node3D] = []
var _levers: Array[Node3D] = []
var _wedge_on_lever: Node3D
var _wedge_on_cart: Node3D
var _doors_207: Array[Node3D] = []
var _transoms: Array[Node3D] = []
var _door_214_today: Node3D
var _mirror_wall: Node3D
var _mirror_down: Node3D
var _diary_on_desk: Node3D
var _hanger: Node3D
var _caio_notebook: Area3D


func _ready() -> void:
	for present: bool in [false, true]:
		var world := make_world(preload("res://scripts/puzzles/quartos/guest_floor_room_3d.gd"), present)
		_build_access(world, present)
		_build_landing(world, present)
		_build_room_207(world, present)
		_build_diary(world, present)
		_build_master_key(world, present)
		_build_room_214(world, present)
	marker("DaEscada", Vector3(3.0, 0, 2.9), PI)
	marker("DoPoco", Vector3(16.25, 0, 1.2), PI)
	_apply_state()
	WorldState.flag_changed.connect(_on_flag)
	super()


# --- Acesso: escada (1923) e poço (hoje) ----------------------------------------------------

func _build_access(world: Node3D, present: bool) -> void:
	if not present:
		area(DOOR, world, "DescerEscada", Vector3(2.25, 0.9, 2.05), Vector3(1.5, 1.0, 0.15), {
			"target_scene": LOBBY, "target_spawn": "DoAndar2Escada",
			"prompt_text": "Descer ao Saguão", "available_in": 0})
		area(DOOR, world, "SubirEscada", Vector3(3.75, 0.9, 2.05), Vector3(1.5, 1.0, 0.15), {
			"target_scene": BALLROOM, "target_spawn": "DaEscada",
			"prompt_text": "Subir ao Salão de baile", "available_in": 0})
	else:
		area(MESSAGE, world, "EscadaDesabada", Vector3(3.0, 0.9, 2.05), Vector3(3.0, 1.0, 0.15), {
			"prompt_text": "Examinar escada", "available_in": 1,
			"message": "A escada principal desabou. Lá embaixo, só escombros."})
		area(DOOR, world, "DescerPoco", Vector3(16.48, 0.9, 0.62), Vector3(0.6, 1.4, 0.15), {
			"target_scene": LOBBY, "target_spawn": "DoAndar2Poco",
			"prompt_text": "Descer pela escada do poço", "available_in": 1})
		var up := area(ACTION, world, "SubirPoco", Vector3(16.48, 2.3, 0.62), Vector3(0.6, 1.2, 0.15), {
			"prompt_text": "Subir pela escada do poço", "available_in": 1})
		up.interacted.connect(_climb_shaft)


# --- Q1. Porta de pavimento -----------------------------------------------------------------

func _build_landing(world: Node3D, present: bool) -> void:
	_cabs.append(ElevatorCab3D.build(world, present))
	var door := StaticBody3D.new()
	door.name = "PortaPavimento"
	door.position = Vector3(16.25, 1.15, GuestFloorRoom3D.NORTH)
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.0, 2.3, 0.08)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	door.add_child(collision)
	world.add_child(door)
	for i in 9:
		box(door, Vector3(-0.45 + i * 0.1125, 0, 0), Vector3(0.025, 2.28, 0.03), "iron", present)
	for y: float in [-1.1, 0.0, 1.1]:
		box(door, Vector3(0, y, 0), Vector3(1.0, 0.04, 0.04), "iron", present)
	_landing_doors.append(door)
	var lever := Node3D.new()
	lever.position = Vector3(17.65, 1.2, GuestFloorRoom3D.NORTH + 0.13)
	world.add_child(lever)
	box(lever, Vector3(0, 0, 0), Vector3(0.12, 0.12, 0.04), "brass" if not present else "iron", present)
	box(lever, Vector3(0, 0.18, 0.03), Vector3(0.035, 0.36, 0.035), "brass" if not present else "iron", present)
	_levers.append(lever)
	if not present:
		var pull := area(ACTION, world, "Alavanca", lever.position + Vector3(0, 0.05, 0.05), Vector3(0.3, 0.5, 0.12), {
			"prompt_text": "Puxar alavanca de destrave", "available_in": 0})
		pull.interacted.connect(_pull_lever)
		var gate := area(ACTION, world, "PavimentoFechado", Vector3(16.25, 1.2, GuestFloorRoom3D.NORTH + 0.15), Vector3(1.0, 2.0, 0.1), {
			"prompt_text": "Examinar porta do elevador", "available_in": 0})
		gate.interacted.connect(func(_by: FirstPersonMotor) -> void:
			_say("A porta do elevador está fechada. Pelas grades, a cabine está bem aqui." if BallroomLevel3D.lift_floor() == THIS_FLOOR \
				else "A porta do elevador está fechada. A cabine está lá em cima."))
		var button := area(ACTION, world, "Botoeira", Vector3(17.3, 1.2, GuestFloorRoom3D.NORTH + 0.18), Vector3(0.3, 0.5, 0.12), {
			"prompt_text": "Chamar o elevador", "available_in": 0})
		button.interacted.connect(_call_cab)
		_wedge_on_cart = box(world, Vector3(5.45, 0.95, 4.0), Vector3(0.22, 0.08, 0.12), "oak", false)
		_wedge_on_lever = box(world, lever.position + Vector3(0, -0.12, 0.06), Vector3(0.12, 0.06, 0.1), "oak", false)
		area(PICKUP, world, "Cunha", Vector3(5.45, 0.98, 4.0), Vector3(0.32, 0.16, 0.3), {
			"prompt_text": "Pegar cunha", "item_id": "cunha", "taken_flag": WEDGE_TAKEN, "available_in": 0})
	else:
		area(MESSAGE, world, "Fresta", Vector3(16.25, 1.2, GuestFloorRoom3D.NORTH - 0.12), Vector3(1.0, 2.0, 0.08), {
			"prompt_text": "Espiar pela fresta", "available_in": 1, "done_flag": PAVEMENT,
			"message": "A porta do pavimento está travada. Pela fresta, do lado do corredor, aparece uma alavanca de destrave, levantada."})


func _call_cab(_by: FirstPersonMotor) -> void:
	if not WorldState.is_set(BallroomLevel3D.LIFT_POWER):
		_say("Você aperta o botão. Nada acende: o elevador está desligado lá embaixo.")
	elif BallroomLevel3D.lift_floor() == THIS_FLOOR:
		_say("A cabine já está parada neste andar.")
	else:
		WorldState.set_flag(BallroomLevel3D.LIFT_FLOOR, THIS_FLOOR)
		_say("Os cabos rangem no poço. A cabine desce e para no 2º andar.")


## Hoje a escada do poço está partida entre o 2º e o 3º andar. Com a cabine parada aqui, Lia sai
## pelo alçapão do teto e alcança a escada inteira lá em cima.
func _climb_shaft(_by: FirstPersonMotor) -> void:
	if BallroomLevel3D.lift_floor() == THIS_FLOOR:
		RoomManager.change_room_alone(BALLROOM, "DoPoco", Era.Id.PRESENT)
	else:
		_say("Acima do patamar, faltam degraus num trecho de dois metros. Lá no alto, a escada continua inteira, fora de alcance.")


func _pull_lever(by: FirstPersonMotor) -> void:
	if WorldState.is_set(PAVEMENT):
		_say("A alavanca está calçada com a cunha. A porta do elevador ficou destravada.")
	elif by.get_held_item() == "cunha":
		by.set_held_item("")
		WorldState.set_flag(PAVEMENT)
		_say("Você puxa a alavanca e a calça com a cunha. A trava da porta do elevador fica solta.")
	else:
		_say("Você puxa a alavanca de destrave. Ela volta sozinha quando você solta.")


# --- Q2. Bandeira do 207 --------------------------------------------------------------------

func _build_room_207(world: Node3D, present: bool) -> void:
	var gap := GuestFloorRoom3D.ROOM_207
	var hinge := Node3D.new()
	hinge.name = "Folha207"
	hinge.position = Vector3(gap.x, 0, GuestFloorRoom3D.SOUTH)
	world.add_child(hinge)
	box(hinge, Vector3(0.5, GuestFloorRoom3D.DOOR_TOP / 2.0, 0), Vector3(1.0, GuestFloorRoom3D.DOOR_TOP, 0.06), "mahogany", present)
	box(hinge, Vector3(0.85, 1.0, -0.05), Vector3(0.06, 0.06, 0.04), "brass", present)
	var body := StaticBody3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.0, GuestFloorRoom3D.DOOR_TOP, 0.08)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = Vector3(0.5, GuestFloorRoom3D.DOOR_TOP / 2.0, 0)
	body.add_child(collision)
	hinge.add_child(body)
	_doors_207.append(hinge)
	# Bandeira de vidro acima da porta: o vão escuro aparece quando ela está aberta
	var transom := Node3D.new()
	transom.position = Vector3((gap.x + gap.y) / 2.0, 2.4, GuestFloorRoom3D.SOUTH)
	world.add_child(transom)
	var hole := box(transom, Vector3(0, 0.2, 0), Vector3(0.9, 0.36, 0.24), "dark", present)
	hole.name = "Vao"
	var pane := Node3D.new()
	pane.name = "Vidro"
	transom.add_child(pane)
	box(pane, Vector3(0, 0.18, -0.13), Vector3(0.9, 0.36, 0.02), "glass", present)
	_transoms.append(transom)
	if not present:
		var chain := area(ACTION, world, "Correntinha", Vector3(gap.y - 0.15, 2.0, GuestFloorRoom3D.SOUTH + 0.2), Vector3(0.25, 0.6, 0.12), {
			"prompt_text": "Puxar a correntinha da bandeira", "available_in": 0})
		chain.interacted.connect(func(_by: FirstPersonMotor) -> void:
			if WorldState.is_set(TRANSOM):
				_say("A bandeira já está aberta.")
			else:
				WorldState.set_flag(TRANSOM)
				_say("Você puxa a correntinha. A bandeira de vidro sobre a porta se inclina e fica aberta."))
		box(world, Vector3(gap.y - 0.15, 2.05, GuestFloorRoom3D.SOUTH + 0.14), Vector3(0.01, 0.45, 0.01), "brass", false)
	else:
		var door := area(ACTION, world, "Porta207", Vector3((gap.x + gap.y) / 2.0, 1.15, GuestFloorRoom3D.SOUTH - 0.18),
			Vector3(1.0, 2.3, 0.1), {"prompt_text": "Abrir quarto 207", "available_in": 1, "done_flag": DOOR_207})
		door.interacted.connect(_try_door_207)
		_hanger = box(world, Vector3(6.35, 1.08, 0.8), Vector3(0.04, 0.03, 0.4), "iron", true)
		area(PICKUP, world, "Cabide", Vector3(6.45, 1.12, 0.8), Vector3(0.5, 0.2, 0.5), {
			"prompt_text": "Pegar cabide de arame", "item_id": "cabide", "taken_flag": HANGER, "available_in": 1})


func _try_door_207(by: FirstPersonMotor) -> void:
	var open_transom := WorldState.is_set(TRANSOM)
	if open_transom and by.get_held_item() == "cabide":
		by.set_held_item("")
		WorldState.set_flag(DOOR_207)
		_say("Você passa o cabide pela bandeira aberta e levanta o trinco. A porta do 207 cede.")
	elif open_transom:
		_say("A porta do 207 está inchada e trancada pelo trinco de dentro. Acima dela, a bandeira de vidro ficou aberta, emperrada.")
	else:
		_say("A porta do 207 está inchada e trancada pelo trinco de dentro. A bandeira de vidro acima dela está fechada.")


# --- Q3. Diário de Helena -------------------------------------------------------------------

func _build_diary(world: Node3D, present: bool) -> void:
	var places := {
		ON_DESK: [Vector3(DESK.x, DESK.y + 0.08, DESK.z), Vector3(0.7, 0.18, 1.1), "Escrivaninha"],
		1: [Vector3(DESK.x + 0.39, 0.62, DESK.z), Vector3(0.08, 0.2, 0.7), "Gaveta"],
		2: [WARDROBE + Vector3(0, 1.1, -0.4), Vector3(1.2, 1.8, 0.1), "Guarda-roupa"],
		3: [TRUNK + Vector3(0, 0.46, 0), Vector3(0.8, 0.12, 0.5), "Mala"],
	}
	for place: int in places:
		var info: Array = places[place]
		var spot := area(ACTION, world, info[2], info[0], info[1], {
			"prompt_text": "Examinar " + str(info[2]).to_lower(), "available_in": 1 if present else 0})
		spot.interacted.connect((_diary_today if present else _diary_1923).bind(place))
	if not present:
		_diary_on_desk = box(world, Vector3(DESK.x + 0.05, DESK.y + 0.02, DESK.z + 0.2), Vector3(0.18, 0.03, 0.24), "leather", false)


func _diary_1923(by: FirstPersonMotor, place: int) -> void:
	var local := int(WorldState.get_flag(DIARY, ON_DESK))
	var hand := by.get_held_item()
	if hand == "diario":
		by.set_held_item("")
		WorldState.set_flag(DIARY, place)
		_say("Você deixa o diário sobre a escrivaninha." if place == ON_DESK else "Você guarda o diário %s." % STORAGE_NAMES[place])
	elif hand != "":
		_say("A mão está ocupada.")
	elif local == place:
		by.set_held_item("diario")
		WorldState.set_flag(DIARY, WITH_HELENA)
		_say("Você escreve a página do dia e fecha o diário." if place == ON_DESK else "Você pega o diário de volta.")
	else:
		_say(["Papel de carta do hotel e um tinteiro.", "Envelopes e papel de carta do hotel.",
			"Seus vestidos e o casaco de viagem.", "Sua mala de couro encerado. Tem um fundo falso, forrado."][place])


func _diary_today(_by: FirstPersonMotor, place: int) -> void:
	var here := int(WorldState.get_flag(DIARY, ON_DESK)) == place
	match place:
		ON_DESK:
			_say("Sobre a escrivaninha, um bloco de papel colado pela umidade. As folhas não se separam." if here
				else "A escrivaninha está vazia, coberta de pó.")
		1:
			_say("Na gaveta, um caderno virou pasta de papel. Só se lê um H na capa." if here
				else "A gaveta emperrada guarda só pó.")
		2:
			_say("Cupins comeram o fundo do guarda-roupa e o que havia dentro. Resta uma capa de couro e farelo de papel." if here
				else "O guarda-roupa está vazio. Cupins abriram buracos no fundo.")
		3:
			if here:
				WorldState.set_flag(DIARY_READ)
				NoteUI.open(get_tree(), "Diário de Helena · 1923", DIARY_TEXT)
			else:
				_say("Uma mala de couro encerado, vazia. O forro está descosturado num canto: por baixo, um fundo falso, vazio.")


# --- Q4. Chave mestra e quarto 214 ----------------------------------------------------------

func _build_master_key(world: Node3D, present: bool) -> void:
	var cabinet := Vector3(7.9, 1.1, -0.0)
	var mirror_at := GuestFloorRoom3D.MIRROR
	if not present:
		var linen := area(ACTION, world, "ArmarioGovernanta", cabinet + Vector3(0, 0, 0.12), Vector3(0.9, 1.8, 0.1), {
			"prompt_text": "Abrir armário da governanta", "available_in": 0})
		linen.interacted.connect(_linen_cabinet)
		var mirror := area(ACTION, world, "Espelho", mirror_at + Vector3(0, 0, -0.05), Vector3(1.0, 1.3, 0.1), {
			"prompt_text": "Examinar espelho", "available_in": 0})
		mirror.interacted.connect(_mirror_1923)
		box(world, mirror_at + Vector3(0, 0, -0.02), Vector3(0.95, 1.25, 0.02), "glass", false)
	else:
		area(MESSAGE, world, "ArmarioGovernanta", cabinet + Vector3(0, 0, 0.12), Vector3(0.9, 1.8, 0.1), {
			"prompt_text": "Abrir armário da governanta", "available_in": 1,
			"message": "O armário da governanta está vazio. Os ganchos numerados enferrujaram."})
		var mirror := area(ACTION, world, "Espelho", mirror_at + Vector3(0, 0, -0.05), Vector3(1.0, 1.3, 0.1), {
			"prompt_text": "Tirar o espelho da parede", "available_in": 1, "done_flag": KEY_FOUND})
		mirror.interacted.connect(_mirror_today)
		_mirror_wall = box(world, mirror_at + Vector3(0, 0, -0.02), Vector3(0.95, 1.25, 0.02), "marble", true)
		_mirror_wall.rotation_degrees.z = 2.0
		_mirror_down = box(world, Vector3(mirror_at.x + 0.9, 0.62, GuestFloorRoom3D.SOUTH - 0.25), Vector3(0.95, 1.25, 0.03), "marble", true)
		_mirror_down.rotation_degrees.x = -12.0


func _linen_cabinet(by: FirstPersonMotor) -> void:
	if WorldState.is_set(KEY_TAKEN):
		_say("Os ganchos numerados da governanta. Falta a chave mestra.")
	elif by.get_held_item() != "":
		_say("Entre os ganchos da governanta há uma chave mestra do andar. A mão está ocupada.")
	else:
		by.set_held_item("chave_mestra")
		WorldState.set_flag(KEY_TAKEN)
		_say("Você pega a chave mestra do andar no armário da governanta.")


func _mirror_1923(by: FirstPersonMotor) -> void:
	if WorldState.is_set(KEY_HIDDEN):
		_say("Atrás da moldura, a chave continua presa no chumbo.")
	elif by.get_held_item() == "chave_mestra":
		by.set_held_item("")
		WorldState.set_flag(KEY_HIDDEN)
		_say("Você encaixa a chave mestra atrás da moldura do espelho, presa no chumbo.")
	else:
		_say("Um espelho chumbado na parede. Atrás da moldura sobra um vão estreito.")


func _mirror_today(by: FirstPersonMotor) -> void:
	if by.get_held_item() != "":
		_say("O espelho rachado está solto na parede. A mão está ocupada.")
	elif WorldState.is_set(KEY_HIDDEN):
		by.set_held_item("chave_mestra")
		WorldState.set_flag(KEY_FOUND)
		_say("Você tira o espelho rachado da parede. Atrás dele, presa no chumbo: uma chave. MESTRA · 2º ANDAR.")
	else:
		_say("Você levanta o espelho rachado. Atrás dele, só reboco. Você o encosta de volta.")


func _build_room_214(world: Node3D, present: bool) -> void:
	var gap := GuestFloorRoom3D.ROOM_214
	var hinge := Node3D.new()
	hinge.name = "Folha214"
	hinge.position = Vector3(gap.x, 0, GuestFloorRoom3D.NORTH)
	world.add_child(hinge)
	box(hinge, Vector3(0.5, GuestFloorRoom3D.DOOR_TOP / 2.0, 0), Vector3(1.0, GuestFloorRoom3D.DOOR_TOP, 0.06), "mahogany", present)
	box(hinge, Vector3(0.85, 1.0, 0.05), Vector3(0.06, 0.06, 0.04), "brass", present)
	var body := StaticBody3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.0, GuestFloorRoom3D.DOOR_TOP, 0.08)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = Vector3(0.5, GuestFloorRoom3D.DOOR_TOP / 2.0, 0)
	body.add_child(collision)
	hinge.add_child(body)
	var front := Vector3((gap.x + gap.y) / 2.0, 1.15, GuestFloorRoom3D.NORTH + 0.18)
	if not present:
		area(MESSAGE, world, "Porta214", front, Vector3(1.0, 2.3, 0.1), {
			"prompt_text": "Bater no 214", "available_in": 0,
			"message": "Quarto 214. Ocupado. Do lado de dentro, alguém tosse."})
		return
	_door_214_today = hinge
	var door := area(ACTION, world, "Porta214", front, Vector3(1.0, 2.3, 0.1), {
		"prompt_text": "Abrir quarto 214", "available_in": 1, "done_flag": DOOR_214})
	door.interacted.connect(func(by: FirstPersonMotor) -> void:
		if by.get_held_item() == "chave_mestra":
			by.set_held_item("")
			WorldState.set_flag(DOOR_214)
			_say("A chave mestra gira. A porta do 214 abre.")
		else:
			_say("Quarto 214, trancado. A fechadura é do tipo mestra: uma só chave abre o andar todo."))
	var notebook := area(NOTE, world, "CadernoCaio", Vector3(13.85, 0.86, -0.35), Vector3(0.6, 0.2, 0.5), {
		"prompt_text": "Ler caderno", "title": "Caderno do Dr. Caio Ferraz · 1951", "available_in": 1})
	notebook.interacted.connect(func(_by: FirstPersonMotor) -> void: WorldState.set_flag(DONE))
	_caio_notebook = notebook
	area(NOTE, world, "MaletaMedico", Vector3(13.0, 0.4, -1.5), Vector3(0.6, 0.25, 0.4), {
		"prompt_text": "Examinar maleta", "title": "Maleta de médico", "available_in": 1,
		"text": "Couro gasto, iniciais C.F. no fecho.\n\nEstetoscópio, um vidro de éter vazio e um bloco de receitas. A primeira folha está assinada e em branco."})


## O caderno de Caio muda conforme a partitura do Salão: se Helena a guardou, ele a achou.
func _caio_text() -> String:
	var found := "Achei uma partitura velha na banqueta do piano do palco. Escrevi a lápis os números das teclas, do jeito que ouvi." \
		if WorldState.is_set(SCORE_SAVED) \
		else "Procurei a partitura de que o porteiro falava. A banqueta do piano estava vazia, e o que havia na estante do maestro virou pó."
	return "1951. Quarto 214.\n\nToda madrugada, às 3 h, quatro notas atravessam o teto. O salão de baile está fechado há anos.\n\n" \
		+ found + "\n\nA recepção diz que não há registro da minha entrada. Eu tenho a chave do quarto na mão.\n\nC.F."


# --- Estado ---------------------------------------------------------------------------------

func _apply_state() -> void:
	for cab: Node3D in _cabs:
		cab.visible = BallroomLevel3D.lift_floor() == THIS_FLOOR
	var calked := WorldState.is_set(PAVEMENT)
	# Em 1923 a porta do elevador fica fechada; hoje, com a alavanca calçada, abre
	_set_solid(_landing_doors[0], true)
	_landing_doors[1].visible = not calked
	_set_solid(_landing_doors[1], not calked)
	for lever: Node3D in _levers:
		lever.rotation_degrees.z = 180.0 if calked else 0.0
	_wedge_on_lever.visible = calked
	_wedge_on_cart.visible = not WorldState.is_set(WEDGE_TAKEN)
	# 207: aberta para Helena em 1923; hoje só depois do cabide
	_doors_207[0].rotation_degrees.y = -95.0
	_doors_207[1].rotation_degrees.y = -80.0 if WorldState.is_set(DOOR_207) else 0.0
	for transom: Node3D in _transoms:
		var open := WorldState.is_set(TRANSOM)
		transom.get_node("Vao").visible = open
		transom.get_node("Vidro").rotation_degrees.x = -35.0 if open else 0.0
	_hanger.visible = not WorldState.is_set(HANGER)
	_diary_on_desk.visible = int(WorldState.get_flag(DIARY, ON_DESK)) == ON_DESK
	var found := WorldState.is_set(KEY_FOUND)
	_mirror_wall.visible = not found
	_mirror_down.visible = found
	_door_214_today.rotation_degrees.y = 85.0 if WorldState.is_set(DOOR_214) else 0.0
	_caio_notebook.text = _caio_text()


func _set_solid(node: Node, solid: bool) -> void:
	for child in node.get_children():
		if child is CollisionShape3D:
			child.disabled = not solid


func _on_flag(key: String, _value: Variant) -> void:
	if key.begins_with("quartos.") or key in [SCORE_SAVED, BallroomLevel3D.LIFT_FLOOR]:
		_apply_state()


func _say(message: String) -> void:
	get_tree().call_group("hud", "show_message", message)
