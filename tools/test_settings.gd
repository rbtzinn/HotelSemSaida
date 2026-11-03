extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var settings = root.get_node("Settings")
	var original: Dictionary = settings.data.duplicate(true)
	var room = load("res://scenes/rooms/cozinha.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	await process_frame
	paused = true
	var menu = load("res://scripts/ui/settings_menu.gd").new()
	root.add_child(menu)
	await process_frame
	assert(menu.tabs.get_tab_count() == 3)
	assert(menu.binding_buttons.size() == 10)
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("hotel-settings.png"))
		menu.queue_free()
		quit()
		return
	settings.config_path = "user://settings-test.cfg"
	menu.waiting = "interact"
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_RIGHT
	click.pressed = true
	menu._input(click)
	assert(menu.draft.bindings.interact.kind == "mouse")
	menu.draft.volume = 0.35
	menu.draft.mute = true
	menu.draft.fps = 120
	menu._apply()
	assert(Engine.max_fps == 120)
	assert(AudioServer.is_bus_mute(0))
	assert(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(0)), 0.35))
	var has_mouse := false
	var has_controller := false
	for event in InputMap.action_get_events("interact"):
		has_mouse = has_mouse or event is InputEventMouseButton
		has_controller = has_controller or event is InputEventJoypadButton
	assert(has_mouse and has_controller)
	var cfg := ConfigFile.new()
	assert(cfg.load(settings.config_path) == OK)
	assert(cfg.get_value("preferences","bindings").interact.kind == "mouse")
	menu.draft.fps = 30
	settings.apply(menu.draft)
	menu.pending_video = true
	menu.confirm_left = 0.01
	menu._process(1.0)
	assert(Engine.max_fps == 120, "Deve reverter para o ultimo estado confirmado")
	menu._cancel()
	settings.apply(original)
	DirAccess.remove_absolute(settings.config_path)
	settings.config_path = settings.PATH
	paused = false
	await process_frame
	print("PASS: menu, mouse, controle preservado, volume/mute, FPS, persistencia, reversao")
	quit()
