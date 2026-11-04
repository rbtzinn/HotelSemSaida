extends SceneTree
## Cozinha 3D, do começo ao fim: porta trancada, escada, fermento no forno, elevador travado,
## gelo no ponto da fresta e, hoje, a Lia subindo no forno petrificado, descendo pelos cabos
## e saindo pelo buraco de volta ao Saguão.
## Rodar: Godot_console.exe --headless --path . --fixed-fps 60 --script res://tools/test_cozinha_3d.gd
## Com -- --capture (sem --headless), salva capturas das duas épocas na pasta TEMP.

const K := 4.5

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


var room: Node
var world_state: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var era_manager := root.get_node("EraManager")
	world_state = root.get_node("WorldState")
	world_state.clear()
	era_manager.set_era(0)
	room = load("res://scenes/rooms/cozinha_3d.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	var helena = room.get_node("Helena")
	var lia = room.get_node("Lia")
	var helena_input := TestInput.new()
	helena.input = helena_input
	await physics_frame

	# Peças que mudam com os enigmas continuam com a própria malha (não viram cenário fixo)
	for prop in ["World1923/PortaFechada/Folha", "World1923/PortaAberta/Folha", "World1923/Elevador/AlavancaPega", "World1923/Elevador/Cabine", "WorldToday/FornoDesabado/Fogao", "WorldToday/FornoPetrificado/Fogao"]:
		assert(room.get_node(prop).find_child("Merged", false, false) != null, "%s tem a própria malha" % prop)

	# Com o jogo pausado (bilhete, cadeado), a personagem não anda
	helena.position = Vector3(3.0, K, 4.0)
	paused = true
	helena_input.direction = Vector2.UP
	for tick in 20:
		await physics_frame
	helena_input.direction = Vector2.ZERO
	paused = false
	assert(helena.position.is_equal_approx(Vector3(3.0, K, 4.0)), "Parada durante a pausa: %s" % helena.position)

	# Porta da despensa trancada: Helena para na folha
	var stopped: Vector3 = await _walk(helena, helena_input, Vector3(0.75, K, 2.6), 0.0, 120)
	assert(stopped.z > 1.55, "A porta trancada segura a Helena: z=%s" % stopped.z)
	assert(await _aim(helena, Vector3(0.75, K + 1.1, 1.6)) == room.get_node("World1923/PortaFechada/Cadeado"), "Helena mira o cadeado")
	# O minigame do cadeado é testado à parte; aqui só a consequência
	world_state.set_flag("cozinha.despensa.aberta")
	await physics_frame
	assert(not room.get_node("World1923/PortaFechada").visible and room.get_node("World1923/PortaAberta").visible, "A porta se abre na hora")
	stopped = await _walk(helena, helena_input, Vector3(0.75, K, 2.6), 0.0, 90)
	assert(stopped.z < 1.0, "Pela porta aberta ela chega ao patamar: z=%s" % stopped.z)

	# Escada: do patamar até o piso da despensa
	stopped = await _walk(helena, helena_input, Vector3(0.9, K, 0.7), -PI / 2.0, 360)
	assert(stopped.y < 0.1 and stopped.x > 7.2, "Helena desce a escada: %s" % stopped)

	# Fermento na estante e massa no forno
	helena.position = Vector3(9.2, 0, 1.1)
	assert(await _aim(helena, Vector3(9.2, 1.2, 0.3)) == room.get_node("World1923/Fermento/Pegar"), "Mira o fermento")
	await _press(helena, helena_input)
	assert(helena.get_held_item() == "fermento" and not room.get_node("World1923/Fermento").visible, "Pegou o fermento")
	helena.position = Vector3(14.6, K, 2.0)
	assert(await _aim(helena, Vector3(14.6, K + 0.5, 1.1)) == room.get_node("World1923/Forno"), "Mira o forno")
	await _press(helena, helena_input)
	assert(world_state.is_set("cozinha.forno.massa") and helena.get_held_item() == "", "A massa ficou no forno")

	# Elevador: sobe a cabine e puxa o freio
	helena.position = Vector3(16.9, K, 2.7)
	assert(await _aim(helena, Vector3(17.9, K + 1.3, 2.4)) == room.get_node("World1923/Elevador/Alavanca"), "Mira a alavanca")
	var handle = room.get_node("World1923/Elevador/AlavancaPega")
	var handle_before: float = handle.rotation_degrees.x
	await _press(helena, helena_input)
	assert(not is_equal_approx(handle.rotation_degrees.x, handle_before), "A alavanca vira")
	for tick in 160:
		await physics_frame
	assert(await _aim(helena, Vector3(17.9, K + 1.3, 2.95)) == room.get_node("World1923/Elevador/Freio"), "Mira o freio")
	await _press(helena, helena_input)
	assert(world_state.is_set("cozinha.elevador.travado"), "Cabine travada no alto")

	# Gelo: errar primeiro (longe da fresta), depois acertar entre os dois pilares
	for spot: Vector3 in [Vector3(6.0, 0, 4.2), Vector3(11.75, 0, 3.8)]:
		helena.position = Vector3(13.7, 0, 1.9)
		assert(await _aim(helena, Vector3(13.7, 0.9, 0.97)) == room.get_node("World1923/Gelo"), "Mira a geladeira")
		await _press(helena, helena_input)
		assert(helena.get_held_item() == "gelo", "Pegou gelo")
		helena.position = spot
		helena.rotation.y = 0.0
		helena.get_node("Head").rotation.x = 1.0
		for tick in 3:
			await physics_frame
		assert(helena.focused == room.get_node("World1923/PisoDespensa"), "Zona do piso ativa com o gelo na mão")
		await _press(helena, helena_input)
		assert(helena.get_held_item() == "", "Deixou o gelo")
		assert(room.get_node("World1923/PisoDespensa/Bloco").visible, "O bloco aparece no chão")
	assert(world_state.is_set("cozinha.piso.apodrecido"), "O último bloco ficou sobre a fresta")
	var block_at: Vector3 = room.get_node("World1923/PisoDespensa/Bloco").global_position
	assert(Vector2(block_at.x, block_at.z).distance_to(Vector2(11.75, 3.2)) < 0.1, "Bloco 0,6 m à frente dos pés: %s" % block_at)

	if "--capture" in OS.get_cmdline_user_args():
		await _capture(helena, Vector3(2.0, K, 5.4), Vector3(14.0, K + 1.0, 1.0), "cozinha3d-1923-cozinha")
		await _capture(helena, Vector3(16.5, 0, 5.0), Vector3(8.0, 0.8, 1.0), "cozinha3d-1923-despensa")
		await _capture(helena, Vector3(0.75, K, 3.4), Vector3(0.75, K + 1.2, 1.4), "cozinha3d-1923-porta")
		await _capture(helena, Vector3(16.4, K, 2.7), Vector3(18.0, K + 1.5, 1.6), "cozinha3d-1923-elevador")

	# Hoje: forno petrificado, poço aberto, mancha no lugar do gelo
	era_manager.set_era(1)
	await physics_frame
	var lia_input := TestInput.new()
	lia.input = lia_input
	assert(room.get_node("WorldToday/FornoPetrificado").visible and not room.get_node("WorldToday/FornoDesabado").visible, "Hoje o forno está petrificado")
	assert(room.get_node("WorldToday/PocoAberto").visible and not room.get_node("WorldToday/CabineBaixa").visible, "Poço aberto")
	assert(room.get_node("WorldToday/Buraco").visible and not room.get_node("WorldToday/Fresta").visible, "Piso apodrecido")
	assert(helena.position.distance_to(Vector3(11.75, 0, 3.8)) < 0.2, "Helena fica onde foi deixada")

	# Do chão, a portinhola fica alta demais
	lia.position = Vector3(17.6, K, 1.0)
	assert(await _aim(lia, Vector3(17.85, K + 2.45, 0.9)) == null, "Do chão a Lia não alcança a portinhola")

	# Sobe no forno petrificado e pula para a prateleira
	lia.position = Vector3(15.0, K + 0.85, 0.5)
	lia.rotation.y = -PI / 2.0
	lia.get_node("Head").rotation.x = 0.0
	for tick in 10:
		await physics_frame
	lia_input.direction = Vector2.UP
	lia_input.jump = true
	for tick in 60:
		await physics_frame
	lia_input.direction = Vector2.ZERO
	for tick in 20:
		await physics_frame
	assert(lia.position.y > K + 1.5 and lia.position.x > 16.2, "Lia sobe na prateleira: %s" % lia.position)

	if "--capture" in OS.get_cmdline_user_args():
		await _capture(lia, Vector3(13.2, K, 2.6), Vector3(16.5, K + 1.2, 0.5), "cozinha3d-hoje-forno")
		await _capture(lia, Vector3(17.0, K + 1.6, 0.3), Vector3(19.0, K + 2.2, 1.0), "cozinha3d-hoje-portinhola")

	# Da prateleira, desce pelos cabos até a despensa
	lia.position = Vector3(17.3, K + 1.6, 0.3)
	assert(await _aim(lia, Vector3(17.85, K + 2.45, 0.9)) == room.get_node("WorldToday/PocoAberto/DescerCabos"), "Mira a portinhola de cima da prateleira")
	await _press(lia, lia_input)
	assert(lia.is_traversing(), "Começa a descer")
	for tick in 600:
		await physics_frame
		if not lia.is_traversing():
			break
	assert(lia.position.distance_to(Vector3(17.4, 0, 1)) < 0.1, "Lia chega à despensa: %s" % lia.position)

	if "--capture" in OS.get_cmdline_user_args():
		await _capture(lia, Vector3(2.0, K, 5.4), Vector3(14.0, K + 1.0, 1.0), "cozinha3d-hoje-cozinha")
		await _capture(lia, Vector3(16.5, 0, 5.0), Vector3(11.0, 0.0, 3.0), "cozinha3d-hoje-despensa")

	# O buraco no piso leva de volta ao Saguão
	lia.position = Vector3(11.75, 0, 4.1)
	assert(await _aim(lia, Vector3(11.75, 0.1, 3.2)) == room.get_node("WorldToday/Buraco/Descer"), "Mira o buraco")
	await _press(lia, lia_input)
	assert(world_state.is_set("cozinha.concluida"), "Andar concluído")
	for tick in 120:
		await process_frame
	assert(current_scene.scene_file_path == "res://scenes/rooms/saguao_3d.tscn", "Voltou ao Saguão: %s" % current_scene.scene_file_path)
	var arrived = current_scene.get_node("Lia")
	assert(arrived.position.distance_to(Vector3(1.4, 0, 7.25)) < 0.3, "Chega pela porta da Cozinha: %s" % arrived.position)
	print("PASS: cozinha 3D completa (porta, escada, fermento, elevador, gelo, prateleira, cabos, buraco)")
	quit()


## Vira a personagem para o ponto e devolve o que ficou na mira.
func _aim(motor, target: Vector3):
	var eye: Vector3 = motor.position + Vector3(0, motor.eye_height, 0)
	var delta := target - eye
	motor.rotation = Vector3(0, atan2(-delta.x, -delta.z), 0)
	motor.get_node("Head").rotation.x = atan2(delta.y, Vector2(delta.x, delta.z).length())
	motor.velocity = Vector3.ZERO
	for tick in 3:
		await physics_frame
	return motor.focused


func _press(motor, input: TestInput) -> void:
	input.interact = true
	for tick in 3:
		await physics_frame


func _walk(motor, input: TestInput, start: Vector3, yaw: float, ticks: int) -> Vector3:
	motor.position = start
	motor.rotation = Vector3(0, yaw, 0)
	motor.velocity = Vector3.ZERO
	input.direction = Vector2.UP
	for tick in ticks:
		await physics_frame
	input.direction = Vector2.ZERO
	for tick in 5:
		await physics_frame
	return motor.position


func _capture(motor, at: Vector3, look: Vector3, file_name: String) -> void:
	var before: Vector3 = motor.position
	motor.position = at
	await _aim(motor, look)
	for tick in 30:
		await process_frame
	var path := OS.get_environment("TEMP").path_join(file_name + ".png")
	root.get_texture().get_image().save_png(path)
	print("captura: ", path)
	motor.position = before
	await physics_frame
