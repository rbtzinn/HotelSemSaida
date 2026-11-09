class_name Updater
extends Node
## Botão Atualizar da recepção: lê o versao.json do último Release do GitHub.
## - Versão nova sobre o mesmo ZIP: baixa só o remendo (.pck com o que mudou); o PatchLoader o instala
##   ao reiniciar.
## - Versão completa (Godot, plugin ou project.godot mudaram): baixa só os arquivos do jogo que mudaram
##   (lista "files" do versao.json; em geral só o .pck), ou o ZIP inteiro se a lista faltar, numa pasta
##   ao lado. Ao reiniciar, um script do PowerShell espera o jogo fechar, copia os arquivos novos por
##   cima da pasta do jogo e o abre de novo. Sem permissão de escrita na pasta do jogo (ou fora do
##   Windows), o botão abre a página do Release.
## Publicar: tools/publicar_versao.sh.

signal changed

enum State { OFF, CHECKING, UP_TO_DATE, PATCH, NEW_ZIP, DOWNLOADING, READY, FAILED }

const REPO := "rbtzinn/HotelSemSaida"
const MANIFEST_URL := "https://github.com/%s/releases/latest/download/versao.json" % REPO
const PAGE_URL := "https://github.com/%s/releases/latest" % REPO
const LOADER := preload("res://scripts/core/patch_loader.gd")
const NEW_GAME := "jogo-novo/"
const NEW_ZIP_FILE := "jogo-novo.zip"
const INSTALLER := "instalar.ps1"
## Arquivos sem os quais o ZIP não é o jogo.
const REQUIRED := ["HotelSemSaida.exe", "HotelSemSaida.pck"]

var state := State.OFF
## versao.json do Release (version, base, patch {url, size, sha256}, zip, zip_size, zip_sha256,
## files [{name, size, sha256, url}], page).
var manifest: Dictionary = {}
var manifest_url := MANIFEST_URL
var folder := LOADER.DIR
## Pasta do jogo instalado (onde o ZIP novo é copiado).
var game_dir := OS.get_executable_path().get_base_dir()
## Falhou ao baixar (e não só ao procurar): a recepção oferece tentar de novo.
var download_failed := false
## O que está baixado/pronto é um ZIP inteiro (e não um remendo).
var full := false
## Arquivos da versão completa que faltam ou mudaram nesta instalação (calculado ao procurar).
var needed: Array = []
var _done_bytes := 0
var _total_bytes := 0
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
	var result := decide(data, GameVersion.VERSION, GameVersion.base())
	if result == State.NEW_ZIP:
		needed = changed_files()
	_set_state(result)


## Tamanho do remendo em MB (para o botão).
func patch_megabytes() -> float:
	var patch: Variant = manifest.get("patch")
	return float(patch.get("size", 0))/1048576.0 if patch is Dictionary else 0.0


## Quanto a versão completa vai baixar, em MB (0 se o versao.json não diz).
func full_megabytes() -> float:
	if manifest.get("files") is Array:
		var total := 0
		for entry: Dictionary in needed:
			total += int(entry.get("size", 0))
		return total/1048576.0
	return float(manifest.get("zip_size", 0))/1048576.0


## Arquivos da lista "files" que não batem (tamanho e sha256) com os da pasta do jogo.
func changed_files() -> Array:
	var result: Array = []
	var files: Variant = manifest.get("files")
	if not files is Array:
		return result
	for entry: Variant in files:
		if not entry is Dictionary or str(entry.get("name", "")).contains("..") or str(entry.get("url", "")) == "":
			continue
		var local := game_dir.path_join(str(entry.name))
		var file := FileAccess.open(local, FileAccess.READ)
		var size := file.get_length() if file != null else -1
		file = null
		# Tamanho primeiro: o sha256 do .exe (~110 MB) só é calculado se o tamanho bater
		if size != int(entry.get("size", -2)) or FileAccess.get_sha256(local) != str(entry.get("sha256", "")).to_lower():
			result.append(entry)
	return result


## Dá para baixar e instalar o ZIP novo pelo jogo: Windows, jogo exportado e pasta do jogo gravável.
func can_install_full() -> bool:
	if OS.get_name() != "Windows" or str(manifest.get("zip", "")) == "":
		return false
	if not OS.has_feature("template") and game_dir == OS.get_executable_path().get_base_dir():
		return false  # no editor, a "pasta do jogo" seria a do Godot
	var probe := game_dir.path_join(".teste-escrita")
	var file := FileAccess.open(probe, FileAccess.WRITE)
	if file == null:
		return false
	file.close()
	DirAccess.remove_absolute(probe)
	return true


## Fração baixada (0..1).
func progress() -> float:
	if state != State.DOWNLOADING:
		return 0.0
	if full and _total_bytes > 0:
		return clampf(float(_done_bytes + _http.get_downloaded_bytes())/_total_bytes, 0.0, 1.0)
	var total := float(_http.get_body_size())
	if total <= 0.0:
		total = float(manifest.get("zip_size", 0)) if full else float(manifest.patch.get("size", 0))
	return clampf(_http.get_downloaded_bytes()/total, 0.0, 1.0) if total > 0.0 else 0.0


func download() -> void:
	if state != State.PATCH:
		return
	full = false
	var patch: Dictionary = manifest.patch
	var part := folder + LOADER.NEW_PACK + ".part"
	if not await _fetch(str(patch.url), part, int(patch.get("size", -2)), str(patch.get("sha256", ""))):
		return
	DirAccess.remove_absolute(folder + LOADER.NEW_PACK)
	DirAccess.rename_absolute(part, folder + LOADER.NEW_PACK)
	var info := FileAccess.open(folder + LOADER.NEW_INFO, FileAccess.WRITE)
	info.store_string(JSON.stringify({"version": str(manifest.version), "base": str(manifest.base)}))
	info.close()
	_set_state(State.READY)


## Baixa a versão completa em user://atualizacao/jogo-novo/: só os arquivos que mudaram, ou o ZIP.
func download_full() -> void:
	if state != State.NEW_ZIP or not can_install_full():
		return
	full = true
	_remove_tree(folder + NEW_GAME)
	if manifest.get("files") is Array:
		_done_bytes = 0
		_total_bytes = 0
		for entry: Dictionary in needed:
			_total_bytes += int(entry.get("size", 0))
		for entry: Dictionary in needed:
			var path := folder + NEW_GAME + str(entry.name)
			DirAccess.make_dir_recursive_absolute(path.get_base_dir())
			if not await _fetch(str(entry.url), path, int(entry.get("size", -1)), str(entry.get("sha256", ""))):
				_remove_tree(folder + NEW_GAME)
				return
			_done_bytes += int(entry.get("size", 0))
		write_installer()
		_set_state(State.READY)
		return
	var part := folder + NEW_ZIP_FILE + ".part"
	if not await _fetch(str(manifest.zip), part, int(manifest.get("zip_size", -1)), str(manifest.get("zip_sha256", ""))):
		return
	if not extract(part, folder + NEW_GAME):
		_fail(part)
		return
	DirAccess.remove_absolute(part)
	write_installer()
	_set_state(State.READY)


## Extrai o ZIP sem a pasta de cima (HotelSemSaida/). Falso se não for o jogo.
func extract(zip_path: String, target: String) -> bool:
	_remove_tree(target)
	var reader := ZIPReader.new()
	if reader.open(zip_path) != OK:
		return false
	var names := reader.get_files()
	var found := 0
	for name in names:
		if name.ends_with("/"):
			continue
		var relative := name.substr(name.find("/") + 1) if name.contains("/") else name
		if relative in REQUIRED:
			found += 1
		var path := target + relative
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			reader.close()
			return false
		file.store_buffer(reader.read_file(name))
		file.close()
	reader.close()
	return found == REQUIRED.size()


## Script que espera este processo fechar, copia o jogo novo por cima e o abre (o teste passa outro
## processo e launch = false).
func write_installer(pid: int = -1, launch: bool = true) -> void:
	if pid < 0:
		pid = OS.get_process_id()
	var source := ProjectSettings.globalize_path(folder + NEW_GAME).trim_suffix("/")
	var lines := [
		"$ErrorActionPreference = 'Stop'",
		"$source = %s" % _quote(source.replace("/", "\\")),
		"$target = %s" % _quote(game_dir.replace("/", "\\")),
		"try { Wait-Process -Id %d -Timeout 60 -ErrorAction SilentlyContinue } catch {}" % pid,
		"for ($i = 0; $i -lt 20; $i++) {",
		"\ttry { Copy-Item -Path (Join-Path $source '*') -Destination $target -Recurse -Force; break }",
		"\tcatch { Start-Sleep -Milliseconds 500 }",
		"}",
		"Remove-Item -LiteralPath $source -Recurse -Force -ErrorAction SilentlyContinue",
	]
	if launch:
		lines.append("Start-Process -FilePath (Join-Path $target 'HotelSemSaida.exe') -WorkingDirectory $target")
	var file := FileAccess.open(folder + INSTALLER, FileAccess.WRITE)
	# Com BOM, o PowerShell 5.1 lê o UTF-8 certo (pastas com acento)
	file.store_buffer(PackedByteArray([0xEF, 0xBB, 0xBF]))
	file.store_string("\r\n".join(lines) + "\r\n")
	file.close()


## Abre o jogo de novo (o PatchLoader instala o remendo, ou o script troca o jogo inteiro) e fecha este.
func restart() -> void:
	if full:
		OS.create_process("powershell.exe", ["-NoProfile", "-ExecutionPolicy", "Bypass", "-WindowStyle", "Hidden",
				"-File", ProjectSettings.globalize_path(folder + INSTALLER)])
	else:
		OS.create_process(OS.get_executable_path(), OS.get_cmdline_args())
	# Pelo caminho: o teste carrega esta classe antes de os autoloads existirem
	get_node("/root/Audio").quit()


func open_page() -> void:
	OS.shell_open(str(manifest.get("page", PAGE_URL)))


## Baixa url em part e confere tamanho e sha256 (quando o versao.json os dá).
func _fetch(url: String, part: String, size: int, sha256: String) -> bool:
	DirAccess.make_dir_recursive_absolute(folder)
	# O timeout vale para a requisição inteira: num download grande, cortaria no meio
	_http.timeout = 0.0
	_http.download_file = part
	_set_state(State.DOWNLOADING)
	if _http.request(url) != OK:
		_fail(part)
		return false
	var reply: Array = await _http.request_completed
	_http.download_file = ""
	var file := FileAccess.open(part, FileAccess.READ)
	var got := file.get_length() if file != null else -1
	file = null
	if reply[0] != HTTPRequest.RESULT_SUCCESS or reply[1] != 200 or got <= 0 or (size >= 0 and got != size) \
			or (sha256 != "" and FileAccess.get_sha256(part) != sha256.to_lower()):
		_fail(part)
		return false
	return true


static func _quote(text: String) -> String:
	return "'" + text.replace("'", "''") + "'"


static func _remove_tree(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for sub in DirAccess.get_directories_at(path):
		_remove_tree(path.path_join(sub))
	for file in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(file))
	DirAccess.remove_absolute(path)


func _fail(part: String) -> void:
	DirAccess.remove_absolute(part)
	download_failed = true
	_set_state(State.FAILED)


func _set_state(value: State) -> void:
	state = value
	changed.emit()
