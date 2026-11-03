extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var room = load("res://scenes/rooms/cozinha.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	room.get_node("Helena").hide()
	room.get_node("Lia").hide()
	room.get_node("HUD").hide()
	for path in ["World1923/PortaDespensa", "World1923/Cardapio", "World1923/Elevador/Cabine", "World1923/Forno/Massa", "World1923/Fermento", "World1923/PisoDespensa/Bloco", "WorldToday/CardapioDesbotado", "WorldToday/FornoDesmoronado", "WorldToday/FornoPetrificado", "WorldToday/CabineEmbaixo", "WorldToday/PocoAberto", "WorldToday/Portinhola", "WorldToday/Mancha", "WorldToday/Fresta", "WorldToday/Buraco"]:
		room.get_node(path).hide()
	for era in [0,1]:
		root.get_node("EraManager").set_era(era)
		for path in ["WorldToday/FornoDesmoronado", "WorldToday/FornoPetrificado", "WorldToday/CabineEmbaixo", "WorldToday/PocoAberto", "WorldToday/Fresta", "WorldToday/Buraco"]:
			room.get_node(path).hide()
		room.get_node("Helena").hide()
		room.get_node("Lia").hide()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("hotel-art-guide-%d.png"%era))
	quit()
