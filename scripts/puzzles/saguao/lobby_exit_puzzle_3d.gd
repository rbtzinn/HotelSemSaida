extends Node
## S4: cofre da gerência e entrada principal, o último enigma desta versão.
## Em 1923, Helena abre o cofre com a data em que o lustre se acendeu (1403), pega a chave da
## porta principal e solta a trava da porta giratória. Hoje, a fechadura só cede porque Helena a
## deixou destrancada; a corrente posta em 1979 cai com a chave da bolsa de Marta.
## Com as duas trancas abertas, Lia tenta sair e volta a entrar no Saguão (`jogo.final`).

const ACTION := preload("res://scripts/interaction3d/interactable_3d.gd")
const MESSAGE := preload("res://scripts/interaction3d/message_interactable_3d.gd")
const SAFE_OPEN := "saguao.cofre.aberto"
const SAFE_KEY_TAKEN := "saguao.chave.entrada"
const LATCH_1923 := "saguao.entrada.trava_1923"
const PADLOCK := "saguao.entrada.cadeado"
const FINAL := "jogo.final"
const SAFE_CODE := "1403"
const ENTRANCE_KEY := "chave_entrada"
const MARTA_KEY := "chave_portaria"
const SAFE := Vector3(12.2, 0.2, LobbyRoom3D.NORTH)
const ENTRANCE := Vector3(10.0, 1.2, 9.95)
## Onde Lia "entra" de novo, de costas para a porta que acabou de abrir.
const RETURN_SPOT := Vector3(10.0, 0.0, 9.4)
const KNOCK := "Do outro lado da porta giratória, alguém bate. Três batidas, como os passos de alguém que tateia no escuro."

var safe_door: Node3D
var safe_recess: MeshInstance3D
var safe_key: Node3D
var latch_key: Node3D
var chain: Node3D
var _leaving := false


func install(room: ChapterRoom3D) -> void:
	var past := room.get_node("World1923") as Node3D
	var today := room.get_node("WorldToday") as Node3D
	_build_safe(room, past)
	room.area(MESSAGE, today, "CofreHoje", SAFE + Vector3(0, 0.62, 0.56), Vector3(1.0, 0.9, 0.12), {
		"prompt_text": "Examinar cofre",
		"message": "O segredo do cofre não gira mais, preso de ferrugem. Na porta, nenhuma frase sobreviveu à umidade.",
		"available_in": 1,
	})
	room.area(MESSAGE, today, "CoroaLustre", Vector3(LobbyRoom3D.CHANDELIER.x, 0.25, LobbyRoom3D.CHANDELIER.z + 1.75),
		Vector3(1.2, 0.5, 0.2), {
			"prompt_text": "Examinar coroa do lustre",
			"message": "Na faixa de latão da coroa, que em 1923 ficava no teto, alguém gravou: «Aceso pela primeira vez em 14/03/1923».",
			"available_in": 1,
		})
	for world: Node3D in [past, today]:
		room.area(MESSAGE, world, "Placa", Vector3(11.9, 1.65, LobbyRoom3D.SOUTH - 0.08), Vector3(0.8, 0.4, 0.1), {
			"prompt_text": "Ler placa",
			"message": "«Grand Hotel Aurora. Inaugurado em 06/09/1921.»",
		})
	var past_door := room.area(ACTION, past, "Entrada", ENTRANCE, Vector3(2, 2.4, 0.4), {
		"prompt_text": "Examinar porta giratória", "available_in": 0})
	past_door.interacted.connect(_use_past_entrance)
	var today_door := room.area(ACTION, today, "Entrada", ENTRANCE, Vector3(2, 2.4, 0.4), {
		"prompt_text": "Examinar entrada", "available_in": 1})
	today_door.interacted.connect(_use_present_entrance)
	latch_key = room.key_visual(past, Vector3(10.85, 1.05, LobbyRoom3D.SOUTH - 0.57), false)
	latch_key.rotation_degrees.y = 90
	chain = _build_chain(room, today)
	_restore()
	WorldState.flag_changed.connect(_on_flag)
	EraManager.era_changed.connect(_on_era_changed)


# --- Cofre (1923) ----------------------------------------------------------------------------

func _build_safe(room: ChapterRoom3D, past: Node3D) -> void:
	var safe := room.area(ACTION, past, "Cofre", SAFE + Vector3(0, 0.62, 0.56), Vector3(1.0, 0.9, 0.12), {
		"prompt_text": "Examinar cofre", "available_in": 0})
	safe.interacted.connect(_use_safe)
	# Aberta, a porta deixa ver o fundo escuro. A frente fixa fica por trás deste vão.
	safe_recess = room.box(past, SAFE + Vector3(0, 0.55, 0.552), Vector3(1.0, 0.98, 0.058), "dark", false)
	safe_door = Node3D.new()
	safe_door.name = "PortaCofre"
	safe_door.position = SAFE + Vector3(-0.52, 0.06, 0.585)
	safe_door.rotation_degrees.y = -25
	past.add_child(safe_door)
	room.box(safe_door, Vector3(0.52, 0.49, 0.025), Vector3(1.04, 0.98, 0.05), "lacquer", false)
	var dial := room.box(safe_door, Vector3(0.52, 0.56, 0.06), Vector3(0.2, 0.2, 0.03), "brass", false)
	dial.rotation_degrees.z = 45
	safe_key = room.key_visual(past, SAFE + Vector3(0.15, 0.32, 0.595), false)


func _use_safe(by: FirstPersonMotor) -> void:
	if not WorldState.is_set(SAFE_OPEN):
		var ui := CodeLockUI.open(get_tree(), SAFE_CODE)
		ui.solved.connect(func() -> void:
			WorldState.set_flag(SAFE_OPEN)
			_say("O segredo para no último número e a porta do cofre se solta."))
		_say("Riscada a lápis na porta: «o dia em que o Aurora se acendeu».")
	elif WorldState.is_set(SAFE_KEY_TAKEN):
		_say("O cofre está vazio.")
	elif by.get_held_item() != "":
		_say("Dentro do cofre há uma chave grande de latão. A mão está ocupada.")
	else:
		by.set_held_item(ENTRANCE_KEY)
		WorldState.set_flag(SAFE_KEY_TAKEN)
		_say("Helena pega a chave da porta principal.")


# --- Entrada principal -----------------------------------------------------------------------

func _use_past_entrance(by: FirstPersonMotor) -> void:
	if WorldState.is_set(FINAL):
		_say(KNOCK)
	elif WorldState.is_set(LATCH_1923):
		_say("As folhas não giram, como se alguém as segurasse do outro lado. Do outro lado do vidro, só a rua escura.")
	elif by.get_held_item() == ENTRANCE_KEY:
		by.set_held_item("")
		WorldState.set_flag(LATCH_1923)
		_say("A chave gira e a trava da porta giratória se solta. Mas as folhas não giram, como se alguém as segurasse do outro lado.")
	else:
		_say("A porta giratória está travada. A fechadura da trava fica no batente.")


func _use_present_entrance(by: FirstPersonMotor) -> void:
	if _leaving:
		return
	if WorldState.is_set(FINAL):
		_say("Tábuas e correntes. Pregadas por dentro. O cadeado está fechado de novo.")
		return
	if not WorldState.is_set(PADLOCK):
		if by.get_held_item() == MARTA_KEY:
			by.set_held_item("")
			WorldState.set_flag(PADLOCK)
			_say("A chave miúda gira no cadeado de 1979. A corrente escorrega das tábuas.")
		elif WorldState.is_set(LATCH_1923):
			_say("Tábuas e correntes, pregadas por dentro. Um cadeado prende a corrente. Por uma fresta, a lingueta da fechadura aparece recolhida.")
		else:
			_say("Tábuas e correntes, pregadas por dentro. Um cadeado prende a corrente.")
		return
	if not WorldState.is_set(LATCH_1923):
		_say("Sem a corrente, as tábuas podres mal seguram. Por baixo delas, a fechadura continua travada de ferrugem.")
		return
	_leave(by)


func _build_chain(room: ChapterRoom3D, today: Node3D) -> Node3D:
	var holder := Node3D.new()
	holder.name = "Corrente"
	today.add_child(holder)
	var face := LobbyRoom3D.SOUTH
	for i in 9:
		var link := MeshInstance3D.new()
		var ring := TorusMesh.new()
		ring.inner_radius = 0.025
		ring.outer_radius = 0.045
		ring.rings = 12
		ring.ring_segments = 6
		link.mesh = ring
		link.position = Vector3(ENTRANCE.x - 0.45 + i * 0.11, 1.35 - 0.12 * sin(i * 0.4), face - 0.1)
		link.rotation_degrees = Vector3(0, 90 if i % 2 == 0 else 0, 90)
		link.material_override = HotelMaterials.get_material("iron", true)
		holder.add_child(link)
	room.box(holder, Vector3(ENTRANCE.x + 0.05, 1.22, face - 0.11), Vector3(0.1, 0.12, 0.05), "iron", true)
	return holder


# --- Final -----------------------------------------------------------------------------------

## A luz de fora cega Lia; quando passa, ela está de novo no Saguão, de costas para a porta.
func _leave(by: FirstPersonMotor) -> void:
	_leaving = true
	var layer := CanvasLayer.new()
	layer.layer = 55
	var flash := ColorRect.new()
	flash.color = Color(1, 0.98, 0.92, 0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(flash)
	add_child(layer)
	var tween := create_tween()
	tween.tween_property(flash, "color:a", 1.0, 0.9)
	tween.tween_callback(func() -> void:
		by.global_position = RETURN_SPOT
		by.rotation.y = 0.0
		by.velocity = Vector3.ZERO
		WorldState.set_flag(FINAL))
	tween.tween_interval(0.6)
	tween.tween_property(flash, "color:a", 0.0, 1.6)
	tween.tween_callback(func() -> void:
		layer.queue_free()
		_leaving = false
		_say("Lá fora é o Saguão. Atrás de você, a porta está pregada de novo."))


func _on_era_changed(era: Era.Id) -> void:
	if era == Era.Id.PAST_1923 and WorldState.is_set(FINAL):
		_say(KNOCK)


func _restore() -> void:
	var open := WorldState.is_set(SAFE_OPEN)
	safe_door.visible = open
	safe_recess.visible = open
	safe_key.visible = open and not WorldState.is_set(SAFE_KEY_TAKEN)
	latch_key.visible = WorldState.is_set(LATCH_1923)
	chain.visible = not WorldState.is_set(PADLOCK) or WorldState.is_set(FINAL)


func _on_flag(key: String, _value: Variant) -> void:
	if key in [SAFE_OPEN, SAFE_KEY_TAKEN, LATCH_1923, PADLOCK, FINAL]:
		_restore()
	# Na dupla online, quem joga com Helena ouve as batidas quando Lia sai
	if key == FINAL and EraManager.current_era == Era.Id.PAST_1923 and NetSession.phase == NetSession.Phase.PLAYING:
		_say(KNOCK)


func _say(message: String) -> void:
	get_tree().call_group("hud", "show_message", message)
