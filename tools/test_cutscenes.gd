extends SceneTree
## Cutscenes no motor: abertura do jogo novo (pular com E devolve tudo ao lugar) e primeira
## troca de época (toca inteira e só uma vez).
## Rodar: Godot_console.exe --headless --path . --fixed-fps 60 --script res://tools/test_cutscenes.gd

const CUTSCENE := "res://scripts/ui/cutscene.gd"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	load(CUTSCENE).enabled = true
	var state := root.get_node("WorldState")
	var eras := root.get_node("EraManager")
	state.clear()
	state.set_flag("cena.abertura.pendente")
	eras.set_era(0)
	change_scene_to_file("res://scenes/rooms/saguao_3d.tscn")
	await scene_changed
	for i in 3:
		await process_frame
	var scene := _playing()
	assert(scene != null and paused, "A abertura toca ao começar o jogo novo")
	assert(not state.is_set("cena.abertura.pendente") and state.is_set("cena.abertura"))
	var helena = current_scene.get_node("Helena")
	var lia = current_scene.get_node("Lia")
	var spot: Vector3 = helena.position
	# Deixa chegar à tomada de hoje
	var reached_today := false
	for i in 60 * 14:
		await process_frame
		if eras.current_era == 1:
			reached_today = true
			break
	assert(reached_today, "A abertura mostra o hotel de hoje")
	assert(not helena.get_camera().current and not lia.get_camera().current, "Câmera própria da cutscene")
	scene.skip()
	for i in 60:
		await process_frame
	assert(_playing() == null and not paused, "Pular encerra e despausa")
	assert(eras.current_era == 0 and helena.get_camera().current, "Volta aos olhos de Helena")
	assert(helena.position.is_equal_approx(spot), "Ninguém sai do lugar")
	assert(current_scene.get_node("HUD").visible, "HUD volta")

	# Primeira troca de época pelo Tab: toca inteira e devolve os olhos de Lia
	eras.switch_era()
	for i in 40:
		await process_frame
	assert(_playing() != null, "A primeira troca tem cutscene")
	for i in 60 * 7:
		await process_frame
		if _playing() == null:
			break
	for i in 10:
		await process_frame
	assert(_playing() == null and not paused and eras.current_era == 1 and lia.get_camera().current)
	eras.switch_era()
	for i in 40:
		await process_frame
	assert(_playing() == null and eras.current_era == 0, "A cutscene da troca não repete")

	# De novo no Saguão, sem jogo novo: a abertura não volta
	change_scene_to_file("res://scenes/rooms/saguao_3d.tscn")
	await scene_changed
	for i in 5:
		await process_frame
	assert(_playing() == null, "Abertura só uma vez")
	await _story_moments(state, eras)
	print("PASS: cutscenes de abertura, primeira troca, fim de capítulos (até o Salão), bolsa de Marta e final; pular, câmera, época e HUD restaurados")
	quit()


## Cada momento da história toca na sala certa; a cutscene espera o bilhete fechar.
func _story_moments(state: Node, eras: Node) -> void:
	var save_path: String = root.get_node("SaveSystem").SAVE_PATH
	var real_save := FileAccess.get_file_as_string(save_path) if FileAccess.file_exists(save_path) else ""
	eras.set_era(1)
	state.set_flag("cozinha.concluida")
	await _open("res://scenes/rooms/manutencao_3d.tscn")
	await _expect_and_skip("cena.fim_cozinha", 1)
	await _open("res://scenes/rooms/biblioteca_3d.tscn")
	# Com um bilhete aberto, a cutscene espera
	var note = load("res://scripts/ui/note_ui.gd").open(self, "Dossiê", "texto")
	state.set_flag("biblioteca.concluida")
	for i in 20:
		await process_frame
	var waiting := _playing()
	assert(waiting != null and not waiting._started, "A cutscene espera o bilhete fechar")
	note.close()
	await _expect_and_skip("cena.fim_biblioteca", 1)
	await _open("res://scenes/rooms/caldeiras_3d.tscn")
	state.set_flag("caldeiras.concluida")
	await _expect_and_skip("cena.fim_caldeiras", 1)
	await _open("res://scenes/rooms/quartos_3d.tscn")
	state.set_flag("quartos.diario.lido")
	await _expect_and_skip("cena.fim_quartos", 1)
	await _open("res://scenes/rooms/salao_3d.tscn")
	state.set_flag("salao.concluido")
	await _expect_and_skip("cena.fim_salao", 1)
	await _open("res://scenes/rooms/saguao_3d.tscn")
	state.set_flag("saguao.bolsa.marta")
	await _expect_and_skip("cena.bolsa_marta", 1)
	state.set_flag("jogo.final")
	await _expect_and_skip("cena.final_saida", 1)
	state.set_flag("jogo.encerrado")
	await _expect_and_skip("cena.final_batidas", 1)
	for i in 60:
		await process_frame
	var end: Node = null
	for child in root.get_children():
		if child.get_script() and child.get_script().resource_path == "res://scripts/ui/end_screen.gd":
			end = child
	assert(end != null and end.visible, "A tela de fim vem depois das batidas")
	end.queue_free()
	paused = false
	if real_save == "":
		DirAccess.remove_absolute(save_path)
	else:
		var file := FileAccess.open(save_path, FileAccess.WRITE)
		file.store_string(real_save)
		file.close()


func _open(path: String) -> void:
	change_scene_to_file(path)
	await scene_changed
	for i in 3:
		await process_frame


func _expect_and_skip(flag: String, era_after: int) -> void:
	var scene: Node = null
	for i in 40:
		await process_frame
		scene = _playing()
		if scene and scene._started:
			break
	assert(scene != null and scene._started and paused, "Cutscene não tocou: " + flag)
	assert(root.get_node("WorldState").is_set(flag))
	for i in 90:
		await process_frame
	scene.skip()
	for i in 60:
		await process_frame
	assert(_playing() == null, "Cutscene não terminou: " + flag)
	assert(root.get_node("EraManager").current_era == era_after, "Época não voltou depois de " + flag)


func _playing() -> Node:
	var found := get_nodes_in_group("cutscene")
	return found[0] if not found.is_empty() else null
