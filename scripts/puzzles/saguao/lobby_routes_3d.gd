class_name LobbyRoutes3D
extends ChapterRoom3D
## Entrada da Biblioteca no Saguão. Em 1923 a porta funciona normalmente para Helena;
## hoje está trancada e só a chave de 1951 (achada na manutenção, depois da Cozinha) abre.
## Nenhuma flag do presente controla o passado.

const LIBRARY_DOOR := Vector3(0.65, 1.2, 4.9)


func _ready() -> void:
	for world_name: String in ["World1923", "WorldToday"]:
		var world := get_node(world_name) as Node3D
		area(preload("res://scripts/interaction3d/key_door_3d.gd"), world, "PortaBiblioteca",
			LIBRARY_DOOR, Vector3(0.3, 2.4, 1.3), {
				"target_scene": "res://scenes/rooms/biblioteca_3d.tscn",
				"target_spawn": "DoSaguao",
				"prompt_text": "Biblioteca",
			})
	marker("DaBiblioteca", Vector3(1.5, 0, 4.9), -PI / 2)
	var lift := preload("res://scripts/puzzles/saguao/lobby_lift_puzzle_3d.gd").new()
	add_child(lift)
	lift.install(self)
	super()
