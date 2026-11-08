extends SceneTree
## Áudio: todo som citado no código existe, cada sala tem perfil de ambiente e as camadas
## seguem a época (jazz em 1923, vento hoje).

const SOURCES := ["res://scripts"]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var audio := root.get_node("Audio")
	# 1. Todo efeito citado em Audio.play("...") / play_one_of / pending_sound / _default_sound existe
	var names := _sound_names()
	assert(names.size() >= 10, "Achou os sons citados no código: %d" % names.size())
	for sound: String in names:
		assert(ResourceLoader.exists("res://art/audio/efeitos/%s.ogg" % sound), "Som existe: " + sound)
	for i in range(1, 7):
		assert(ResourceLoader.exists("res://art/audio/efeitos/passo_%d.ogg" % i))
	for i in range(1, 9):
		assert(ResourceLoader.exists("res://art/audio/efeitos/piano_%d.ogg" % i))
	# 2. Cada sala 3D tem um perfil
	for room: String in ["saguao_3d", "cozinha_3d", "manutencao_3d", "biblioteca_3d", "caldeiras_3d",
			"quartos_3d", "salao_3d", "torre_3d"]:
		assert(audio.ROOMS.has(room), "Perfil de som para " + room)
		assert(FileAccess.file_exists("res://scenes/rooms/%s.tscn" % room))
	# 3. Camadas pela época
	change_scene_to_file("res://scenes/rooms/saguao_3d.tscn")
	await scene_changed
	root.get_node("EraManager").set_era(0)
	await _wait(1.6)
	assert(audio.current_room() == "saguao_3d")
	assert(audio.get_node("jazz").volume_db > -20.0, "Jazz em 1923")
	assert(audio.get_node("vento").volume_db < -50.0, "Sem vento em 1923")
	root.get_node("EraManager").set_era(1)
	await _wait(0.8)
	assert(audio.get_node("jazz").volume_db < -50.0, "Sem jazz hoje")
	assert(audio.get_node("vento").volume_db > -20.0, "Vento hoje")
	print("PASS: sons citados existem, perfis por sala e camadas por época")
	audio.quit()


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _sound_names() -> Array[String]:
	var found: Array[String] = []
	var pattern := RegEx.create_from_string(
		'(?:Audio\\.play\\(|pending_sound = |sound = |return )"([a-z_0-9]+)"')
	for path in _files("res://scripts"):
		var text := FileAccess.get_file_as_string(path)
		for m in pattern.search_all(text):
			var value := m.get_string(1)
			# "return \"...\"" só conta dentro de _default_sound
			if m.get_string(0).begins_with("return ") and not _in_default_sound(text, m.get_start()):
				continue
			if value not in found:
				found.append(value)
	return found


func _in_default_sound(text: String, at: int) -> bool:
	var head := text.substr(0, at)
	var last_func := head.rfind("func ")
	return last_func != -1 and head.substr(last_func, 30).begins_with("func _default_sound")


func _files(dir: String) -> Array[String]:
	var out: Array[String] = []
	for file in DirAccess.get_files_at(dir):
		if file.ends_with(".gd"):
			out.append(dir + "/" + file)
	for sub in DirAccess.get_directories_at(dir):
		out.append_array(_files(dir + "/" + sub))
	return out
