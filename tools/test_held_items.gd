extends SceneTree

class Controls extends CharacterInput:
	var direction := Vector2.ZERO
	func get_move() -> Vector2:
		return direction

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
	var helena = room.get_node("Helena")
	var controls := Controls.new()
	await physics_frame
	helena.input = controls
	for item in ["fermento","gelo"]:
		helena.position = Vector2(200,200)
		helena.velocity = Vector2.ZERO
		helena.set_held_item(item)
		controls.direction = Vector2.ZERO
		for tick in 6:
			await physics_frame
		assert(helena._item_name == StringName(item+"_idle"))
		assert(not helena._held_item_sprite.visible)
		if "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("held-%s.png"%item))
		controls.direction = Vector2.RIGHT
		var frames := {}
		for tick in 100:
			await physics_frame
			frames[helena.get_node("Sprite").texture.resource_path] = true
		assert(helena._item_name == StringName(item+"_walk"))
		assert(frames.size() >= 8)
		controls.direction = Vector2.LEFT
		for tick in 25:
			await physics_frame
		assert(helena.get_node("Sprite").flip_h)
		controls.direction = Vector2.ZERO
		helena.set_held_item("")
		for tick in 6:
			await physics_frame
		assert(helena.get_node("Sprite").hframes == 5)
		assert(helena.get_node("Sprite").offset == Vector2(-12,-48))
	# A coleta real entra no estado carregando e persiste na memória do mundo.
	helena.position = Vector2(277,344)
	room.get_node("World1923/Fermento/Interacao").interact(helena)
	assert(helena.get_held_item() == "fermento")
	assert(state.is_set("cozinha.fermento.pego"))
	for tick in 3:
		await physics_frame
	helena.position = Vector2(504,200)
	helena.velocity = Vector2.ZERO
	var oven = room.get_node("World1923/Forno/Interacao")
	oven.interact(helena)
	assert(helena.is_using_item())
	assert(not oven.can_interact(helena))
	assert(not state.is_set("cozinha.forno.massa"))
	for tick in 8:
		await physics_frame
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("held-fermento-use.png"))
	var time: float = helena._item_clock
	paused = true
	await create_timer(0.1,true).timeout
	assert(helena._item_clock == time)
	paused = false
	eras.set_era(1)
	for tick in 10:
		await physics_frame
	assert(helena._item_clock == time)
	assert(helena.get_held_item() == "fermento")
	eras.set_era(0)
	for tick in 60:
		await physics_frame
	assert(state.is_set("cozinha.forno.massa"))
	assert(helena.get_held_item() == "")
	assert(not helena.is_using_item())
	# O gelo é posto no ponto original somente ao concluir o gesto.
	helena.position = Vector2(376,344)
	helena.velocity = Vector2.ZERO
	helena.set_held_item("gelo")
	var drop = room.get_node("World1923/PisoDespensa")
	drop.interact(helena)
	assert(helena.is_using_item())
	assert(not state.is_set("cozinha.gelo.posto"))
	assert(helena.get_held_item() == "gelo")
	for tick in 60:
		await physics_frame
	assert(helena.get_held_item() == "")
	assert(state.is_set("cozinha.gelo.posto"))
	assert(state.is_set("cozinha.piso.apodrecido"))
	assert(state.get_flag("cozinha.gelo.x") == 376)
	assert(helena.get_node("Sprite").hframes == 5)
	assert(room.get_node("HUD")._message.get_theme_font_size("font_size") == 10)
	print("PASS: 2objetos idle/walk, virar, coleta, uso diferido, sem duplicacao, pausa/epoca, gelo e UIcompacta")
	quit()
