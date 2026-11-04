extends SceneTree
## Prévias das novas salas; não grava o progresso do jogador.
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(1280,720)
	root.get_node("WorldState").clear()
	for scene: String in ["manutencao","biblioteca"]:
		change_scene_to_file("res://scenes/rooms/"+scene+"_3d.tscn")
		await scene_changed
		for era in ([1] if scene=="manutencao" else [0,1]):
			root.get_node("EraManager").set_era(era)
			var motor = current_scene.get_node("Helena" if era==0 else "Lia")
			motor.position = Vector3(2.5,0,6.1) if scene=="manutencao" else Vector3(8.5,0,11.6)
			var target := Vector3(6.1,1,1) if scene=="manutencao" else Vector3(9,2.3,2)
			var delta: Vector3 = target - motor.get_camera().global_position
			motor.rotation.y = atan2(-delta.x,-delta.z)
			motor.get_node("Head").rotation.x = atan2(delta.y,Vector2(delta.x,delta.z).length())
			for i in 35:
				await process_frame
			var path := "res://art/previews/%s3d-%s.png" % [scene,"1923" if era==0 else "hoje"]
			root.get_texture().get_image().save_png(path)
			print("CAPTURE: ",path)
	quit()
