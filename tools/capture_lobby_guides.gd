extends SceneTree
## Captura o Saguão sem personagens nem HUD, nas duas épocas, como guia de geometria
## para a geração das pinturas. Rodar sem --headless:
## Godot_console.exe --path . --script res://tools/capture_lobby_guides.gd
## Depois: python tools/make_art_guides.py


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var room: Node = load("res://scenes/rooms/saguao.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	# Transparentes, e não removidas: o roteador de input continua achando as duas
	for node_name in ["Helena", "Lia"]:
		room.get_node(node_name).modulate.a = 0.0
	room.get_node("HUD").hide()
	var out := ProjectSettings.globalize_path("res://art/environment/source")
	for era in [0, 1]:
		root.get_node("EraManager").set_era(era)
		for tick in 40:
			await process_frame
		var image := root.get_texture().get_image()
		image.resize(1536, 864, Image.INTERPOLATE_NEAREST)
		var path := out.path_join("lobby_game_%s.png" % ("1923" if era == 0 else "present"))
		image.save_png(path)
		print("guia: ", path)
	quit()
