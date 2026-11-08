extends Node
## Cada máquina simula apenas sua viajante. A rede transmite as mudanças de
## estado em ordem. Abrir um bilhete, andar ou passar por uma porta é local.
signal lobby_changed
enum Phase { OFF, HOSTING, JOINING, WAITING, PLAYING }
const RULES := preload("res://scripts/online/coop_progress.gd")
const PORT := 7777
## Suba a cada mudança nas regras de flags: versões diferentes não podem jogar juntas.
const PROTOCOL := 4
const LOBBY := "res://scenes/ui/entrada.tscn"
const HOTEL := "res://scenes/rooms/saguao_3d.tscn"
const ROOMS := [HOTEL, "res://scenes/rooms/cozinha_3d.tscn", "res://scenes/rooms/manutencao_3d.tscn",
	"res://scenes/rooms/biblioteca_3d.tscn", "res://scenes/rooms/caldeiras_3d.tscn",
	"res://scenes/rooms/quartos_3d.tscn"]
const SAVE := "user://dupla.save"
## Teto contra arquivo adulterado; o jogo completo usa bem menos.
const MAX_SAVED_FLAGS := 1000
var phase := Phase.OFF
var local_era := Era.Id.PAST_1923
var partner := 0
var status := ""
var is_host := false
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
		_check_in.rpc_id(1, PROTOCOL)

@rpc("any_peer", "call_remote", "reliable")
func _check_in(version: int) -> void:
	var guest := multiplayer.get_remote_sender_id()
	if not is_host or phase != Phase.HOSTING or guest <= 1:
		return
	if version != PROTOCOL:
		_refuse.rpc_id(guest)
		return
	partner = guest
	phase = Phase.WAITING
	_welcome.rpc_id(guest, Era.other(local_era))
	_message("Dupla completa. Você joga com %s." % Era.character_name(local_era))

@rpc("authority", "call_remote", "reliable")
func _refuse() -> void:
	leave.call_deferred("As versões dos jogos são diferentes.", false)

@rpc("authority", "call_remote", "reliable")
func _welcome(era: int) -> void:
	if phase != Phase.JOINING or era not in [0, 1]:
		return
	local_era = era as Era.Id
	partner = 1
	phase = Phase.WAITING
	_deadline = 0
	_message("Você joga com %s. Aguardando o anfitrião iniciar." % Era.character_name(local_era))

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
	if data.is_empty():
		WorldState.set_flag(StoryCutscenes.OPENING_PENDING)
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
	# Cutscenes vistas são de cada máquina
	if phase != Phase.PLAYING or _receiving or key.begins_with(Cutscene.PREFIX):
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
	# Saves da versão 1 só têm flags que a versão atual também aceita
	if data.get("version") not in [1, PROTOCOL] or not _valid_spot(data.get("Lia")) or not _valid_spot(data.get("Helena")):
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
	# Cutscenes vistas são de cada máquina e ficam fora do save da dupla
	for key: String in flags.keys():
		if key.begins_with(Cutscene.PREFIX):
			flags.erase(key)
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
		_message("O visitante saiu. Aguardando outra conexão.")
	elif phase == Phase.PLAYING:
		leave.call_deferred("A outra pessoa saiu da partida.", false)

func leave(reason: String = "", notify_partner: bool = true) -> void:
	if phase == Phase.OFF:
		return
	if notify_partner and partner in multiplayer.get_peers():
		_goodbye.rpc_id(partner)
		var peer := multiplayer.multiplayer_peer as ENetMultiplayerPeer
		if peer and peer.host:
			peer.host.flush()
	var in_game := phase == Phase.PLAYING
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
			leave.call_deferred("A outra pessoa saiu da sala.", false)

func _process(_delta: float) -> void:
	if phase == Phase.JOINING and Time.get_ticks_msec() >= _deadline:
		leave("Sem resposta. Confira se a sala e o túnel UDP estão abertos.")

func _message(text: String) -> void:
	status = text
	lobby_changed.emit()
