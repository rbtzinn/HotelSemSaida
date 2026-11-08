class_name MaintenanceLevel3D
extends ChapterRoom3D
## Lia desce pelo buraco da despensa até a manutenção, pega a chave e sobe à Biblioteca.

const KEY_DOOR := preload("res://scripts/interaction3d/key_door_3d.gd")
const DOOR := preload("res://scripts/interaction3d/door_3d.gd")
const PICKUP := preload("res://scripts/interaction3d/item_pickup_3d.gd")
const NOTE := preload("res://scripts/interaction3d/note_interactable_3d.gd")
const KEY_TAKEN := "manutencao.chave.pega"


func _ready() -> void:
	StoryTrigger.attach(self, "cozinha.concluida", StoryCutscenes.kitchen_end, true)
	for present: bool in [false, true]:
		var world := make_world(preload("res://scripts/puzzles/cozinha/maintenance_room_3d.gd"), present)
		_build_exits(world)
		if present:
			_build_key(world)
	_build_time_cards()
	marker("DaDespensa", Vector3(2.6, 0, 6.3))
	marker("DaBiblioteca", Vector3(MaintenanceRoom3D.CORRIDOR_END - 1.6, 0, _corridor_mid()), PI / 2)
	super()


func _build_exits(world: Node3D) -> void:
	var stairs := Vector3(MaintenanceRoom3D.CORRIDOR_END - 0.3, 1.3, _corridor_mid())
	area(KEY_DOOR, world, "ParaBiblioteca", stairs, Vector3(0.35, 2.6, 1.7), {
		"target_scene": "res://scenes/rooms/biblioteca_3d.tscn",
		"target_spawn": "DaManutencao",
		"prompt_text": "Subir à Biblioteca",
	})
	var to_pantry := {
		"target_scene": "res://scenes/rooms/cozinha_3d.tscn",
		"target_spawn": "DaManutencao",
		"prompt_text": "Subir à despensa",
	}
	area(DOOR, world, "ParaDespensa", Vector3(1.55, 1.25, 7.2), Vector3(0.9, 2.5, 0.4), to_pantry)
	# A mesma saída também pode ser usada mirando o alçapão no alto da escada.
	area(DOOR, world, "AlcapaoDespensa", Vector3(1.55, 3.4, 7.2), Vector3(0.9, 0.3, 0.95), to_pantry)


func _corridor_mid() -> float:
	return (MaintenanceRoom3D.CORRIDOR_Z.x + MaintenanceRoom3D.CORRIDOR_Z.y) / 2.0


## A duplicata de 1951 da Biblioteca, sobre a bancada, com a etiqueta.
func _build_key(world: Node3D) -> void:
	var key := key_visual(world, Vector3(6.4, 0.94, 0.82), true)
	key.visible = not WorldState.is_set(KEY_TAKEN)
	var pickup := area(PICKUP, world, "Chave", Vector3(6.4, 1, 0.97), Vector3(0.45, 0.25, 0.55), {
		"item_id": "chave_biblioteca",
		"taken_flag": KEY_TAKEN,
		"prompt_text": "Pegar chave",
	})
	pickup.interacted.connect(func(_by: FirstPersonMotor) -> void: key.hide())
	area(NOTE, world, "Etiqueta", Vector3(5.25, 1.2, 1.02), Vector3(0.5, 0.4, 0.2), {
		"title": "Etiqueta presa à chave",
		"text": "BIBLIOTECA — ACESSO DE SERVIÇO\n\nDuplicata, 1951. Retirada para o arquivo do Dr. Caio Ferraz.\nDevolver à manutenção.",
		"prompt_text": "Ler etiqueta",
	})
	box(world, Vector3(5.25, 0.93, 0.8), Vector3(0.24, 0.02, 0.2), "paper", true)


## Fichas de ponto: hoje, a de Otília resistiu, com entradas carimbadas e nenhuma saída.
## Liga a descoberta da Cozinha ao nome que o livro do Saguão vai mostrar.
func _build_time_cards() -> void:
	var spot := Vector3(0.35, 1.45, 4.7)
	var size := Vector3(0.4, 1.0, 1.6)
	area(NOTE, get_node("World1923"), "FichasDePonto", spot, size, {
		"title": "Relógio de ponto",
		"text": "As fichas da semana, em ordem, uma por funcionário. Cada entrada tem sua saída carimbada ao lado.",
		"prompt_text": "Ler fichas",
		"available_in": Interactable3D.Availability.PAST_ONLY,
	})
	area(NOTE, get_node("WorldToday"), "FichasDePonto", spot, size, {
		"title": "Relógio de ponto",
		"text": "Quase todas as fichas viraram pó nos escaninhos. Uma resistiu, presa no alto:\n\nOTÍLIA — COZINHA\n\nEntradas carimbadas até 14 de março de 1923. Na coluna da saída, nada.",
		"prompt_text": "Ler fichas",
		"available_in": Interactable3D.Availability.PRESENT_ONLY,
	})
