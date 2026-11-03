extends SceneTree
## Saguão (S1): geometria nas duas épocas, lustre caído só hoje e porta para a Cozinha.
## Rodar: Godot_console.exe --headless --path . --fixed-fps 60 --script res://tools/test_saguao.gd
## Com -- --capture (sem --headless), salva capturas das duas épocas na pasta TEMP.

class TestInput extends CharacterInput:
	var direction := Vector2.ZERO
	func get_move() -> Vector2:
		return direction


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var era_manager := root.get_node("EraManager")
	era_manager.set_era(0)
	var room: Node = load("res://scenes/rooms/saguao.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	var helena = room.get_node("Helena")
	var lia = room.get_node("Lia")
	await physics_frame
	assert(helena.mode == 1, "Saguão é visto de cima")

	for world_name in ["World1923", "WorldToday"]:
		var world: Node = room.get_node(world_name)
		for part in ["SideWalls", "KitchenDoor", "Entrance", "Stairs", "Elevator", "ReceptionWall", "ReceptionCounter", "Piano"]:
			assert(world.has_node(part), "%s sem %s" % [world_name, part])
	assert(room.get_node("World1923").has_node("Rug") and not room.get_node("World1923").has_node("FallenChandelier"))
	assert(room.get_node("WorldToday").has_node("FallenChandelier") and not room.get_node("WorldToday").has_node("Rug"))

	# 1923: o centro é livre (o lustre está no teto)
	var helena_input := TestInput.new()
	helena.input = helena_input
	assert((await _walk(helena, helena_input, Vector2(200, 236), Vector2.RIGHT, 240)).x > 440.0, "Centro livre em 1923")
	# A parede oeste segura a personagem fora do vão da porta
	var stopped: Vector2 = await _walk(helena, helena_input, Vector2(80, 300), Vector2.LEFT, 90)
	assert(stopped.x >= 16.0 + 10.0 - 0.5 and stopped.x < 30.0, "Parede oeste sólida: x=%s" % stopped.x)
	# O balcão é sólido
	stopped = await _walk(helena, helena_input, Vector2(320, 170), Vector2.UP, 90)
	assert(stopped.y > 128.0, "Balcão sólido: y=%s" % stopped.y)

	# Hoje: o lustre caído bloqueia o centro, mas dá para contornar por baixo
	era_manager.set_era(1)
	await physics_frame
	var lia_input := TestInput.new()
	lia.input = lia_input
	stopped = await _walk(lia, lia_input, Vector2(200, 236), Vector2.RIGHT, 240)
	assert(stopped.x < 256.0 - 10.0 + 0.5 + 1.0, "Lustre caído sólido hoje: x=%s" % stopped.x)
	assert((await _walk(lia, lia_input, Vector2(200, 290), Vector2.RIGHT, 240)).x > 440.0, "Caminho por baixo do lustre livre")

	if "--capture" in OS.get_cmdline_user_args():
		await _capture(room, "today")
		era_manager.set_era(0)
		await _capture(room, "1923")

	# Porta da Cozinha: as duas personagens vão juntas para o ponto de entrada
	era_manager.set_era(1)
	await physics_frame
	lia.position = Vector2(40, 244)
	for tick in 4:
		await physics_frame
	var door = room.get_node("WorldToday/PortaCozinha")
	assert(door.has_body(lia), "Lia alcança a porta da Cozinha")
	door.interact(lia)
	await process_frame
	while root.get_node("RoomManager").is_changing():
		await process_frame
	var kitchen := current_scene
	assert(kitchen.scene_file_path == "res://scenes/rooms/cozinha.tscn")
	for motor in [kitchen.get_node("Helena"), kitchen.get_node("Lia")]:
		assert(motor.global_position == Vector2(120, 200), "Entrada da Cozinha pelo saguão")
	print("PASS: saguao geometria 1923/hoje, lustre caido, porta para a Cozinha")
	quit()


func _walk(motor, input: TestInput, start: Vector2, direction: Vector2, ticks: int) -> Vector2:
	motor.position = start
	motor.velocity = Vector2.ZERO
	input.direction = direction
	for tick in ticks:
		await physics_frame
	input.direction = Vector2.ZERO
	return motor.position


func _capture(room: Node, label: String) -> void:
	for tick in 30:
		await process_frame
	var image := root.get_texture().get_image()
	var path := OS.get_environment("TEMP").path_join("saguao-%s.png" % label)
	image.save_png(path)
	print("captura: ", path)
