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
	print("PASS: cutscenes de abertura e da primeira troca, pular, câmera, época e HUD restaurados")
	quit()


func _playing() -> Node:
	var found := get_nodes_in_group("cutscene")
	return found[0] if not found.is_empty() else null
