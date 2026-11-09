class_name Updater
extends Node
## Botão Atualizar da recepção: lê o versao.json do último Release do GitHub e, se houver versão
## nova sobre o mesmo ZIP, baixa só o remendo (.pck com o que mudou). O PatchLoader o instala ao
## reiniciar. Versão nova de ZIP (Godot, plugin ou project.godot mudaram) abre a página do Release.
## Publicar: tools/publicar_versao.sh.

signal changed

enum State { OFF, CHECKING, UP_TO_DATE, PATCH, NEW_ZIP, DOWNLOADING, READY, FAILED }

const REPO := "rbtzinn/HotelSemSaida"
const MANIFEST_URL := "https://github.com/%s/releases/latest/download/versao.json" % REPO
const PAGE_URL := "https://github.com/%s/releases/latest" % REPO
const LOADER := preload("res://scripts/core/patch_loader.gd")

var state := State.OFF
## versao.json do Release (version, base, patch {url, size, sha256}, page).
var manifest: Dictionary = {}
var manifest_url := MANIFEST_URL
var folder := LOADER.DIR
## Falhou ao baixar (e não só ao procurar): a recepção oferece tentar de novo.
var download_failed := false
var _http: HTTPRequest


## O que fazer com o versao.json, dada a versão atual e a do ZIP instalado.
static func decide(data: Variant, local: String, base: String) -> State:
	if not data is Dictionary or not data.has("version"):
		return State.FAILED
	if GameVersion.compare(str(data.version), local) <= 0:
		return State.UP_TO_DATE
	var patch: Variant = data.get("patch")
	if str(data.get("base", "")) != base or not patch is Dictionary or str(patch.get("url", "")) == "":
		return State.NEW_ZIP
	return State.PATCH


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_http = HTTPRequest.new()
	add_child(_http)


func check() -> void:
	if state in [State.CHECKING, State.DOWNLOADING, State.READY]:
		return
	download_failed = false
	_set_state(State.CHECKING)
	_http.timeout = 20.0
	_http.download_file = ""
	if _http.request(manifest_url) != OK:
		_set_state(State.FAILED)
		return
	var reply: Array = await _http.request_completed
	var data: Variant = null
	if reply[0] == HTTPRequest.RESULT_SUCCESS and reply[1] == 200:
		data = JSON.parse_string((reply[3] as PackedByteArray).get_string_from_utf8())
	manifest = data if data is Dictionary else {}
	_set_state(decide(data, GameVersion.VERSION, GameVersion.base()))


## Tamanho do remendo em MB (para o botão).
func patch_megabytes() -> float:
	var patch: Variant = manifest.get("patch")
	return float(patch.get("size", 0))/1048576.0 if patch is Dictionary else 0.0


## Fração baixada (0..1).
func progress() -> float:
	var total := float(manifest.patch.get("size", 0)) if state == State.DOWNLOADING else 0.0
	return clampf(_http.get_downloaded_bytes()/total, 0.0, 1.0) if total > 0.0 else 0.0


func download() -> void:
	if state != State.PATCH:
		return
	var patch: Dictionary = manifest.patch
	DirAccess.make_dir_recursive_absolute(folder)
	var part := folder + LOADER.NEW_PACK + ".part"
	# O timeout vale para a requisição inteira: num download grande, cortaria no meio
	_http.timeout = 0.0
	_http.download_file = part
	_set_state(State.DOWNLOADING)
	if _http.request(str(patch.url)) != OK:
		_fail(part)
		return
	var reply: Array = await _http.request_completed
	_http.download_file = ""
	var file := FileAccess.open(part, FileAccess.READ)
	var size := file.get_length() if file != null else -1
	file = null
	if reply[0] != HTTPRequest.RESULT_SUCCESS or reply[1] != 200 or size != int(patch.get("size", -2)) \
			or FileAccess.get_sha256(part) != str(patch.get("sha256", "")).to_lower():
		_fail(part)
		return
	DirAccess.remove_absolute(folder + LOADER.NEW_PACK)
	DirAccess.rename_absolute(part, folder + LOADER.NEW_PACK)
	var info := FileAccess.open(folder + LOADER.NEW_INFO, FileAccess.WRITE)
	info.store_string(JSON.stringify({"version": str(manifest.version), "base": str(manifest.base)}))
	info.close()
	_set_state(State.READY)


## Abre o jogo de novo (o PatchLoader instala o remendo) e fecha este.
func restart() -> void:
	OS.create_process(OS.get_executable_path(), OS.get_cmdline_args())
	# Pelo caminho: o teste carrega esta classe antes de os autoloads existirem
	get_node("/root/Audio").quit()


func open_page() -> void:
	OS.shell_open(str(manifest.get("page", PAGE_URL)))


func _fail(part: String) -> void:
	DirAccess.remove_absolute(part)
	download_failed = true
	_set_state(State.FAILED)


func _set_state(value: State) -> void:
	state = value
	changed.emit()
