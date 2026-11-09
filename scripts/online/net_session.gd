extends Node
## Cada máquina simula apenas sua viajante. A rede transmite as mudanças de
## estado em ordem. Abrir um bilhete, andar ou passar por uma porta é local.
## Duas formas de abrir a sala: por código (host_room/join_room, Epic Online Services em
## `rooms`) ou, como plano B, por endereço:porta (host/join, ENet direto ou túnel do Playit).
signal lobby_changed
## OPENING: falando com a Epic antes de a sala existir.
enum Phase { OFF, HOSTING, JOINING, WAITING, PLAYING, OPENING }
const RULES := preload("res://scripts/online/coop_progress.gd")
const EPIC := preload("res://scripts/online/epic_online.gd")
const PORT := 7777
## Suba a cada mudança nas regras de flags: versões diferentes não podem jogar juntas.
const PROTOCOL := 8
const MAX_NAME := 20
const LOBBY := "res://scenes/ui/entrada.tscn"
const HOTEL := "res://scenes/rooms/saguao_3d.tscn"
const ROOMS := [HOTEL, "res://scenes/rooms/cozinha_3d.tscn", "res://scenes/rooms/manutencao_3d.tscn",
	"res://scenes/rooms/biblioteca_3d.tscn", "res://scenes/rooms/caldeiras_3d.tscn",
	"res://scenes/rooms/quartos_3d.tscn", "res://scenes/rooms/salao_3d.tscn",
	"res://scenes/rooms/torre_3d.tscn"]
const SAVE := "user://dupla.save"
## Teto contra arquivo adulterado; o jogo completo usa bem menos.
const MAX_SAVED_FLAGS := 1000
var phase := Phase.OFF
var local_era := Era.Id.PAST_1923
var partner := 0
var status := ""
var is_host := false
## Código da sala aberta pela Epic (vazio na sala por endereço).
var room_code := ""
var partner_name := ""
## Quem abre as salas por código: open_room(nome), enter_room(código, nome), close_room().
## Os testes trocam por um substituto local.
var rooms: Node
var _receiving := false
var _deadline := 0
var _saving := false
var _returning := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	multiplayer.connected_to_server.connect(_connected)
	multiplayer.connection_failed.connect(func() -> void: leave.call_deferred("Não foi possível conectar. Confira o endereço e a porta.", false))
	multiplayer.server_disconnected.connect(func() -> void: leave.call_deferred("O anfitrião encerrou a conexão.", false))
	multiplayer.peer_disconnected.connect(_lost_peer)
	WorldState.flag_changed.connect(_publish)
	rooms = EPIC.new()
	rooms.name = "Epic"
	add_child(rooms)

## Nome que a outra pessoa vê (Configurações; também vai para o login anônimo da Epic).
func player_name() -> String:
	var name_text := clean_name(str(Settings.data.get("player_name", "")))
	return name_text if name_text != "" else "Hóspede"

static func clean_name(text: String) -> String:
	var name_text := ""
	for character in text.strip_edges():
		if character.unicode_at(0) >= 32:
			name_text += character
	return name_text.substr(0, MAX_NAME).strip_edges()

## Cria a sala por código (Epic). O código aparece em `room_code`.
func host_room(era: Era.Id) -> void:
	if phase != Phase.OFF or _returning:
		return
	phase = Phase.OPENING
	is_host = true
	local_era = era
	_message("Abrindo a sala…")
	var result: Dictionary = await rooms.open_room(player_name())
	if phase != Phase.OPENING:
		# Voltou antes de a sala abrir
		if result.has("peer"):
			(result.peer as MultiplayerPeer).close()
			rooms.close_room()
		return
	if result.has("error"):
		phase = Phase.OFF
		is_host = false
		_message(result.error)
		return
	multiplayer.multiplayer_peer = result.peer
	room_code = result.code
	phase = Phase.HOSTING
	_message("Sala aberta. Passe o código para a outra pessoa.")

## Entra na sala de um código.
func join_room(text: String) -> void:
	if phase != Phase.OFF or _returning:
		return
	var code := EPIC.normalize_code(text)
	if not EPIC.valid_code(code):
		_message("O código tem %d letras e números, como K7M2QX." % EPIC.CODE_LENGTH)
		return
	phase = Phase.OPENING
	is_host = false
	room_code = code
	_message("Procurando a sala %s…" % code)
	var result: Dictionary = await rooms.enter_room(code, player_name())
	if phase != Phase.OPENING:
		if result.has("peer"):
			(result.peer as MultiplayerPeer).close()
			rooms.close_room()
		return
	if result.has("error"):
		phase = Phase.OFF
		room_code = ""
		_message(result.error)
		return
	phase = Phase.JOINING
	multiplayer.multiplayer_peer = result.peer
	_deadline = Time.get_ticks_msec()+20000
	_message("Sala encontrada. Conectando…")

func host(era: Era.Id, port: int = PORT) -> void:
	if phase != Phase.OFF or _returning:
		return
	var peer := ENetMultiplayerPeer.new()
	peer.set_bind_ip("0.0.0.0")
	if peer.create_server(port, 1) != OK:
		_message("Porta UDP %d indisponível. Confira se já existe uma sala aberta." % port)
		return
	local_era = era
	is_host = true
	phase = Phase.HOSTING
	multiplayer.multiplayer_peer = peer
	_message("Aguardando a segunda pessoa · UDP %d" % port)

func join(address: String) -> void:
	if phase != Phase.OFF or _returning:
		return
	var fields := address.strip_edges().split(":")
	var port := PORT
	if fields.size() == 2 and fields[1].is_valid_int():
		port = fields[1].to_int()
	elif fields.size() != 1:
		_message("Use o endereço do servidor seguido da porta, como hotel.exemplo:7777.")
		return
	var hostname := fields[0].strip_edges()
	if hostname.is_empty() or hostname.contains("/") or port < 1 or port > 65535:
		_message("Confira o endereço e use uma porta entre 1 e 65535.")
		return
	var peer := ENetMultiplayerPeer.new()
	peer.set_bind_ip("0.0.0.0")
	if peer.create_client(hostname, port) != OK:
		_message("Não foi possível abrir a conexão com esse endereço.")
		return
	phase = Phase.JOINING
	multiplayer.multiplayer_peer = peer
	_deadline = Time.get_ticks_msec()+15000
	_message("Conectando à recepção…")

func _connected() -> void:
	if phase == Phase.JOINING:
		_check_in.rpc_id(1, PROTOCOL, player_name(), GameVersion.VERSION)

@rpc("any_peer", "call_remote", "reliable")
func _check_in(version: int, guest_name: String = "", game_version: String = "") -> void:
	var guest := multiplayer.get_remote_sender_id()
	if not is_host or phase != Phase.HOSTING or guest <= 1:
		return
	if version != PROTOCOL or game_version != GameVersion.VERSION:
		# Remendos diferentes podem ter enigmas diferentes: as duas cópias precisam ser da mesma versão
		_refuse.rpc_id(guest, GameVersion.VERSION)
		_message("%s tentou entrar com a versão %s do jogo; a sua é %s. Atualizem na recepção." % [
				_shown_name(guest_name), game_version if game_version != "" else "antiga", GameVersion.VERSION])
		return
	partner = guest
	partner_name = _shown_name(guest_name)
	phase = Phase.WAITING
	_welcome.rpc_id(guest, Era.other(local_era), player_name())
	_message(_pair_text())

static func _shown_name(text: Variant) -> String:
	var name_text := clean_name(str(text)) if text is String else ""
	return name_text if name_text != "" else "A outra pessoa"

func _pair_text() -> String:
	return "%s está na sala e fica com %s. Você fica com %s." % [partner_name,
		_role_text(Era.other(local_era)), _role_text(local_era)]

static func _role_text(era: Era.Id) -> String:
	return "Helena (1923)" if era == Era.Id.PAST_1923 else "Lia (hoje)"

## O anfitrião troca de personagem até começar; a outra pessoa recebe a outra na hora.
func choose_era(era: Era.Id) -> void:
	if not is_host or phase not in [Phase.HOSTING, Phase.WAITING, Phase.OPENING] or era == local_era:
		return
	local_era = era
	if phase == Phase.WAITING:
		_assign.rpc_id(partner, Era.other(era))
		_message(_pair_text())
	else:
		lobby_changed.emit()

@rpc("authority", "call_remote", "reliable")
func _assign(era: int) -> void:
	if phase != Phase.WAITING or is_host or era not in [0, 1]:
		return
	local_era = era as Era.Id
	_message(_guest_text())

func _guest_text() -> String:
	return "Você está na sala de %s e fica com %s. Aguardando começar." % [partner_name, _role_text(local_era)]

@rpc("authority", "call_remote", "reliable")
func _refuse(host_version: String = "") -> void:
	leave.call_deferred("As versões dos jogos são diferentes (a sua é %s; a do anfitrião, %s). Atualizem na recepção." % [
			GameVersion.VERSION, host_version if host_version != "" else "outra"], false)

@rpc("authority", "call_remote", "reliable")
func _welcome(era: int, host_name: String = "") -> void:
	if phase != Phase.JOINING or era not in [0, 1]:
		return
	local_era = era as Era.Id
	partner = 1
	partner_name = _shown_name(host_name)
	phase = Phase.WAITING
	_deadline = 0
	_message(_guest_text())

func start(resume: bool = false) -> void:
	if not is_host or phase != Phase.WAITING:
		return
	var data := {}
	if resume:
		var file := FileAccess.open(SAVE, FileAccess.READ)
		var saved: Variant = file.get_var(false) if file else null
		if not saved is Dictionary or not _valid_save(saved):
			_message("Não foi possível ler o save da dupla.")
			return
		data = saved
	_begin.rpc_id(partner, data)
	_begin(data)

@rpc("authority", "call_remote", "reliable")
func _begin(data: Dictionary) -> void:
	if phase != Phase.WAITING or (not data.is_empty() and not _valid_save(data)):
		return
	phase = Phase.PLAYING
	RoomManager.clear_away()
	WorldState.load_dict(data.get("flags", {}))
	EraManager.set_era(local_era)
	var spot: Dictionary = data.get(Era.character_name(local_era), {})
	get_tree().change_scene_to_file(spot.get("room", HOTEL))
	await get_tree().scene_changed
	if phase == Phase.PLAYING and not spot.is_empty():
		var motor := get_tree().current_scene.get_node(Era.character_name(local_era)) as FirstPersonMotor
		motor.position = spot.position
		motor.rotation.y = spot.yaw
		motor.get_node("Head").rotation.x = spot.pitch

func _publish(key: String, value: Variant) -> void:
	if phase != Phase.PLAYING or _receiving:
		return
	if RULES.allowed(local_era, key, value):
		_receive_flag.rpc_id(partner, key, value)
	elif OS.is_debug_build() and not RULES.allowed(Era.other(local_era), key, value):
		# Flag nova esquecida em coop_progress.gd: não chega ao outro jogador
		push_warning("NetSession: flag '%s' fora das regras do online" % key)

@rpc("any_peer", "call_remote", "reliable")
func _receive_flag(key: String, value: Variant) -> void:
	if phase != Phase.PLAYING or multiplayer.get_remote_sender_id() != partner:
		return
	if RULES.allowed(Era.other(local_era), key, value):
		_receiving = true
		WorldState.set_flag(key, value)
		_receiving = false

func _spot() -> Dictionary:
	var room := get_tree().current_scene
	if RoomManager.is_changing() or not room or room.scene_file_path not in ROOMS:
		return {}
	var motor := room.get_node(Era.character_name(local_era)) as FirstPersonMotor
	return {"room":room.scene_file_path, "position":motor.get_save_position(),
		"yaw":motor.rotation.y, "pitch":motor.get_node("Head").rotation.x}

static func _valid_spot(spot: Variant) -> bool:
	return spot is Dictionary and spot.get("room", "") in ROOMS and spot.get("position") is Vector3 \
		and spot.position.is_finite() and spot.get("yaw") is float and is_finite(spot.yaw) \
		and spot.get("pitch") is float and is_finite(spot.pitch)

static func _valid_save(data: Dictionary) -> bool:
	# Saves de versões anteriores só têm flags que a versão atual também aceita
	var version: Variant = data.get("version")
	if not (version is int and version >= 1 and version <= PROTOCOL) \
			or not _valid_spot(data.get("Lia")) or not _valid_spot(data.get("Helena")):
		return false
	var flags: Variant = data.get("flags")
	if not flags is Dictionary or flags.size() > MAX_SAVED_FLAGS:
		return false
	for key: Variant in flags:
		if not key is String or not (RULES.allowed(0, key, flags[key]) or RULES.allowed(1, key, flags[key])):
			return false
	return true

func save_duo() -> void:
	if phase != Phase.PLAYING or not is_host or _saving:
		return
	_saving = true
	_ask_spot.rpc_id(partner)

@rpc("authority", "call_remote", "reliable")
func _ask_spot() -> void:
	if phase == Phase.PLAYING:
		_save_with.rpc_id(1, _spot())

@rpc("any_peer", "call_remote", "reliable")
func _save_with(guest: Dictionary) -> void:
	if not is_host or not _saving or multiplayer.get_remote_sender_id() != partner:
		return
	_saving = false
	var flags := WorldState.to_dict()
	var data := {"version":PROTOCOL, "flags":flags}
	data[Era.character_name(local_era)] = _spot()
	data[Era.character_name(Era.other(local_era))] = guest
	var message := "Aguarde os dois terminarem a travessia e salve de novo."
	if _valid_save(data):
		var file := FileAccess.open(SAVE+".tmp", FileAccess.WRITE)
		var saved := false
		if file:
			file.store_var(data)
			file.flush()
			saved = file.get_error() == OK
			file.close()
		if saved:
			saved = DirAccess.rename_absolute(SAVE+".tmp", SAVE) == OK
		message = "Progresso da dupla salvo." if saved else "Não foi possível gravar o save da dupla."
	get_tree().call_group("hud", "show_message", message)

func _lost_peer(id: int) -> void:
	if id != partner:
		return
	if is_host and phase == Phase.WAITING:
		partner = 0
		phase = Phase.HOSTING
		_message("%s saiu da sala. Aguardando outra pessoa." % partner_name)
		partner_name = ""
	elif phase == Phase.PLAYING:
		leave.call_deferred("%s saiu da partida." % partner_name, false)

func leave(reason: String = "", notify_partner: bool = true) -> void:
	if phase == Phase.OFF:
		return
	if phase == Phase.OPENING:
		# A sala ainda está abrindo: host_room/join_room desfazem ao terminar
		phase = Phase.OFF
		is_host = false
		room_code = ""
		_message(reason)
		return
	if notify_partner and partner in multiplayer.get_peers():
		_goodbye.rpc_id(partner)
		var peer := multiplayer.multiplayer_peer as ENetMultiplayerPeer
		if peer and peer.host:
			peer.host.flush()
	var in_game := phase == Phase.PLAYING
	if room_code != "":
		rooms.close_room()
	room_code = ""
	partner_name = ""
	phase = Phase.OFF
	partner = 0
	is_host = false
	_deadline = 0
	_saving = false
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	if in_game:
		_returning = true
		get_tree().call_group("room_overlay", "queue_free")
		get_tree().paused = false
		while RoomManager.is_changing():
			await get_tree().process_frame
		get_tree().change_scene_to_file(LOBBY)
		await get_tree().scene_changed
		_returning = false
	_message(reason)

@rpc("any_peer", "call_remote", "reliable")
func _goodbye() -> void:
	if multiplayer.get_remote_sender_id() == partner:
		if is_host and phase == Phase.WAITING:
			_lost_peer(partner)
		else:
			leave.call_deferred("%s saiu da sala." % partner_name, false)

func _process(_delta: float) -> void:
	if phase == Phase.JOINING and Time.get_ticks_msec() >= _deadline:
		leave("Sem resposta do anfitrião. Confira o código ou, por endereço, se o túnel UDP está aberto.")

func _message(text: String) -> void:
	status = text
	lobby_changed.emit()
