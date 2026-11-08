extends Node
## Som do jogo (autoload `Audio`): ambientes que continuam de uma sala para outra e efeitos curtos.
## 1923 tem jazz abafado vindo do Salão e burburinho; hoje, vento e goteiras. A troca de época
## distorce os ambientes por um instante. Cada sala dá o volume de cada camada (ROOMS).
## Sons CC0 do OpenGameArt em art/audio/ (créditos em art/audio/CREDITOS.md).

const AMBIENT := "res://art/audio/ambiente/"
const EFFECTS := "res://art/audio/efeitos/"
## Volume de cada camada por sala, em dB (ausente = desligada).
## jazz e burburinho tocam em 1923; vento e goteiras hoje; tique (relógio) nas duas.
const ROOMS := {
	"entrada": {"jazz": -18.0},
	"saguao_3d": {"jazz": -15.0, "burburinho": -15.0, "vento": -17.0, "goteiras": -13.0},
	"cozinha_3d": {"jazz": -27.0, "burburinho": -21.0, "vento": -22.0, "goteiras": -11.0},
	"manutencao_3d": {"jazz": -33.0, "vento": -27.0, "goteiras": -9.0},
	"biblioteca_3d": {"jazz": -24.0, "burburinho": -28.0, "vento": -18.0, "goteiras": -15.0},
	"caldeiras_3d": {"jazz": -34.0, "vento": -25.0, "goteiras": -9.0},
	"quartos_3d": {"jazz": -21.0, "burburinho": -27.0, "vento": -18.0, "goteiras": -14.0},
	"salao_3d": {"jazz": -9.0, "burburinho": -13.0, "vento": -15.0, "goteiras": -15.0},
	"torre_3d": {"jazz": -30.0, "vento": -8.0, "goteiras": -26.0, "tique": -14.0},
}
const LAYERS := {
	"jazz": ["jazz_1923", Era.Id.PAST_1923],
	"burburinho": ["burburinho_1923", Era.Id.PAST_1923],
	"vento": ["vento_hoje", Era.Id.PRESENT],
	"goteiras": ["goteiras_hoje", Era.Id.PRESENT],
	"tique": ["tique_relogio", -1],
}
const SILENT := -60.0
const FADE := 1.2
const AMBIENT_BUS := &"Ambiente"
const EFFECTS_BUS := &"Efeitos"

var _layers: Dictionary = {}
var _fades: Dictionary = {}
var _cache: Dictionary = {}
var _distortion: AudioEffectDistortion
var _room := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().auto_accept_quit = false
	_make_buses()
	for layer: String in LAYERS:
		var player := AudioStreamPlayer.new()
		player.name = layer
		player.bus = AMBIENT_BUS
		player.volume_db = SILENT
		var stream := load(AMBIENT + str(LAYERS[layer][0]) + ".ogg") as AudioStreamOggVorbis
		stream.loop = true
		player.stream = stream
		add_child(player)
		_layers[layer] = player
	EraManager.era_changed.connect(_on_era_changed)
	get_tree().scene_changed.connect(_refresh)
	_refresh.call_deferred()


## Toca um efeito de art/audio/efeitos/ (sem extensão). `variation` sorteia a altura (±).
func play(sound: String, volume_db: float = 0.0, variation: float = 0.05) -> void:
	if sound == "":
		return
	var stream := _effect(sound)
	if stream == null:
		push_warning("Som não encontrado: " + sound)
		return
	var player := AudioStreamPlayer.new()
	player.bus = EFFECTS_BUS
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + randf_range(-variation, variation)
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


## Um de vários sons numerados (ex.: "passo", 6 → passo_1..passo_6).
func play_one_of(prefix: String, count: int, volume_db: float = 0.0, variation: float = 0.05) -> void:
	play("%s_%d" % [prefix, randi_range(1, count)], volume_db, variation)


func current_room() -> String:
	return _room


func _effect(sound: String) -> AudioStream:
	if not _cache.has(sound):
		var path := EFFECTS + sound + ".ogg"
		_cache[sound] = load(path) if ResourceLoader.exists(path) else null
	return _cache[sound]


func _make_buses() -> void:
	for bus_name: StringName in [AMBIENT_BUS, EFFECTS_BUS]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus_name)
			AudioServer.set_bus_send(index, &"Master")
	_distortion = AudioEffectDistortion.new()
	_distortion.mode = AudioEffectDistortion.MODE_LOFI
	_distortion.drive = 0.0
	var ambient := AudioServer.get_bus_index(AMBIENT_BUS)
	AudioServer.add_bus_effect(ambient, _distortion)
	AudioServer.set_bus_effect_enabled(ambient, 0, false)


func _refresh() -> void:
	var scene := get_tree().current_scene
	_room = scene.scene_file_path.get_file().get_basename() if scene else ""
	_apply(EraManager.current_era, FADE)


func _apply(era: Era.Id, fade: float) -> void:
	var levels: Dictionary = ROOMS.get(_room, {})
	for layer: String in _layers:
		var player: AudioStreamPlayer = _layers[layer]
		var layer_era: int = LAYERS[layer][1]
		var audible := levels.has(layer) and (layer_era == -1 or layer_era == era)
		var target: float = float(levels[layer]) if audible else SILENT
		if audible and not player.playing:
			player.play(randf() * player.stream.get_length())
		# Um fade novo substitui o anterior (senão o "parar" antigo calaria a camada de novo)
		if _fades.has(layer) and (_fades[layer] as Tween).is_valid():
			(_fades[layer] as Tween).kill()
		var tween := create_tween()
		tween.tween_property(player, "volume_db", target, fade)
		if not audible:
			tween.tween_callback(player.stop)
		_fades[layer] = tween


## A troca de época corta o som com uma distorção rápida e troca as camadas.
func _on_era_changed(era: Era.Id) -> void:
	play("troca_epoca", -6.0)
	var ambient := AudioServer.get_bus_index(AMBIENT_BUS)
	AudioServer.set_bus_effect_enabled(ambient, 0, true)
	_distortion.drive = 0.7
	var tween := create_tween()
	tween.tween_property(_distortion, "drive", 0.0, 0.45)
	tween.tween_callback(func() -> void: AudioServer.set_bus_effect_enabled(ambient, 0, false))
	_apply(era, 0.35)


## Fecha o jogo calando os sons antes (Sair do menu e o X da janela passam por aqui).
func quit() -> void:
	for player: AudioStreamPlayer in _layers.values():
		player.stop()
	for child in get_children():
		if child is AudioStreamPlayer:
			(child as AudioStreamPlayer).stop()
	# O servidor de áudio solta as reproduções no quadro seguinte
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit()


## Ao fechar o jogo, solta os streams que ainda tocam (senão o Godot avisa de recursos presos).
func _exit_tree() -> void:
	for player: AudioStreamPlayer in _layers.values():
		player.stop()
		player.stream = null
	_cache.clear()
