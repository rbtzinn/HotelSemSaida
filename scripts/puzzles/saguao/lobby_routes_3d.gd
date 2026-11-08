class_name LobbyRoutes3D
extends ChapterRoom3D
## Entrada da Biblioteca no Saguão, na parede norte (ala nordeste). Em 1923 a porta funciona normalmente para Helena;
## hoje está trancada e só a chave de 1951 (achada na manutenção, depois da Cozinha) abre.
## Nenhuma flag do presente controla o passado.

const LIBRARY_DOOR := Vector3(
	(LobbyRoom3D.LIBRARY_DOOR.x + LobbyRoom3D.LIBRARY_DOOR.y) / 2.0, 1.2, LobbyRoom3D.NORTH + 0.15)


func _ready() -> void:
	for world_name: String in ["World1923", "WorldToday"]:
		var world := get_node(world_name) as Node3D
		area(preload("res://scripts/interaction3d/key_door_3d.gd"), world, "PortaBiblioteca",
			LIBRARY_DOOR, Vector3(1.3, 2.4, 0.3), {
				"target_scene": "res://scenes/rooms/biblioteca_3d.tscn",
				"target_spawn": "DoSaguao",
				"prompt_text": "Biblioteca",
			})
	marker("DaBiblioteca", Vector3(LIBRARY_DOOR.x, 0, LobbyRoom3D.NORTH + 1.0), PI)
	# Escada principal: em 1923 leva ao 2º andar; hoje desabou
	area(preload("res://scripts/interaction3d/door_3d.gd"), get_node("World1923"), "SubirEscada", Vector3(3.0, 1.0, 3.75),
		Vector3(3.0, 2.0, 0.2), {
			"target_scene": "res://scenes/rooms/quartos_3d.tscn", "target_spawn": "DaEscada",
			"prompt_text": "Subir ao 2º andar", "available_in": 0})
	area(preload("res://scripts/interaction3d/message_interactable_3d.gd"), get_node("WorldToday"), "EscadaDesabada",
		Vector3(3.0, 1.0, 3.75), Vector3(3.0, 2.0, 0.2), {
			"prompt_text": "Examinar escada", "available_in": 1,
			"message": "A escada principal desabou. Os degraus que sobraram não aguentam peso."})
	marker("DoAndar2Escada", Vector3(3.0, 0, 4.4), PI)
	marker("DoAndar2Poco", Vector3(16.48, 0, 2.55), PI)
	var lift := preload("res://scripts/puzzles/saguao/lobby_lift_puzzle_3d.gd").new()
	add_child(lift)
	lift.install(self)
	var exit := preload("res://scripts/puzzles/saguao/lobby_exit_puzzle_3d.gd").new()
	add_child(exit)
	exit.install(self)
	var piano := preload("res://scripts/puzzles/saguao/lobby_piano_3d.gd").new()
	add_child(piano)
	piano.install(self)
	super()
