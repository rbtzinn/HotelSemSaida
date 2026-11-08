extends Node
## S4: cofre da gerência e entrada principal, o último enigma desta versão.
## Em 1923, o cofre tem duas fechaduras, em qualquer ordem: a chave do gerente (da torre), que
## fica na fechadura, e o segredo com a data em que o lustre se acendeu (1403). Helena pega a chave da
## porta principal e solta a trava da porta giratória. Hoje, a fechadura só cede porque Helena a
## deixou destrancada; a corrente posta em 1979 cai com a chave da bolsa de Marta.
## Com as duas trancas abertas, Lia tenta sair e volta a entrar no Saguão (`jogo.final`).

const ACTION := preload("res://scripts/interaction3d/interactable_3d.gd")
const MESSAGE := preload("res://scripts/interaction3d/message_interactable_3d.gd")
const SAFE_OPEN := "saguao.cofre.aberto"
const SAFE_KEY_TAKEN := "saguao.chave.entrada"
## As duas fechaduras do cofre: a chave do gerente girada (fica nela) e o segredo acertado.
const SAFE_MANAGER_KEY := "saguao.cofre.chave"
const SAFE_CODE_SET := "saguao.cofre.segredo"
const MANAGER_KEY := "chave_gerente"
## Onde fica a fechadura de chave, abaixo do segredo (mesma posição em LobbyRoom3D._build_safe).
const KEYHOLE := Vector3(-0.22, 0.4, 0.536)
const LATCH_1923 := "saguao.entrada.trava_1923"
const PADLOCK := "saguao.entrada.cadeado"
const FINAL := "jogo.final"
const SAFE_CODE := "1403"
const ENTRANCE_KEY := "chave_entrada"
const MARTA_KEY := "chave_portaria"
const SAFE := LobbyRoom3D.SAFE
## Abertura da porta do cofre (dobradiça à direita, abre para o Saguão); hoje solta, mais aberta.
const SAFE_OPEN_ANGLE := 90.0
const SAFE_OPEN_ANGLE_TODAY := 112.0
const ENTRANCE := Vector3(10.0, 1.2, 9.95)
## Onde Lia "entra" de novo, de costas para a porta que acabou de abrir.
const RETURN_SPOT := Vector3(10.0, 0.0, 9.4)
const KNOCK := "Do outro lado da porta giratória, alguém bate. Três batidas, como os passos de alguém que tateia no escuro."

var safe_door: Node3D
var safe_recess: MeshInstance3D
var safe_key: Node3D
## Chave do gerente na fechadura: na frente fechada e na porta aberta, em cada época.
var lock_keys: Dictionary = {}
var today_door: Node3D
var today_recess: MeshInstance3D
var today_safe: Node
var latch_key: Node3D
var chain: Node3D
var _leaving := false


func install(room: ChapterRoom3D) -> void:
	var past := room.get_node("World1923") as Node3D
	var today := room.get_node("WorldToday") as Node3D
	_build_safe(room, past)
	_build_today_safe(room, today)
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
	safe_door = _safe_door(room, past, "PortaCofre", SAFE_OPEN_ANGLE, false)
	safe_key = room.key_visual(past, SAFE + Vector3(0.15, 0.32, 0.595), false)
	_add_lock_keys(room, past, safe_door, false)


## Porta aberta do cofre, com colisão própria (o que se vê é o que colide). A dobradiça fica
## no canto direito; a folha ocupa x de -1,04 a 0 no espaço da dobradiça.
func _safe_door(room: ChapterRoom3D, world: Node3D, node_name: String, angle: float, present: bool) -> Node3D:
	var door := Node3D.new()
	door.name = node_name
	door.position = SAFE + Vector3(0.52, 0.06, 0.585)
	door.rotation_degrees.y = angle
	world.add_child(door)
	room.box(door, Vector3(-0.52, 0.49, 0.025), Vector3(1.04, 0.98, 0.05), "iron" if present else "lacquer", present)
	var dial := room.box(door, Vector3(-0.52, 0.56, 0.06), Vector3(0.2, 0.2, 0.03), "iron" if present else "brass", present)
	dial.rotation_degrees.z = 45
	var body := StaticBody3D.new()
	body.name = "Solido"
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.04, 0.98, 0.06)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = Vector3(-0.52, 0.49, 0.025)
	body.add_child(collision)
	door.add_child(body)
	return door


## Porta do cofre com a fechadura de chave, na mesma posição da frente fechada.
func _door_keyhole(room: ChapterRoom3D, door: Node3D, present: bool) -> void:
	var hole := Vector3(KEYHOLE.x - 0.52, KEYHOLE.y - 0.06, 0.056)
	room.box(door, hole, Vector3(0.07, 0.14, 0.012), "brass", present)
	room.box(door, hole + Vector3(0, -0.01, 0.007), Vector3(0.016, 0.06, 0.004), "dark", present)


## Chave do gerente enfiada e girada: uma na frente fechada, outra na porta aberta.
func _add_lock_keys(room: ChapterRoom3D, world: Node3D, door: Node3D, present: bool) -> void:
	_door_keyhole(room, door, present)
	var closed := room.key_visual(world, SAFE + KEYHOLE + Vector3(0, 0, 0.095), present)
	closed.rotation_degrees.y = 90
	var opened := room.key_visual(door, Vector3(KEYHOLE.x - 0.52, KEYHOLE.y - 0.06, 0.16), present)
	opened.rotation_degrees.y = 90
	lock_keys[present] = [closed, opened]


## Hoje: fechado e enferrujado, ou aberto e vazio se Helena o abriu.
func _build_today_safe(room: ChapterRoom3D, today: Node3D) -> void:
	today_safe = room.area(MESSAGE, today, "CofreHoje", SAFE + Vector3(0, 0.62, 0.56), Vector3(1.0, 0.9, 0.12), {
		"prompt_text": "Examinar cofre",
		"message": "",
		"available_in": 1,
	})
	today_recess = room.box(today, SAFE + Vector3(0, 0.55, 0.552), Vector3(1.0, 0.98, 0.058), "dark", true)
	# Solta nas dobradiças, mais aberta que em 1923
	today_door = _safe_door(room, today, "PortaCofreHoje", SAFE_OPEN_ANGLE_TODAY, true)
	_add_lock_keys(room, today, today_door, true)


func _today_message() -> String:
	var has_key := WorldState.is_set(SAFE_MANAGER_KEY)
	if WorldState.is_set(SAFE_OPEN):
		var text := "O cofre está aberto e vazio, a porta solta nas dobradiças."
		if has_key:
			text += " Na fechadura da porta ficou uma chave, presa pela ferrugem."
		return text
	if has_key:
		return ("Uma chave enferrujada está enfiada na fechadura de baixo, virada até o fim. "
			+ "O disco do segredo, acima dela, não gira mais.")
	return ("O cofre tem duas fechaduras: o disco do segredo, preso de ferrugem, e abaixo dele "
		+ "um buraco de chave entupido de pó. Na porta, nenhuma frase sobreviveu à umidade.")


func _use_safe(by: FirstPersonMotor) -> void:
	if not WorldState.is_set(SAFE_OPEN):
		if by.get_held_item() == MANAGER_KEY and not WorldState.is_set(SAFE_MANAGER_KEY):
			by.set_held_item("")
			WorldState.set_flag(SAFE_MANAGER_KEY)
			if WorldState.is_set(SAFE_CODE_SET):
				_open_safe()
			else:
				_say("A chave do gerente entra na fechadura de baixo e gira até o fim. Fica presa nela. A porta ainda não cede: falta o segredo.")
		elif WorldState.is_set(SAFE_CODE_SET):
			_say("O disco está travado no número certo. Abaixo dele, a fechadura de chave continua trancada.")
		else:
			var ui := CodeLockUI.open(get_tree(), SAFE_CODE)
			ui.solved.connect(_on_code_solved)
			_say("Riscada a lápis na porta: «o dia em que o Aurora se acendeu». Abaixo do segredo, uma fechadura de chave.")
	elif WorldState.is_set(SAFE_KEY_TAKEN):
		_say("O cofre está vazio.")
	elif by.get_held_item() != "":
		_say("Dentro do cofre há uma chave grande de latão. A mão está ocupada.")
	else:
		by.set_held_item(ENTRANCE_KEY)
		WorldState.set_flag(SAFE_KEY_TAKEN)
		_say("Helena pega a chave da porta principal.")


func _on_code_solved() -> void:
	WorldState.set_flag(SAFE_CODE_SET)
	if WorldState.is_set(SAFE_MANAGER_KEY):
		_open_safe()
	else:
		_say("O segredo para no último número e o disco trava. A porta não cede: falta a fechadura de chave, abaixo dele.")


func _open_safe() -> void:
	WorldState.set_flag(SAFE_OPEN)
	_say("Com a chave girada e o segredo certo, a porta do cofre se solta.")


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
	# Se uma tela em close pausar o jogo, o clarão continua sumindo por baixo dela
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
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
	_show_door(safe_door, open)
	safe_recess.visible = open
	safe_key.visible = open and not WorldState.is_set(SAFE_KEY_TAKEN)
	_show_door(today_door, open)
	today_recess.visible = open
	today_safe.set("message", _today_message())
	var turned := WorldState.is_set(SAFE_MANAGER_KEY)
	for present: bool in lock_keys:
		lock_keys[present][0].visible = turned and not open
		lock_keys[present][1].visible = turned and open
	latch_key.visible = WorldState.is_set(LATCH_1923)
	chain.visible = not WorldState.is_set(PADLOCK) or WorldState.is_set(FINAL)


## A porta fechada é a frente fixa do cofre: a folha aberta some e para de colidir.
func _show_door(door: Node3D, open: bool) -> void:
	door.visible = open
	(door.get_node("Solido").get_child(0) as CollisionShape3D).disabled = not open


func _on_flag(key: String, _value: Variant) -> void:
	if key in [SAFE_OPEN, SAFE_KEY_TAKEN, SAFE_MANAGER_KEY, SAFE_CODE_SET, LATCH_1923, PADLOCK, FINAL]:
		_restore()
	# Na dupla online, quem joga com Helena ouve as batidas quando Lia sai
	if key == FINAL and EraManager.current_era == Era.Id.PAST_1923 and NetSession.phase == NetSession.Phase.PLAYING:
		_say(KNOCK)


func _say(message: String) -> void:
	get_tree().call_group("hud", "show_message", message)
