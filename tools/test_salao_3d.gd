extends SceneTree
## Salão de baile (3º andar): botoeiras e cabine como degrau, escada de 1923, contrapeso da
## cortina (degrau hoje), partitura na banqueta (ida e volta) e leitura de Lia.
## Rodar: Godot_console.exe --headless --path . --fixed-fps 60 --script res://tools/test_salao_3d.gd

class TestInput extends CharacterInput:
	var direction := Vector2.ZERO
	var interact := false
	var jump := false
	func get_move() -> Vector2:
		return direction
	func is_interact_just_pressed() -> bool:
		var pressed := interact
		interact = false
		return pressed
	func is_jump_just_pressed() -> bool:
		var pressed := jump
		jump = false
		return pressed


const FLOOR := "res://scenes/rooms/quartos_3d.tscn"
const HALL := "res://scenes/rooms/salao_3d.tscn"
const LIFT := "saguao.elevador.andar"

var state: Node
var eras: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("WorldState")
	eras = root.get_node("EraManager")
	state.clear()
	state.set_flag("saguao.bolsa.marta")
	root.get_node("RoomManager").clear_away()
	var sheet: Texture2D = load("res://scripts/ui/score_sheet.gd").texture(true)
	assert(sheet.get_width() == 920, "A pauta é desenhada")

	# Helena, nos Quartos: sem a chave de Bento o elevador está desligado
	await _reload(FLOOR, 0)
	await _use("Helena", "World1923/Botoeira", Vector3(17.3, 0, 3.0))
	assert(int(state.get_flag(LIFT, 3)) == 3, "Sem a chave de Bento, a botoeira não chama a cabine")
	state.set_flag("saguao.elevador.no_alto")
	await _use("Helena", "World1923/Botoeira", Vector3(17.3, 0, 3.0))
	assert(int(state.get_flag(LIFT)) == 1, "A cabine para no 2º andar")
	assert(current_scene.get_node("World1923/Cabine").visible and current_scene.get_node("WorldToday/Cabine").visible)

	# Sobe a escada de 1923 até o Salão
	await _use("Helena", "World1923/SubirEscada", Vector3(3.75, 0, 3.0))
	await _wait_room(HALL)
	var helena = current_scene.get_node("Helena")
	assert(helena.position.distance_to(Vector3(3.0, 0, 2.9)) < 0.2, "Helena chega ao Salão: %s" % helena.position)
	assert(not current_scene.get_node("World1923/Cabine").visible)
	# A botoeira do 3º andar leva a cabine embora (e tira o degrau de Lia)
	await _use("Helena", "World1923/Botoeira", Vector3(17.3, 0, 3.0))
	assert(int(state.get_flag(LIFT)) == 2 and current_scene.get_node("World1923/Cabine").visible)
	# Contrapeso: o saco cai na frente do palco
	await _use("Helena", "World1923/Malagueta", Vector3(1.7, 0, 12.6))
	assert(state.is_set("salao.contrapeso.solto"))
	assert(current_scene.get_node("World1923/SacoCaido").visible and not current_scene.get_node("World1923/SacoPendurado").visible)
	# A escadinha de 1923 leva ao palco
	var up: Vector3 = await _walk(helena, Vector3(5.2, 0, 11.4), Vector2.DOWN, 120)
	assert(up.y > 1.1 and up.z > 14.0, "Helena sobe a escadinha do palco: %s" % up)
	# Partitura: da estante para a mão, para a banqueta, de volta para a mão e para a banqueta
	await _use("Helena", "World1923/Estante", Vector3(10.0, 1.2, 14.15))
	assert(str(state.get_flag("helena.mao")) == "partitura" and paused, "Helena pega a partitura e vê a pauta")
	await _close_note()
	await _use("Helena", "World1923/Banqueta", Vector3(12.3, 1.2, 15.0))
	assert(state.is_set("salao.partitura.guardada") and str(state.get_flag("helena.mao")) == "")
	await _use("Helena", "World1923/Banqueta", Vector3(12.3, 1.2, 15.0))
	assert(not state.is_set("salao.partitura.guardada") and str(state.get_flag("helena.mao")) == "partitura", "A partitura sai da banqueta")
	await _use("Helena", "World1923/Banqueta", Vector3(12.3, 1.2, 15.0))
	assert(state.is_set("salao.partitura.guardada"))
	# Desce e chama a cabine de volta ao 2º andar
	await _use("Helena", "World1923/DescerEscada", Vector3(3.0, 0, 3.0))
	await _wait_room(FLOOR)
	assert(current_scene.get_node("Helena").position.distance_to(Vector3(3.0, 0, 2.9)) < 0.2)

	# Hoje, com a cabine no 3º, a escada do poço partida não deixa Lia subir
	await _reload(FLOOR, 1)
	await _use("Lia", "WorldToday/SubirPoco", Vector3(16.48, 0, 1.3))
	for i in 30:
		await process_frame
	assert(current_scene.scene_file_path == FLOOR, "Sem a cabine aqui, Lia não sobe")
	state.set_flag(LIFT, 1)
	await _use("Lia", "WorldToday/SubirPoco", Vector3(16.48, 0, 1.3))
	await _wait_room(HALL)
	var lia = current_scene.get_node("Lia")
	assert(lia.position.distance_to(Vector3(16.25, 0, 1.2)) < 0.2, "Lia chega pelo poço: %s" % lia.position)
	var out: Vector3 = await _walk(lia, Vector3(16.25, 0, 1.2), Vector2.DOWN, 90)
	assert(out.z > 2.6, "A porta arrombada deixa Lia sair do poço: %s" % out)
	# Sem o saco, o palco é alto demais (a escadinha desabou)
	state.set_flag("salao.contrapeso.solto", false)
	var low: Vector3 = await _climb(lia, Vector3(5.2, 0, 12.6))
	assert(low.y < 0.5, "Sem a escadinha, Lia não sobe ao palco: %s" % low)
	low = await _climb(lia, Vector3(9.0, 0, 12.3))
	assert(low.y < 0.5, "Sem o monte de areia, Lia não sobe ao palco: %s" % low)
	state.set_flag("salao.contrapeso.solto")
	var stage: Vector3 = await _climb(lia, Vector3(9.0, 0, 12.3))
	assert(stage.y > 1.1 and stage.z > 14.0, "Pelo monte de areia, Lia sobe ao palco: %s" % stage)
	await _use("Lia", "WorldToday/Banqueta", Vector3(12.3, 1.2, 15.0))
	assert(state.is_set("salao.partitura.lida") and state.is_set("salao.concluido") and paused, "Lia lê a partitura de Caio")
	await _close_note()

	# Tudo continua no lugar ao recarregar
	await _reload(HALL, 1)
	assert(current_scene.get_node("WorldToday/MonteDeAreia").visible)
	assert(not current_scene.get_node("WorldToday/Cabine").visible)
	await _use("Lia", "WorldToday/DescerPoco", Vector3(16.25, 0, 1.2))
	await _wait_room(FLOOR)
	assert(current_scene.get_node("Lia").position.distance_to(Vector3(16.25, 0, 1.2)) < 0.2)
	print("PASS: Salão: botoeiras e cabine, escada de 1923, contrapeso e monte de areia, partitura ida e volta, leitura de Lia e recarga")
	quit()


## Anda para +z pulando de tempos em tempos; devolve onde parou.
func _climb(motor, start: Vector3) -> Vector3:
	var controls := TestInput.new()
	motor.input = controls
	motor.position = start
	motor.rotation = Vector3.ZERO
	motor.velocity = Vector3.ZERO
	controls.direction = Vector2.DOWN
	for i in 160:
		if i % 25 == 5 and i < 130:
			controls.jump = true
		await physics_frame
	controls.direction = Vector2.ZERO
	for i in 30:
		await physics_frame
	return motor.position


func _use(character: String, path: String, at: Vector3) -> void:
	var motor = current_scene.get_node(character)
	var target: Area3D = current_scene.get_node(path)
	var controls := TestInput.new()
	motor.input = controls
	motor.position = at
	motor.velocity = Vector3.ZERO
	var aim: Vector3 = target.global_position - motor.get_camera().global_position
	motor.rotation.y = atan2(-aim.x, -aim.z)
	motor.get_node("Head").rotation.x = atan2(aim.y, Vector2(aim.x, aim.z).length())
	for i in 4:
		await physics_frame
	assert(motor.focused == target, "Alvo fora de alcance: %s (mira: %s)" % [path, motor.focused])
	controls.interact = true
	for i in 3:
		await physics_frame


func _walk(motor, start: Vector3, direction: Vector2, ticks: int) -> Vector3:
	var controls := TestInput.new()
	motor.input = controls
	motor.position = start
	motor.rotation = Vector3.ZERO
	motor.velocity = Vector3.ZERO
	controls.direction = direction
	for i in ticks:
		await physics_frame
	controls.direction = Vector2.ZERO
	return motor.position


func _wait_room(path: String) -> void:
	for i in 240:
		await process_frame
		if current_scene and current_scene.scene_file_path == path and not root.get_node("RoomManager").is_changing():
			break
	assert(current_scene.scene_file_path == path, "Não chegou em " + path)
	for i in 3:
		await physics_frame


func _reload(path: String, era: int) -> void:
	state.load_dict(JSON.parse_string(JSON.stringify(state.to_dict())))
	root.get_node("RoomManager").clear_away()
	eras.set_era(era)
	change_scene_to_file(path)
	await scene_changed
	for i in 3:
		await physics_frame


func _close_note() -> void:
	for child in root.get_children():
		if child is CanvasLayer and child.has_method("close"):
			child.close()
	for i in 8:
		await process_frame
