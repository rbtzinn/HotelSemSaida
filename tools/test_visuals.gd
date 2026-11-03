extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var room = load("res://scenes/rooms/cozinha.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	await physics_frame
	var lia = room.get_node("Lia")
	assert(lia.drawn_animations.get_frame_count("walk") == 16)
	assert(lia.drawn_animations.get_frame_count("idle") == 4)
	root.get_node("EraManager").set_era(1)
	await physics_frame
	await physics_frame
	assert(lia.get_node("Sprite").hframes == 1)
	assert(lia.get_node("Sprite").texture.get_height() == 288)
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("hotel-present.png"))
		root.get_node("EraManager").set_era(0)
		await physics_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("hotel-past.png"))
	print("PASS: presente desenhado, 16 quadros walk, 4 idle, escala fisica preservada")
	quit()
