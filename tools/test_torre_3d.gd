extends SceneTree
## Telhado e torre do relógio: passarelas conforme o registro da caixa d'água, ponteiros (hora
## errada não abre; 3h07 solta a caixa do pêndulo), chave da gerência, mostrador parado hoje,
## nomes riscados e volta ao Saguão.
## Rodar: Godot_console.exe --headless --path . --fixed-fps 60 --script res://tools/test_torre_3d.gd

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
const TOWER := "res://scenes/rooms/torre_3d.tscn"
const CLOCK_UI := "res://scripts/ui/clock_ui.gd"

var state: Node
var eras: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("WorldState")
	eras = root.get_node("EraManager")
	state.clear()
	state.set_flag("saguao.piano.valsa")
	root.get_node("RoomManager").clear_away()

	# Hoje, sem o registro fechado, as duas passarelas estão podres
	await _reload(TOWER, 1)
	var lia = current_scene.get_node("Lia")
	var out: Vector3 = await _walk(lia, Vector3(1.5, 0, 2.4), Vector2.DOWN, 60)
	assert(out.z > 3.2, "Lia sai da casinha da escada: %s" % out)
	for x: float in [3.0, 7.0]:
		var stop: Vector3 = await _walk(lia, Vector3(x, 0, 4.2), Vector2.DOWN, 150)
		assert(stop.z < 5.0 and stop.y > -0.5, "Passarela podre bloqueia: %s" % stop)
	await _use("Lia", "WorldToday/PassarelaOesteFrente", Vector3(3.0, 0, 4.2))

	# Helena: fecha o registro, cruza, erra a hora e depois acerta 3h07
	await _reload(TOWER, 0)
	var helena = current_scene.get_node("Helena")
	assert(current_scene.get_node("World1923/Vazamento").visible)
	await _use("Helena", "World1923/Registro", Vector3(8.0, 0, 3.4))
	assert(state.is_set("torre.registro.fechado") and not current_scene.get_node("World1923/Vazamento").visible)
	var across: Vector3 = await _walk(helena, Vector3(7.0, 0, 4.4), Vector2.DOWN, 240)
	assert(across.z > 11.2 and across.y > -0.2, "Em 1923 a passarela leste aguenta: %s" % across)
	await _use("Helena", "World1923/CaixaPendulo", Vector3(5.4, 0, 17.2))
	assert(not state.is_set("torre.pendulo.aberto"), "A caixa começa trancada")
	await _use("Helena", "World1923/MostradorAcerto", Vector3(5.0, 0, 14.2))
	var ui = _clock()
	assert(ui != null and paused and ui.minutes == 700, "O minigame abre na hora de 1923 (11h40)")
	ui.turn(5)
	ui.confirm()
	await _settle()
	assert(int(state.get_flag("torre.ponteiros")) == 705 and not state.is_set("torre.pendulo.aberto"), "Hora errada não abre")
	await _use("Helena", "World1923/MostradorAcerto", Vector3(5.0, 0, 14.2))
	ui = _clock()
	assert(ui.minutes == 705, "Os ponteiros ficaram onde Helena deixou")
	ui.turn(187 - 705)
	ui.confirm()
	await _settle()
	assert(state.is_set("torre.pendulo.aberto"), "3h07 solta a caixa do pêndulo")
	assert(current_scene.get_node("World1923/PortaPendulo").rotation_degrees.y > 80)
	await _use("Helena", "World1923/CaixaPendulo", Vector3(5.4, 0, 17.2))
	assert(str(state.get_flag("helena.mao")) == "chave_gerente" and state.is_set("torre.chave.gerente"))
	# Os ponteiros podem mudar de novo depois; a caixa continua aberta
	await _use("Helena", "World1923/MostradorAcerto", Vector3(5.0, 0, 14.2))
	_clock().turn(60)
	_clock().confirm()
	await _settle()
	assert(int(state.get_flag("torre.ponteiros")) == 247 and state.is_set("torre.pendulo.aberto"))

	# Hoje: lado oeste firme, leste caído; mostrador parado na hora de Helena
	await _reload(TOWER, 1)
	lia = current_scene.get_node("Lia")
	var fallen: Vector3 = await _walk(lia, Vector3(7.0, 0, 4.2), Vector2.DOWN, 150)
	assert(fallen.z < 5.0 and fallen.y > -0.5, "A passarela leste caída bloqueia: %s" % fallen)
	var dry: Vector3 = await _walk(lia, Vector3(3.0, 0, 4.2), Vector2.DOWN, 240)
	assert(dry.z > 11.2 and dry.y > -0.2, "Lia cruza pelo lado seco: %s" % dry)
	await _use("Lia", "WorldToday/MostradorAcerto", Vector3(5.0, 0, 14.2))
	assert(load(CLOCK_UI).describe(247) == "4h07")
	var minutes: Node3D = current_scene.get_node("WorldToday").get_children().filter(func(n): return n.has_node("Minutos"))[0].get_node("Minutos")
	assert(is_equal_approx(minutes.rotation.z, TAU * 7 / 60.0), "Hoje os ponteiros estão onde Helena deixou")
	await _use("Lia", "WorldToday/CaixaPendulo", Vector3(5.4, 0, 17.2))
	assert(state.is_set("torre.concluida") and paused, "Lia lê os nomes riscados")
	await _close_note()
	# Volta ao Saguão pela escada em caracol
	await _use("Lia", "WorldToday/DescerEscada", Vector3(1.5, 0, 2.5))
	await _wait_room(LOBBY)
	assert(current_scene.get_node("Lia").position.distance_to(Vector3(18.7, 0, 7.1)) < 0.2, "Lia chega na frente do painel")
	print("PASS: Torre: passarelas e registro, ponteiros (errado, 3h07, de novo), chave da gerência, mostrador de hoje, nomes riscados e volta ao Saguão")
	quit()


func _clock() -> Node:
	for child in root.get_children():
		if child.get_script() and child.get_script().resource_path == CLOCK_UI:
			return child
	return null


func _settle() -> void:
	for i in 10:
		await process_frame


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
