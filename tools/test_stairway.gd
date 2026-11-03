extends SceneTree
## Executar com --headless --path . --script res://tools/test_stairway.gd

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var state = root.get_node("WorldState")
	var eras = root.get_node("EraManager")
	state.load_dict({})
	eras.set_era(0)
	var room = load("res://scenes/rooms/cozinha.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	await physics_frame
	await physics_frame
	var helena = room.get_node("Helena")
	var lia = room.get_node("Lia")
	var down = room.get_node("World1923/PortaDespensa/Interacao")
	var up = room.get_node("World1923/SaidaEscada/Interacao")
	assert(not down.can_interact(helena), "A descida deve exigir o cadeado aberto")
	assert(not up.can_interact(helena), "A subida deve exigir a mesma porta aberta")
	state.set_flag("cozinha.despensa.aberta", true)
	assert(not room.get_node("World1923/PortaDespensa/Porta").visible)
	helena.position = Vector2(64, 200)
	var lia_origin: Vector2 = lia.position
	down.interact(helena)
	assert(helena.is_traversing())
	assert(helena.get_save_position() == Vector2(64, 200))
	assert(not down.can_interact(helena), "Nao pode repetir a passagem durante o percurso")
	for frame in range(20):
		await physics_frame
	assert(helena.position.y > 200 and helena.position.y < 344)
	eras.set_era(1)
	var stopped: Vector2 = helena.position
	for frame in range(20):
		await physics_frame
	assert(helena.position == stopped, "A personagem inativa deve ficar parada")
	eras.set_era(0)
	paused = true
	stopped = helena.position
	await create_timer(0.1, true).timeout
	assert(helena.position == stopped, "Pausar deve interromper a travessia")
	paused = false
	for frame in range(240):
		await physics_frame
	assert(not helena.is_traversing())
	assert(helena.position.distance_to(Vector2(156, 344)) < 1.0)
	assert(lia.position.distance_to(lia_origin) < 1.0)
	assert(up.has_body(helena), "O destino precisa estar dentro da area de subida")
	up.interact(helena)
	assert(helena.is_traversing())
	for frame in range(240):
		await physics_frame
	assert(not helena.is_traversing())
	assert(helena.position.distance_to(Vector2(64, 200)) < 1.0)
	assert(down.has_body(helena), "O destino precisa estar dentro da area de descida")
	assert(helena.get_save_position().distance_to(Vector2(64, 200)) < 1.0)
	print("PASS: cadeado, porta, ida/volta, animacao, pausa, troca de epoca, destino e posicao de save")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("hotel-stairway.png"))
	quit()
