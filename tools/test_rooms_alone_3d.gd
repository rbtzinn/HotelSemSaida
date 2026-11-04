extends SceneTree
## Em 3D só a personagem ativa passa pela porta: a outra fica onde foi deixada, na sala dela.
## O Tab abre a sala da outra; o save guarda as duas salas. O save real do jogador é
## preservado (copiado antes e restaurado no fim).
## Rodar: Godot_console.exe --headless --path . --fixed-fps 60 --script res://tools/test_rooms_alone_3d.gd

const SAGUAO := "res://scenes/rooms/saguao_3d.tscn"
const COZINHA := "res://scenes/rooms/cozinha_3d.tscn"

var era_manager: Node
var room_manager: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	era_manager = root.get_node("EraManager")
	room_manager = root.get_node("RoomManager")
	var save_system := root.get_node("SaveSystem")
	var real_save := ""
	if FileAccess.file_exists(save_system.SAVE_PATH):
		real_save = FileAccess.get_file_as_string(save_system.SAVE_PATH)
	root.get_node("WorldState").clear()
	room_manager.clear_away()
	era_manager.set_era(0)
	change_scene_to_file(SAGUAO)
	await scene_changed
	await physics_frame

	var lia_spot := Vector3(13, 0, 9)
	current_scene.get_node("Lia").position = lia_spot
	current_scene.get_node("Lia").rotation.y = 1.0
	var helena = current_scene.get_node("Helena")
	helena.position = Vector3(1.4, 0, 7.25)
	await physics_frame
	current_scene.get_node("World1923/PortaCozinha").interact(helena)
	await _settle()
	assert(current_scene.scene_file_path == COZINHA, "Helena entrou na Cozinha")
	assert(current_scene.get_node("Helena").position.distance_to(Vector3(3.6, 4.5, 5.2)) < 0.1, "Helena no ponto de entrada")
	assert(room_manager.is_away(1), "A Lia ficou no Saguão")

	var helena_spot := Vector3(6, 4.5, 4)
	current_scene.get_node("Helena").position = helena_spot
	await physics_frame
	era_manager.switch_era()
	await _settle()
	assert(current_scene.scene_file_path == SAGUAO and era_manager.current_era == 1, "Tab abre a sala da Lia")
	var lia = current_scene.get_node("Lia")
	assert(lia.position.distance_to(lia_spot) < 0.05 and is_equal_approx(lia.rotation.y, 1.0), "Lia onde foi deixada: %s" % lia.position)
	assert(lia.get_camera().current, "Câmera nos olhos da Lia")
	assert(room_manager.is_away(0) and not room_manager.is_away(1), "Agora a Helena é que está fora")

	era_manager.switch_era()
	await _settle()
	assert(current_scene.scene_file_path == COZINHA and era_manager.current_era == 0, "Tab volta à Cozinha")
	assert(current_scene.get_node("Helena").position.distance_to(helena_spot) < 0.05, "Helena onde foi deixada")

	# Salvar com cada uma numa sala e carregar
	assert(save_system.save_game(), "Salvou")
	current_scene.get_node("Helena").position = Vector3(10, 4.5, 4)
	save_system.load_game()
	await _settle()
	assert(current_scene.scene_file_path == COZINHA, "Carregou a sala ativa")
	assert(current_scene.get_node("Helena").position.distance_to(helena_spot) < 0.05, "Helena volta ao lugar salvo")
	assert(room_manager.is_away(1), "A Lia continua no Saguão depois de carregar")
	era_manager.switch_era()
	await _settle()
	assert(current_scene.get_node("Lia").position.distance_to(lia_spot) < 0.05, "Lia no lugar salvo, no Saguão")

	# A Lia volta para a Cozinha pela porta: as duas na mesma sala de novo
	current_scene.get_node("Lia").position = Vector3(1.4, 0, 7.25)
	await physics_frame
	current_scene.get_node("WorldToday/PortaCozinha").interact(current_scene.get_node("Lia"))
	await _settle()
	assert(current_scene.scene_file_path == COZINHA, "Lia na Cozinha")
	assert(current_scene.get_node("Helena").position.distance_to(helena_spot) < 0.05, "Helena já estava lá, no lugar dela")
	assert(not room_manager.is_away(0) and not room_manager.is_away(1), "As duas na mesma sala")

	if real_save != "":
		var file := FileAccess.open(save_system.SAVE_PATH, FileAccess.WRITE)
		file.store_string(real_save)
		file.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_system.SAVE_PATH))
	print("PASS: so a ativa passa pela porta; Tab abre a sala da outra; save guarda as duas salas")
	quit()


func _settle() -> void:
	for tick in 5:
		await process_frame
	while room_manager.is_changing() or era_manager.is_switching():
		await process_frame
	for tick in 3:
		await physics_frame
