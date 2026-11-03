extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.get_node("WorldState").set_flag("cozinha.elevador.travado",true)
	root.get_node("EraManager").set_era(1)
	var room = load("res://scenes/rooms/cozinha.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	var lia = room.get_node("Lia")
	lia.position = Vector2(552,136)
	await physics_frame
	await physics_frame
	var helena_origin: Vector2 = room.get_node("Helena").position
	var passage = room.get_node("WorldToday/PocoAberto/DescerCabos")
	assert(passage.has_body(lia))
	assert(passage.can_interact(lia))
	var origin: Vector2 = lia.position
	passage.interact(lia)
	assert(lia.is_traversing())
	assert(lia.get_save_position() == origin)
	assert(not passage.can_interact(lia))
	var stages := {}
	var captured := {}
	var textures := {}
	var paused_once := false
	var capture := "--capture" in OS.get_cmdline_user_args()
	for frame in 600:
		await physics_frame
		var stage: StringName = lia._cable_stage
		if stage != &"":
			if capture and not captured.has(stage) and stage != &"approach" and lia._cable_time > 0.2:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("lia-cable-%s.png" % stage))
				captured[stage] = true
			stages[stage] = true
		if stage == &"descend":
			var texture_path: String = lia.get_node("Sprite").texture.resource_path
			if "/descend_" in texture_path:
				textures[texture_path] = true
			if not paused_once:
				paused_once = true
				var stopped: Vector2 = lia.position
				paused = true
				await create_timer(0.1,true).timeout
				assert(lia.position == stopped)
				paused = false
				root.get_node("EraManager").set_era(0)
				for tick in 8:
					await physics_frame
				assert(lia.position == stopped)
				root.get_node("EraManager").set_era(1)
		if not lia.is_traversing():
			break
	assert(stages.size() == 4)
	assert(textures.size() == 12, "Todos os quadros de descida devem ser exibidos")
	assert(not lia.is_traversing())
	assert(lia.position.distance_to(Vector2(580,344)) < 1.0)
	assert(room.get_node("WorldToday/SubirCabos").has_body(lia))
	assert(room.get_node("Helena").position == helena_origin)
	assert(lia.get_node("Sprite").texture.resource_path.ends_with("lia_00.png"))
	print("PASS: 4 fases, 12 desenhos, pausa/epoca, save seguro, pouso, retorno e Helena preservada")
	quit()
