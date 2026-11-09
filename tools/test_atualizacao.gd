extends SceneTree
## Botão Atualizar: comparação de versões, decisão pelo versao.json, download do remendo (servidor
## HTTP local, sem internet), conferência do sha256 e instalação pelo PatchLoader.
## Usa user://teste_atualizacao/ (não mexe no remendo de verdade).
const FOLDER := "user://teste_atualizacao/"
const LOADER := preload("res://scripts/core/patch_loader.gd")
const MARK := "res://teste_remendo_marca.txt"
var _files: Dictionary = {}
var _server := TCPServer.new()
var _serving := true

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, what: String) -> bool:
	if not ok:
		printerr("FAIL: ", what)
		_finish(1)
	return ok

func _finish(code: int) -> void:
	_serving = false
	_server.stop()
	Updater._remove_tree(FOLDER.trim_suffix("/"))
	quit(code)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(FOLDER)
	for file in DirAccess.get_files_at(FOLDER):
		DirAccess.remove_absolute(FOLDER + file)
	# Versões
	for case: Array in [["1.0.0", "1.0.0", 0], ["1.0.1", "1.0.0", 1], ["1.0.9", "1.0.10", -1], ["1.1", "1.0.5", 1],
			["2.0.0", "10.0.0", -1]]:
		if not _check(GameVersion.compare(case[0], case[1]) == case[2], "compare %s %s" % [case[0], case[1]]):
			return
	# Decisão
	var patch := {"url": "x", "size": 1, "sha256": "a"}
	var S := Updater.State
	for case: Array in [
			[null, S.FAILED], [{"version": "1.0.0", "base": "1.0.0", "patch": null}, S.UP_TO_DATE],
			[{"version": "1.0.2", "base": "1.0.0", "patch": patch}, S.PATCH],
			[{"version": "1.1.0", "base": "1.1.0", "patch": null}, S.NEW_ZIP],
			[{"version": "1.1.1", "base": "1.1.0", "patch": patch}, S.NEW_ZIP]]:
		if not _check(Updater.decide(case[0], "1.0.1", "1.0.0") == case[1], "decide %s" % [case[0]]):
			return
	# Um remendo de verdade (PCKPacker) com um arquivo que o projeto não tem
	var source := FOLDER + "marca.txt"
	var text := FileAccess.open(source, FileAccess.WRITE)
	text.store_string("remendo ok")
	text.close()
	var pck := FOLDER + "servido.pck"
	var packer := PCKPacker.new()
	packer.pck_start(pck)
	packer.add_file(MARK, source)
	packer.flush()
	var bytes := FileAccess.get_file_as_bytes(pck)
	var sha := FileAccess.get_sha256(pck)
	var base := GameVersion.base()
	var next := "%s.900" % GameVersion.VERSION
	# Servidor HTTP local
	if not _check(_server.listen(0, "127.0.0.1") == OK, "servidor local"):
		return
	var url := "http://127.0.0.1:%d/" % _server.get_local_port()
	_serve()
	var updater := Updater.new()
	updater.folder = FOLDER
	updater.manifest_url = url + "versao.json"
	root.add_child(updater)
	for attempt: String in ["sha errado", "certo"]:
		_files["/versao.json"] = JSON.stringify({"version": next, "base": base, "patch": {"url": url + "remendo.pck",
				"size": bytes.size(), "sha256": sha if attempt == "certo" else "0".repeat(64)}}).to_utf8_buffer()
		_files["/remendo.pck"] = bytes
		updater.check()  # CHECKING sai na hora; espera o resultado
		await updater.changed
		if not _check(updater.state == S.PATCH, "procurar (%s): %s" % [attempt, updater.state]):
			return
		updater.download()
		await updater.changed
		if attempt == "sha errado":
			if not _check(updater.state == S.FAILED and updater.download_failed
					and not FileAccess.file_exists(FOLDER + LOADER.NEW_PACK), "sha errado não pode instalar"):
				return
		elif not _check(updater.state == S.READY and FileAccess.file_exists(FOLDER + LOADER.NEW_PACK)
				and FileAccess.file_exists(FOLDER + LOADER.NEW_INFO), "baixar: %s" % updater.state):
			return
	# Instalação ao abrir o jogo
	if not _check(not FileAccess.file_exists(MARK), "marca já existe antes do remendo"):
		return
	if not _check(LOADER.load_patch(FOLDER) == next, "PatchLoader carrega a versão baixada"):
		return
	if not _check(FileAccess.get_file_as_string(MARK) == "remendo ok", "arquivo do remendo visível em res://"):
		return
	if not _check(FileAccess.file_exists(FOLDER + LOADER.PACK) and not FileAccess.file_exists(FOLDER + LOADER.NEW_PACK),
			"remendo-novo vira remendo"):
		return
	# Remendo de outro ZIP é descartado
	var info := FileAccess.open(FOLDER + LOADER.INFO, FileAccess.WRITE)
	info.store_string(JSON.stringify({"version": next, "base": "0.0.1"}))
	info.close()
	if not _check(LOADER.load_patch(FOLDER) == "" and not FileAccess.file_exists(FOLDER + LOADER.PACK),
			"remendo de outra base é apagado"):
		return
	if not await _full_update(url, base):
		return
	print("PASS: versões, decisão, remendo (download, sha256, instalação) e versão completa pelo jogo")
	_finish(0)

## Responde GET com _files (um pedido por conexão).
func _serve() -> void:
	while _serving:
		if _server.is_connection_available():
			_answer(_server.take_connection())
		await process_frame

func _answer(peer: StreamPeerTCP) -> void:
	var request := ""
	while _serving and not request.contains("\r\n\r\n"):
		peer.poll()
		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			return
		if peer.get_available_bytes() > 0:
			request += peer.get_utf8_string(peer.get_available_bytes())
		else:
			await process_frame
	var path := request.get_slice(" ", 1)
	var body: PackedByteArray = _files.get(path, PackedByteArray())
	var status := "200 OK" if _files.has(path) else "404 Not Found"
	peer.put_data(("HTTP/1.1 %s\r\nContent-Length: %d\r\nConnection: close\r\n\r\n" % [status, body.size()]).to_utf8_buffer())
	peer.put_data(body)
	peer.disconnect_from_host()


func _write(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()

func _entry(url: String, name: String, text: String) -> Dictionary:
	var bytes := text.to_utf8_buffer()
	_files["/" + name] = bytes
	var temp := FOLDER + "hash.tmp"
	_write(temp, text)
	var sha := FileAccess.get_sha256(temp)
	DirAccess.remove_absolute(temp)
	return {"name": name, "size": bytes.size(), "sha256": sha, "url": url + name}

## Versão completa: só os arquivos que mudaram vão para jogo-novo/, e o instalar.ps1 os copia por cima.
## Depois, sem a lista, o ZIP inteiro.
func _full_update(url: String, base: String) -> bool:
	var game := FOLDER + "instalado/"
	_write(game + "HotelSemSaida.exe", "motor igual")
	_write(game + "HotelSemSaida.pck", "jogo velho")
	var files := [_entry(url, "HotelSemSaida.exe", "motor igual"), _entry(url, "HotelSemSaida.pck", "jogo novo"),
			_entry(url, "nova.dll", "dll nova")]
	_files["/versao.json"] = JSON.stringify({"version": "99.0.0", "base": "99.0.0", "patch": null,
			"zip": url + "jogo.zip", "files": files}).to_utf8_buffer()
	var updater := Updater.new()
	updater.folder = FOLDER
	updater.game_dir = ProjectSettings.globalize_path(game).trim_suffix("/")
	updater.manifest_url = url + "versao.json"
	root.add_child(updater)
	updater.check()
	await updater.changed
	var names := updater.needed.map(func(entry: Dictionary) -> String: return entry.name)
	if not _check(updater.state == Updater.State.NEW_ZIP and updater.can_install_full()
			and names == ["HotelSemSaida.pck", "nova.dll"], "completa: só o que mudou (%s)" % [names]):
		return false
	updater.download_full()
	while updater.state == Updater.State.DOWNLOADING:  # um aviso por arquivo
		await updater.changed
	var fresh := FOLDER + Updater.NEW_GAME
	if not _check(updater.state == Updater.State.READY and not FileAccess.file_exists(fresh + "HotelSemSaida.exe")
			and FileAccess.get_file_as_string(fresh + "HotelSemSaida.pck") == "jogo novo"
			and FileAccess.file_exists(FOLDER + Updater.INSTALLER), "completa: baixar os arquivos"):
		return false
	# O instalador de verdade, sem esperar este processo e sem abrir o jogo
	updater.write_installer(999999, false)
	var output := []
	var code := OS.execute("powershell.exe", ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
			ProjectSettings.globalize_path(FOLDER + Updater.INSTALLER)], output, true)
	if not _check(code == 0 and FileAccess.get_file_as_string(game + "HotelSemSaida.pck") == "jogo novo"
			and FileAccess.get_file_as_string(game + "nova.dll") == "dll nova"
			and FileAccess.get_file_as_string(game + "HotelSemSaida.exe") == "motor igual"
			and not DirAccess.dir_exists_absolute(fresh), "instalar.ps1 copia por cima (%d %s)" % [code, output]):
		return false
	# Sem a lista de arquivos: o ZIP inteiro
	var zip_path := FOLDER + "servido.zip"
	var packer := ZIPPacker.new()
	packer.open(zip_path)
	for name: String in ["HotelSemSaida.exe", "HotelSemSaida.pck"]:
		packer.start_file("HotelSemSaida/" + name)
		packer.write_file(("zip " + name).to_utf8_buffer())
		packer.close_file()
	packer.close()
	_files["/jogo.zip"] = FileAccess.get_file_as_bytes(zip_path)
	_files["/versao.json"] = JSON.stringify({"version": "99.0.0", "base": "99.0.0", "patch": null,
			"zip": url + "jogo.zip"}).to_utf8_buffer()
	updater.state = Updater.State.OFF
	updater.check()
	await updater.changed
	updater.download_full()
	while updater.state == Updater.State.DOWNLOADING:  # um aviso por arquivo
		await updater.changed
	return _check(updater.state == Updater.State.READY
			and FileAccess.get_file_as_string(fresh + "HotelSemSaida.pck") == "zip HotelSemSaida.pck",
			"completa pelo ZIP: %s" % updater.state)
