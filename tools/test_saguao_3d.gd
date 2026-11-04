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
	print("PASS: saguao 3D cameras por epoca, colisao, lustre caido, mira no livro, cada uma fica onde foi deixada")
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
