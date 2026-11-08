extends SceneTree
## Quartos (2º andar): subida pela escada de 1923 e pelo poço, porta de pavimento, bandeira do 207,
## diário de Helena, chave mestra atrás do espelho, quarto 214 e caderno de Caio.
## Rodar: Godot_console.exe --headless --path . --fixed-fps 60 --script res://tools/test_quartos_3d.gd

class TestInput extends CharacterInput:
	var direction := Vector2.ZERO
	var interact := false
	func get_move() -> Vector2:
		return direction
	func is_interact_just_pressed() -> bool:
		var pressed := interact
		interact = false
		return pressed


const LOBBY := "res://scenes/rooms/saguao_3d.tscn"
const FLOOR := "res://scenes/rooms/quartos_3d.tscn"

var state: Node
var eras: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("WorldState")
	eras = root.get_node("EraManager")
	state.clear()
	for flag in ["saguao.elevador.no_alto", "saguao.bolsa.marta"]:
		state.set_flag(flag)
	root.get_node("RoomManager").clear_away()

	# Helena sobe a escada principal de 1923
	eras.set_era(0)
	change_scene_to_file(LOBBY)
	await scene_changed
	await physics_frame
	await _use("Helena", "World1923/SubirEscada", Vector3(3.0, 0, 4.6))
	await _wait_room(FLOOR)
	var helena = current_scene.get_node("Helena")
	assert(helena.position.distance_to(Vector3(3.0, 0, 2.9)) < 0.2, "Helena chega pela escada: %s" % helena.position)

	# Q1: cunha no carrinho e alavanca calçada
	await _use("Helena", "World1923/Alavanca", Vector3(17.4, 0, 3.2))
	assert(not state.is_set("quartos.pavimento.calcado"), "Sem cunha a alavanca volta")
	await _use("Helena", "World1923/Cunha", Vector3(5.2, 0, 3.2))
	assert(state.get_flag("helena.mao") == "cunha")
	await _use("Helena", "World1923/Alavanca", Vector3(17.4, 0, 3.2))
	assert(state.is_set("quartos.pavimento.calcado") and state.get_flag("helena.mao") == "")
	# Q2: bandeira, por dentro do 207 (aberto em 1923)
	await _use("Helena", "World1923/Correntinha", Vector3(7.6, 0, 5.8))
	assert(state.is_set("quartos.bandeira.aberta"))
	# Q3: diário da escrivaninha para o fundo falso da mala
	await _use("Helena", "World1923/Escrivaninha", Vector3(7.2, 0, 7.0))
	assert(state.get_flag("helena.mao") == "diario" and int(state.get_flag("quartos.diario.local")) == 4)
	await _use("Helena", "World1923/Mala", Vector3(8.0, 0, 5.4))
	assert(int(state.get_flag("quartos.diario.local")) == 3 and state.get_flag("helena.mao") == "")
	# Q4: chave mestra da rouparia escondida atrás do espelho
	await _use("Helena", "World1923/ArmarioGovernanta", Vector3(7.9, 0, 1.2))
	assert(state.get_flag("helena.mao") == "chave_mestra")
	await _use("Helena", "World1923/Espelho", Vector3(10.9, 0, 3.2))
	assert(state.is_set("quartos.chave_mestra.escondida") and state.get_flag("helena.mao") == "")

	# Hoje: Lia sobe pelo poço do Saguão (sala da Lia é o Saguão; Tab abre a sala dela)
	await _reload(LOBBY, 1)
	await _use("Lia", "WorldToday/SubirAndar", Vector3(16.48, 0, 2.7))
	await _wait_room(FLOOR)
	var lia = current_scene.get_node("Lia")
	assert(lia.position.distance_to(Vector3(16.25, 0, 1.2)) < 0.2, "Lia chega pelo poço: %s" % lia.position)
	# A porta de pavimento está aberta: dá para sair do poço andando
	var out: Vector3 = await _walk(lia, Vector3(16.25, 0, 1.2), Vector2.DOWN, 90)
	assert(out.z > 2.6, "Lia sai do poço para o corredor: %s" % out)
	var blocked: Vector3 = await _walk(lia, Vector3(7.6, 0, 3.6), Vector2.DOWN, 90)
	assert(blocked.z < 4.3, "A porta fechada do 207 bloqueia: %s" % blocked)
	blocked = await _walk(lia, Vector3(12.5, 0, 3.0), Vector2.UP, 90)
	assert(blocked.z > 2.2, "A porta fechada do 214 bloqueia: %s" % blocked)
	await _use("Lia", "WorldToday/Porta207", Vector3(7.5, 0, 3.5))
	assert(not state.is_set("quartos.207.aberto"), "Sem cabide a porta não abre")
	await _use("Lia", "WorldToday/Cabide", Vector3(7.6, 0, 1.0))
	assert(state.get_flag("lia.mao") == "cabide")
	await _use("Lia", "WorldToday/Porta207", Vector3(7.5, 0, 3.5))
	assert(state.is_set("quartos.207.aberto") and state.get_flag("lia.mao") == "")
	var inside: Vector3 = await _walk(lia, Vector3(7.6, 0, 3.6), Vector2.DOWN, 90)
	assert(inside.z > 5.2, "A porta do 207 abriu de verdade: %s" % inside)
	await _use("Lia", "WorldToday/Mala", Vector3(8.0, 0, 5.4))
	assert(state.is_set("quartos.diario.lido") and paused, "O diário sobreviveu na mala")
	await _close_note()
	await _use("Lia", "WorldToday/Espelho", Vector3(10.9, 0, 3.2))
	assert(state.get_flag("lia.mao") == "chave_mestra" and state.is_set("quartos.chave_mestra.pega"))
	await _use("Lia", "WorldToday/Porta214", Vector3(12.5, 0, 3.3))
	assert(state.is_set("quartos.214.aberto"))
	var room_214: Vector3 = await _walk(lia, Vector3(12.5, 0, 3.0), Vector2.UP, 90)
	assert(room_214.z < 1.5, "A porta do 214 abriu de verdade: %s" % room_214)
	var notebook = current_scene.get_node("WorldToday/CadernoCaio")
	assert("virou pó" in notebook.text, "Sem a partitura guardada, Caio não a achou")
	state.set_flag("salao.partitura.guardada")
	assert("números das teclas" in notebook.text, "Com a partitura guardada, Caio a anotou")
	await _use("Lia", "WorldToday/CadernoCaio", Vector3(13.3, 0, 0.6))
	assert(state.is_set("quartos.concluido"))
	await _close_note()

	# Tudo continua no lugar ao recarregar
	await _reload(FLOOR, 1)
	assert(not current_scene.get_node("WorldToday/PortaPavimento").visible)
	assert(current_scene.get_node("WorldToday/Folha207").rotation_degrees.y < -60)
	assert(current_scene.get_node("WorldToday/Folha214").rotation_degrees.y > 60)
	# Lia volta ao Saguão pelo poço
	await _use("Lia", "WorldToday/DescerPoco", Vector3(16.25, 0, 1.2))
	await _wait_room(LOBBY)
	assert(current_scene.get_node("Lia").position.distance_to(Vector3(16.48, 0, 2.55)) < 0.2)
	print("PASS: Quartos: escada e poço, pavimento, bandeira do 207, diário na mala, chave mestra, 214, caderno de Caio e recarga")
	quit()


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
