extends SceneTree
## Verifica o fluxo do botão Jogar solo, a troca visual de época e a entrega do controle.
## -- --capture DIRETÓRIO gera quadros da abertura com o Godot em modo gráfico.

const LOBBY := "res://scenes/ui/entrada.tscn"
const HOTEL := "res://scenes/rooms/saguao_3d.tscn"

var _capture_dir := ""


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() == 2 and args[0] == "--capture":
		_capture_dir = args[1]

	var rooms := root.get_node("RoomManager")
	var eras := root.get_node("EraManager")
	await rooms.open_scene(LOBBY)
	await process_frame
	var play: Button = current_scene.get("_solo")
	play.pressed.emit()
	while rooms.is_changing():
		await process_frame
	assert(current_scene.scene_file_path == HOTEL)
	var opening := current_scene.get_node("Opening")
	opening.set_process(false)
	assert(paused and not current_scene.get_node("HUD").visible)
	assert(root.get_camera_3d() != current_scene.get_node("Helena").get_camera())
	await _frame(opening, 2.35, "01-saguao")
	await _frame(opening, 4.52, "02-janela")
	await _frame(opening, 5.75, "03-fachada")
	await _frame(opening, 10.9, "04-1923")
	var past_camera := root.get_camera_3d().global_transform
	assert(current_scene.get_node("Opening").get("_outside_1923").visible)
	await _frame(opening, 12.2, "05-hoje")
	assert(current_scene.get_node("Opening").get("_outside_today").visible)
	assert(root.get_camera_3d().global_transform.is_equal_approx(past_camera))
	assert(eras.current_era == Era.Id.PAST_1923)
	await _frame(opening, 15.5, "06-titulo")
	await _frame(opening, 21.75, "07-retorno")
	opening._process(1.0)
	await process_frame
	assert(not paused and not current_scene.has_node("Opening"))
	assert(root.get_camera_3d() == current_scene.get_node("Helena").get_camera())
	assert(current_scene.get_node("World1923").visible and current_scene.get_node("HUD").visible)

	# A outra ponta da dupla tem a Lia como câmera local e a abertura ainda parte de 1923.
	eras.set_era(Era.Id.PRESENT)
	load("res://scripts/ui/opening.gd").start_in(current_scene)
	opening = current_scene.get_node("Opening")
	opening.set_process(false)
	assert(current_scene.get_node("World1923").visible and not current_scene.get_node("WorldToday").visible)
	opening._skip()
	await _frame(opening, 21.65, "08-retorno-lia")
	opening._process(1.0)
	await process_frame
	assert(not paused and not current_scene.has_node("Opening"))
	assert(root.get_camera_3d() == current_scene.get_node("Lia").get_camera())
	assert(current_scene.get_node("WorldToday").visible and not current_scene.get_node("World1923").visible)
	assert(current_scene.get_node("HUD").visible)
	print("PASS: nova partida, voo, corte entre épocas, pular e controle devolvido às duas personagens")
	await root.get_node("Audio").quit()


func _frame(opening: Node, at: float, label: String) -> void:
	opening._process(at - opening.get("_elapsed"))
	if _capture_dir.is_empty():
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	assert(image.save_png(_capture_dir.path_join(label + ".png")) == OK)
