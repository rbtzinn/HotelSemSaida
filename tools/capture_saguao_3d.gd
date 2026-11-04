extends SceneTree
## Capturas do Saguão 3D de vários pontos de vista, nas duas épocas, para conferir o visual.
## Rodar sem --headless: Godot_console.exe --path . --script res://tools/capture_saguao_3d.gd
## As imagens vão para a pasta TEMP (saguao3d-<época>-<n>.png).

const VIEWS := [
	[Vector3(10, 0, 10.2), 0.0, -0.05],
	[Vector3(13.5, 0, 9.6), 40.0, 0.05],
	[Vector3(6.5, 0, 8.0), -60.0, 0.0],
	[Vector3(10, 0, 4.6), 180.0, 0.15],
	[Vector3(8.0, 0, 6.0), -120.0, -0.1],
]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var room: Node = load("res://scenes/rooms/saguao_3d.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	for era in [0, 1]:
		root.get_node("EraManager").set_era(era)
		var motor = room.get_node("Helena" if era == 0 else "Lia")
		for index in VIEWS.size():
			var view: Array = VIEWS[index]
			motor.position = view[0]
			motor.rotation_degrees = Vector3(0, view[1], 0)
			motor.get_node("Head").rotation.x = view[2]
			for tick in 45:
				await process_frame
			var path := OS.get_environment("TEMP").path_join("saguao3d-%s-%d.png" % ["1923" if era == 0 else "hoje", index])
			root.get_texture().get_image().save_png(path)
			print("captura: ", path)
	quit()
