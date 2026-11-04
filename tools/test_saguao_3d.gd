extends SceneTree
## Saguão 3D (protótipo em primeira pessoa): câmera de cada época, movimento, colisões,
## mira no livro de hóspedes e a troca de época mantendo cada uma onde foi deixada.
## Rodar: Godot_console.exe --headless --path . --fixed-fps 60 --script res://tools/test_saguao_3d.gd
## Com -- --capture (sem --headless), salva capturas das duas épocas na pasta TEMP.

class TestInput extends CharacterInput:
	var direction := Vector2.ZERO
	var interact := false
	func get_move() -> Vector2:
		return direction
	func is_interact_just_pressed() -> bool:
		var pressed := interact
		interact = false
		return pressed


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var era_manager := root.get_node("EraManager")
	era_manager.set_era(0)
	var room: Node = load("res://scenes/rooms/saguao_3d.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	var helena = room.get_node("Helena")
	var lia = room.get_node("Lia")
	await physics_frame
	assert(helena.get_camera().current, "Em 1923 a câmera é a dos olhos da Helena")
	for world_name in ["World1923", "WorldToday"]:
		for part in ["Floor", "WallNorth", "Counter", "Stairs", "Piano", "Column"]:
			assert(room.get_node(world_name).find_child(part, false, false) != null or room.get_node(world_name).has_node(part), "%s sem %s" % [world_name, part])

	var helena_input := TestInput.new()
	helena.input = helena_input
	# 1923: o centro está livre (o lustre está no teto) até o balcão, que é sólido
	var stopped: Vector3 = await _walk(helena, helena_input, Vector3(10, 0, 9.5), Vector2.UP, 240)
	assert(stopped.z > 4.0 and stopped.z < 5.0, "Helena para no balcão: z=%s" % stopped.z)

	# A tampa do piano fica acima do corpo e também bloqueia a personagem.
	var lid = room.get_node("World1923").find_child("PianoLid", false, false)
	assert(lid != null and lid.get_child(0).shape != null, "Tampa do piano tem colisão")

	# Mirar no livro, de frente para o balcão e olhando um pouco para baixo
	helena.position = Vector3(10, 0, 4.6)
	helena.rotation = Vector3.ZERO
	helena.get_node("Head").rotation.x = -0.3
	for tick in 3:
		await physics_frame
	assert(helena.focused == room.get_node("World1923/Livro"), "Helena mira o livro")
	var helena_spot: Vector3 = helena.position

	# Hoje: a câmera passa para os olhos da Lia, e a Helena fica onde estava
	era_manager.set_era(1)
	await physics_frame
	assert(lia.get_camera().current and not helena.get_camera().current, "Troca para os olhos da Lia")
	assert(helena.position.is_equal_approx(helena_spot), "Helena fica onde foi deixada")
	var lia_input := TestInput.new()
	lia.input = lia_input
	stopped = await _walk(lia, lia_input, Vector3(10, 0, 9.5), Vector2.UP, 240)
	assert(stopped.z > 7.8, "Lustre caído bloqueia o centro hoje: z=%s" % stopped.z)
	assert((await _walk(lia, lia_input, Vector3(6.5, 0, 9.5), Vector2.UP, 240)).z < 5.0, "Dá para contornar o lustre")

	await _test_lift()
	room = current_scene
	helena = room.get_node("Helena")
	lia = room.get_node("Lia")
	if "--capture" in OS.get_cmdline_user_args():
		for setup in [[1, lia, "hoje"], [0, helena, "1923"]]:
			era_manager.set_era(setup[0])
			var motor = setup[1]
			motor.position = Vector3(10, 0, 10.2)
			motor.rotation = Vector3.ZERO
			motor.get_node("Head").rotation.x = -0.05
			for tick in 30:
				await process_frame
			var path := OS.get_environment("TEMP").path_join("saguao3d-%s.png" % setup[2])
			root.get_texture().get_image().save_png(path)
			print("captura: ", path)
	print("PASS: Saguão 3D, câmeras, colisão, quadro, chave errada e devolução, cabine, bolsa de Marta, escada e recarga")
	quit()


func _walk(motor, input: TestInput, start: Vector3, direction: Vector2, ticks: int) -> Vector3:
	motor.position = start
	motor.rotation = Vector3.ZERO
	motor.velocity = Vector3.ZERO
	input.direction = direction
	for tick in ticks:
		await physics_frame
	input.direction = Vector2.ZERO
	return motor.position


func _test_lift() -> void:
	var state := root.get_node("WorldState")
	var eras := root.get_node("EraManager")
	var desk := Vector3(7.77, 0, 2.59)
	var sill := Vector3(16.29, 0, 3.18)
	var lock := Vector3(17.51, 0, 3.18)
	state.set_flag("caldeiras.concluida")
	await _use("Lia", "WorldToday/OlharGrade", sill)
	await _use("Lia", "WorldToday/Chapa9", desk)
	assert(paused and not state.is_set("saguao.elevador.no_alto"))
	await _close_note()
	eras.set_era(0)
	await _use("Helena", "World1923/Gancho2", desk)
	await _use("Helena", "World1923/PainelElevador", lock)
	assert(not state.is_set("saguao.elevador.no_alto") and state.get_flag("helena.mao") == "chave_quadro")
	await _reload_flags()
	await _use("Helena", "World1923/Gancho2", desk)
	assert(state.get_flag("helena.mao") == "")
	await _use("Helena", "World1923/Gancho9", desk)
	await _use("Helena", "World1923/PainelElevador", lock)
	assert(state.is_set("saguao.elevador.no_alto") and state.get_flag("helena.mao") == "")
	for i in 108:
		await physics_frame
	assert(current_scene.get_node("World1923/Cabin").position.y > 3.5)
	await _reload_flags()
	eras.set_era(1)
	assert(current_scene.get_node("WorldToday/Cabin").position.y > 3.5)
	var lia = current_scene.get_node("Lia")
	await _use("Lia", "WorldToday/DescerPoco", sill)
	assert(lia.is_traversing() and lia.get_save_position().distance_to(sill)<0.05)
	for i in 340:
		await physics_frame
	assert(not lia.is_traversing() and lia.is_on_floor() and absf(lia.position.y+2.65)<0.03)
	await _use("Lia", "WorldToday/BolsaMarta", lia.position)
	assert(paused and state.is_set("saguao.bolsa.marta"))
	await _close_note()
	await _use("Lia", "WorldToday/SubirPoco", lia.position)
	for i in 340:
		await physics_frame
	assert(lia.is_on_floor() and lia.position.distance_to(Vector3(16.48, 0, 2.55)) < 0.04)
	assert(state.is_set("caldeiras.concluida"))


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


func _close_note() -> void:
	for child in root.get_children():
		if child is CanvasLayer and child.has_method("close"):
			child.close()
	for i in 8:
		await process_frame


func _reload_flags() -> void:
	var state := root.get_node("WorldState")
	state.load_dict(JSON.parse_string(JSON.stringify(state.to_dict())))
	var previous := current_scene
	var path := previous.scene_file_path
	change_scene_to_file(path)
	await scene_changed
