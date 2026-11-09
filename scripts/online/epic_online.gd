extends Node
## Sala por código usando o Epic Online Services (plugin EOSG em addons/epic-online-services-godot).
## Login anônimo por Device ID (ninguém precisa de conta da Epic), um lobby de 2 vagas cujo id
## carrega o código e a conexão P2P da Epic (com relay) por baixo do multiplayer do Godot.
## O plugin é opcional: sem ele (ou sem as chaves), available() é falso e a recepção explica o
## que falta. Por isso nada aqui cita as classes do plugin pelo nome: tudo é buscado na hora.
## Interface de "sala" usada pelo NetSession: open_room() / enter_room(code) / close_room().

const ADDON := "res://addons/epic-online-services-godot/"
## Chaves do Epic Developer Portal (fora do git; modelo em epic_credentials.example.cfg).
const CREDENTIALS := "res://epic_credentials.cfg"
## Só letras e números, até 32 (regra do EOSGMultiplayerPeer)
const SOCKET := "hotelsemsaida"
const LOBBY_PREFIX := "HOTEL"
## Sem O/0 e I/1, para ninguém confundir ao ditar o código.
const CODE_CHARS := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
const CODE_LENGTH := 6

var _ready_for_rooms := false
var _logged_name := ""
var _lobby: Variant = null


## O plugin está instalado e ligado e as chaves existem.
static func available() -> bool:
	return ClassDB.class_exists("EOSGMultiplayerPeer") and FileAccess.file_exists(CREDENTIALS) \
		and Engine.get_main_loop().root.has_node("HPlatform")


## O que falta para a sala por código funcionar (vazio quando está tudo certo).
static func missing() -> String:
	if not ClassDB.class_exists("EOSGMultiplayerPeer") or not Engine.get_main_loop().root.has_node("HPlatform"):
		return "O plugin da Epic (EOSG) não está instalado ou ligado. Veja JOGAR-ONLINE.md."
	if not FileAccess.file_exists(CREDENTIALS):
		return "Faltam as chaves da Epic (epic_credentials.cfg). Veja JOGAR-ONLINE.md."
	return ""


static func random_code() -> String:
	var code := ""
	for i in CODE_LENGTH:
		code += CODE_CHARS[randi() % CODE_CHARS.length()]
	return code


## Deixa o código digitado no formato do jogo (maiúsculas, sem espaços nem traços).
static func normalize_code(text: String) -> String:
	var code := ""
	for character in text.to_upper():
		if character in CODE_CHARS:
			code += character
	return code


static func valid_code(code: String) -> bool:
	if code.length() != CODE_LENGTH:
		return false
	for character in code:
		if not character in CODE_CHARS:
			return false
	return true


## Cria a sala. Devolve {"peer", "code"} ou {"error"}.
func open_room(player_name: String) -> Dictionary:
	var error := await _login(player_name)
	if error != "":
		return {"error": error}
	var eos: Script = load(ADDON + "eos.gd")
	for attempt in 4:
		var code := random_code()
		var opts: Variant = eos.Lobby.CreateLobbyOptions.new()
		opts.lobby_id = LOBBY_PREFIX + code
		opts.bucket_id = "hotel:%d" % NetSession.PROTOCOL
		opts.max_lobby_members = 2
		opts.presence_enabled = false
		opts.enable_rtc_room = false
		opts.enable_join_by_id = true
		opts.allow_invites = false
		opts.local_rtc_options = null
		var lobby: Variant = await _h("HLobbies").create_lobby_async(opts)
		if lobby == null:
			continue  # código repetido (ou falha passageira): tenta outro
		_lobby = lobby
		var peer: MultiplayerPeer = ClassDB.instantiate("EOSGMultiplayerPeer")
		if peer.create_server(SOCKET) != OK:
			await close_room()
			return {"error": "Não foi possível abrir a conexão da Epic."}
		return {"peer": peer, "code": code}
	return {"error": "A Epic não criou a sala. Confira a internet e tente de novo."}


## Entra na sala do código. Devolve {"peer"} ou {"error"}.
func enter_room(code: String, player_name: String) -> Dictionary:
	var error := await _login(player_name)
	if error != "":
		return {"error": error}
	var lobby: Variant = await _h("HLobbies").join_by_id_async(LOBBY_PREFIX + code)
	if lobby == null:
		return {"error": "Nenhuma sala com o código %s. Confira o código com o anfitrião." % code}
	_lobby = lobby
	var owner: String = lobby.owner_product_user_id
	var peer: MultiplayerPeer = ClassDB.instantiate("EOSGMultiplayerPeer")
	if owner == "" or peer.create_client(SOCKET, owner) != OK:
		await close_room()
		return {"error": "Não foi possível ligar ao anfitrião pela Epic."}
	return {"peer": peer}


## Sai do lobby (o anfitrião o desfaz, para o código não ficar ocupado).
func close_room() -> void:
	var lobby: Variant = _lobby
	_lobby = null
	if lobby == null or not lobby.is_valid():
		return
	if lobby.is_owner():
		await lobby.destroy_async()
	else:
		await lobby.leave_async()


func _login(player_name: String) -> String:
	var problem := missing()
	if problem != "":
		return problem
	if not _ready_for_rooms:
		var creds := ConfigFile.new()
		if creds.load(CREDENTIALS) != OK:
			return "Não foi possível ler epic_credentials.cfg."
		var hcreds: Variant = load(ADDON + "heos/hcredentials.gd").new()
		hcreds.product_name = "Hotel Sem Saida"
		# O Godot 4 registra application/config/version com "" por padrão; vazio, a Epic recusa (InvalidParameters)
		var version := str(ProjectSettings.get_setting("application/config/version", "")).strip_edges()
		hcreds.product_version = version if version != "" else "1.0"
		for key: String in ["product_id", "sandbox_id", "deployment_id", "client_id", "client_secret",
				"encryption_key"]:
			hcreds.set(key, str(creds.get_value("epic", key, "")).strip_edges())
		if not await _h("HPlatform").setup_eos_async(hcreds):
			return "A Epic recusou as chaves. Confira epic_credentials.cfg."
		# Sem conta da Epic não há presença; o lobby também não deve tentar usá-la
		_h("HLobbies").presence_enabled = false
		_h("HLobbies").local_rtc_options = null
		_ready_for_rooms = true
	if _logged_name == "":
		if not await _h("HAuth").login_anonymous_async(player_name):
			return "Não foi possível entrar na Epic. Confira a internet."
		_logged_name = player_name
	return ""


func _h(singleton: String) -> Node:
	return get_node("/root/" + singleton)
