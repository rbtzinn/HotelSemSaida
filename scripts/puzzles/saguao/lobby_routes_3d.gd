class_name LobbyRoutes3D
extends ChapterRoom3D
## Entrada da Biblioteca no Saguão, após a Cozinha. A chave de 1951 só é exigida hoje.
func _ready() -> void:
	for world_name: String in ["World1923","WorldToday"]:
		var world := get_node(world_name) as Node3D
		area(preload("res://scripts/interaction3d/key_door_3d.gd"),world,"PortaBiblioteca",Vector3(0.65,1.2,4.9),Vector3(0.3,2.4,1.3),{"target_scene":"res://scenes/rooms/biblioteca_3d.tscn","target_spawn":"DoSaguao","prompt_text":"Biblioteca","required_flag":"cozinha.concluida"})
	marker("DaBiblioteca",Vector3(1.5,0,4.9),-PI/2)
	super()
