extends SceneTree
## S4 e final desta versão: livro de hóspedes por capítulo, chave da bolsa de Marta, cofre 1403,
## as duas trancas da entrada, a assinatura de Helena, a saída de Lia e a tela de fim.
## Preserva o save solo real (a tela de fim salva o jogo).
## Rodar: Godot_console.exe --headless --path . --fixed-fps 60 --script res://tools/test_saguao_final_3d.gd

class TestInput extends CharacterInput:
	var interact := false
	func is_interact_just_pressed() -> bool:
		var pressed := interact
		interact = false
		return pressed


const END := "res://scripts/ui/end_screen.gd"
const SILL := Vector3(16.29, 0, 3.18)
const SAFE_SPOT := Vector3(13.3, 0, 2.62)
const DOOR_SPOT := Vector3(10.0, 0, 9.0)
const DESK_SPOT := Vector3(10.0, 0, 4.6)

var state: Node
var eras: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var save_path: String = root.get_node("SaveSystem").SAVE_PATH
	var real_save := FileAccess.get_file_as_string(save_path) if FileAccess.file_exists(save_path) else ""
	state = root.get_node("WorldState")
	eras = root.get_node("EraManager")
	state.clear()
	for flag in ["cozinha.concluida", "biblioteca.concluida", "caldeiras.concluida", "saguao.elevador.no_alto"]:
		state.set_flag(flag)
	eras.set_era(1)
	change_scene_to_file("res://scenes/rooms/saguao_3d.tscn")
	await scene_changed
	await physics_frame

	# O livro de hoje acumula os desaparecidos dos capítulos feitos
	var book_text := _book()
	for piece in ["Otília", "Caio Ferraz", "Tomás Reis", "primeira letra parece um L"]:
		assert(piece in book_text, "Livro sem: " + piece)
	assert(not "Marta" in book_text and not "Helena" in book_text, "Marta e Helena ainda não estão no livro")

	# Poço: Lia lê a bolsa e guarda a chave miúda
	var lia = current_scene.get_node("Lia")
	await _use("Lia", "WorldToday/DescerPoco", SILL)
	for i in 340:
		await physics_frame
	assert(current_scene.find_child("BolsaMarta", true, false).get_parent().name == "WorldToday")
	await _use("Lia", "WorldToday/BolsaMarta", lia.position)
	assert(state.is_set("saguao.bolsa.marta") and str(state.get_flag("lia.mao", "")) == "", "Examinar só lê")
	await _close_overlays()
	await _use("Lia", "WorldToday/ChaveMiuda", lia.position)
	assert(state.get_flag("lia.mao") == "chave_portaria", "Lia pega a chave à parte")
	assert("Marta Siqueira, 1979" in _book())
	await _use("Lia", "WorldToday/SubirPoco", lia.position)
	for i in 340:
		await physics_frame

	# Entrada hoje: o cadeado cai, mas a fechadura de 1923 ainda está travada
	await _use("Lia", "WorldToday/Entrada", DOOR_SPOT)
	assert(state.is_set("saguao.entrada.cadeado") and state.get_flag("lia.mao") == "")
	assert(not current_scene.get_node("WorldToday/Corrente").visible, "A corrente cai")
	await _use("Lia", "WorldToday/Entrada", DOOR_SPOT)
	assert(not state.is_set("jogo.final"), "Sem a trava de 1923 Lia não sai")

	# 1923: cofre com a data do lustre, chave da porta principal e trava da porta giratória
	eras.set_era(0)
	await physics_frame
	await _use("Helena", "World1923/Cofre", SAFE_SPOT)
	var lock := _overlay("res://scripts/ui/code_lock_ui.gd")
	assert(lock != null, "O cofre abre o cadeado de código")
	lock.solved.emit()
	await _close_overlays()
	# Duas fechaduras: o segredo fica marcado, mas sem a chave do gerente a porta não cede
	assert(state.is_set("saguao.cofre.segredo") and not state.is_set("saguao.cofre.aberto"), "Falta a chave")
	assert(not current_scene.get_node("World1923/PortaCofre").visible)
	await _use("Helena", "World1923/Cofre", SAFE_SPOT)
	assert(_overlay("res://scripts/ui/code_lock_ui.gd") == null, "O segredo já está certo")
	current_scene.get_node("Helena").set_held_item("chave_gerente")
	await _use("Helena", "World1923/Cofre", SAFE_SPOT)
	assert(state.is_set("saguao.cofre.chave") and state.get_flag("helena.mao") == "", "A chave fica na fechadura")
	assert(state.is_set("saguao.cofre.aberto"))
	assert(current_scene.get_node("World1923/PortaCofre").visible, "A porta do cofre aparece aberta")
	assert(current_scene.get_node("WorldToday/PortaCofreHoje").visible, "Hoje o cofre está aberto")
	assert("vazio" in str(current_scene.get_node("WorldToday/CofreHoje").message))
	await _use("Helena", "World1923/Cofre", SAFE_SPOT)
	assert(state.get_flag("helena.mao") == "chave_entrada", "Helena pega a chave do cofre")
	await _reload_flags()
	assert(current_scene.get_node("World1923/PortaCofre").visible, "Cofre continua aberto ao recarregar")
	await _use("Helena", "World1923/Entrada", DOOR_SPOT)
	assert(state.is_set("saguao.entrada.trava_1923") and state.get_flag("helena.mao") == "")
	await _use("Helena", "World1923/Livro", DESK_SPOT)
	assert(state.is_set("saguao.livro.helena"), "Helena assina o livro")
	await _close_overlays()
	assert("Na primeira página, em 1923: Helena" in _book())

	# Hoje: com as duas trancas abertas, Lia sai… e volta ao Saguão
	eras.set_era(1)
	await physics_frame
	lia = current_scene.get_node("Lia")
	await _use("Lia", "WorldToday/Entrada", DOOR_SPOT)
	for i in 240:
		await physics_frame
	assert(state.is_set("jogo.final"), "Lia passa pela entrada")
	assert(lia.position.distance_to(Vector3(10, 0, 9.4)) < 0.1, "Lia volta de costas para a porta: %s" % lia.position)
	assert(current_scene.get_node("WorldToday/Corrente").visible, "A porta está pregada de novo")
	assert("assinatura: Lia" in _book())

	# Ler o próprio nome encerra o jogo, depois de fechar o livro
	await _use("Lia", "WorldToday/Livro", DESK_SPOT)
	assert(not state.is_set("jogo.encerrado"))
	await _close_overlays()
	for i in 10:
		await process_frame
	assert(state.is_set("jogo.encerrado"))
	var end := _overlay(END)
	assert(end != null and end.visible and paused, "Tela de fim aberta e jogo pausado")
	for i in 30:
		await process_frame
	assert(paused, "O fim continua pausado depois que o livro despausa")
	end._leave()
	await scene_changed
	assert(current_scene.scene_file_path == "res://scenes/ui/entrada.tscn", "Volta à recepção")

	if real_save == "":
		DirAccess.remove_absolute(save_path)
	else:
		var file := FileAccess.open(save_path, FileAccess.WRITE)
		file.store_string(real_save)
		file.close()
	print("PASS: Saguão final, livro por capítulo, bolsa de Marta, cofre 1403, duas trancas, assinatura de Helena, saída de Lia e tela de fim")
	quit()


func _use(character: String, path: String, at: Vector3) -> void:
	var motor = current_scene.get_node(character)
	var target: Area3D = current_scene.get_node(path)
	var controls := TestInput.new()
	motor.input = controls
	motor.position = at
	motor.velocity = Vector3.ZERO
	var aim: Vector3 = target.global_position - motor.get_camera().global_position
	motor.rotation.y = atan2(-aim.x, -aim.z)
	motor.get_node("Head").rotation.x = atan2(aim.y, Vector2(aim.x, aim.z).length())
	for i in 4:
		await physics_frame
	assert(motor.focused == target, "Alvo fora de alcance: " + path)
	controls.interact = true
	for i in 3:
		await physics_frame


func _book() -> String:
	return load("res://scripts/puzzles/saguao/guest_book_3d.gd").present_text()


func _overlay(script_path: String) -> Node:
	for child in root.get_children():
		if child.get_script() and child.get_script().resource_path == script_path:
			return child
	return null


func _close_overlays() -> void:
	for child in root.get_children():
		if child is CanvasLayer and child.is_in_group("room_overlay") and _overlay(END) != child:
			if child.has_method("close"):
				child.close()
			else:
				child.queue_free()
				paused = false
	for i in 8:
		await process_frame


func _reload_flags() -> void:
	state.load_dict(JSON.parse_string(JSON.stringify(state.to_dict())))
	change_scene_to_file(current_scene.scene_file_path)
	await scene_changed
	await physics_frame
