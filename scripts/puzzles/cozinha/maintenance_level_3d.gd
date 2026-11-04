class_name MaintenanceLevel3D
extends ChapterRoom3D
## Lia desce pelo buraco da despensa até a manutenção, pega a chave e sobe à Biblioteca.
func _ready() -> void:
	for present: bool in [false,true]:
		var world := make_world(preload("res://scripts/puzzles/cozinha/maintenance_room_3d.gd"),present)
		area(preload("res://scripts/interaction3d/key_door_3d.gd"),world,"ParaBiblioteca",Vector3(4.5,1.3,8.7),Vector3(1.7,2.6,0.35),{"target_scene":"res://scenes/rooms/biblioteca_3d.tscn","target_spawn":"DaManutencao","prompt_text":"Subir à Biblioteca"})
		area(preload("res://scripts/interaction3d/door_3d.gd"),world,"ParaDespensa",Vector3(1.55,1.25,7.2),Vector3(0.9,2.5,0.4),{"target_scene":"res://scenes/rooms/cozinha_3d.tscn","target_spawn":"DaManutencao","prompt_text":"Subir à despensa"})
		# A mesma saída também pode ser usada mirando o alçapão no alto da escada.
		area(preload("res://scripts/interaction3d/door_3d.gd"),world,"AlcapaoDespensa",Vector3(1.55,3.4,7.2),Vector3(0.9,0.3,0.95),{"target_scene":"res://scenes/rooms/cozinha_3d.tscn","target_spawn":"DaManutencao","prompt_text":"Subir à despensa"})
		if present:
			var key := key_visual(world,Vector3(6.4,0.94,0.82),true)
			key.visible = not WorldState.is_set("manutencao.chave.pega")
			var pickup := area(preload("res://scripts/interaction3d/item_pickup_3d.gd"),world,"Chave",Vector3(6.4,1,0.97),Vector3(0.45,0.25,0.55),{"item_id":"chave_biblioteca","taken_flag":"manutencao.chave.pega","prompt_text":"Pegar chave"})
			pickup.interacted.connect(func(_by: FirstPersonMotor) -> void: key.hide())
			area(preload("res://scripts/interaction3d/note_interactable_3d.gd"),world,"Etiqueta",Vector3(5.25,1.2,1.02),Vector3(0.5,0.4,0.2),{"title":"Etiqueta presa à chave","text":"BIBLIOTECA — ACESSO DE SERVIÇO\n\nDuplicata, 1951. Retirada para o arquivo do Dr. Caio Ferraz.\nDevolver à manutenção.","prompt_text":"Ler etiqueta"})
			box(world,Vector3(5.25,0.93,0.8),Vector3(0.24,0.02,0.2),"paper",true)
	marker("DaDespensa",Vector3(2.6,0,6.3))
	super()
