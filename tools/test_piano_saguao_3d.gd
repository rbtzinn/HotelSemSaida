extends SceneTree
## Piano do Saguão: em 1923 Helena toca 3 · 1 · 5 · 6 a partir do dó de latão (errar não faz
## nada) e o painel atrás do piano abre; hoje, o painel está aberto para Lia e a lona do piano
## mostra a plaquinha de latão.
## Rodar: Godot_console.exe --headless --path . --fixed-fps 60 --script res://tools/test_piano_saguao_3d.gd

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
const PIANO_UI := "res://scripts/ui/piano_ui.gd"
const FLAG := "saguao.piano.valsa"

var state: Node
var eras: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("WorldState")
	eras = root.get_node("EraManager")
	state.clear()
	root.get_node("RoomManager").clear_away()
	var script: Script = load(PIANO_UI)
	assert(script._number_for(KEY_3) == 3 and script._number_for(KEY_KP_8) == 8 and script._number_for(KEY_9) == 0, "Teclas 1 a 8")
	await _reload(LOBBY, 0)
	assert(is_equal_approx(current_scene.get_node("World1923/Painel").rotation_degrees.y, 0.0), "Painel começa fechado")
	assert(not current_scene.get_node("World1923/VaoTorre").visible)
	await _use("Helena", "World1923/TocarPiano", Vector3(14.4, 0, 7.2))
	var ui = _piano()
	assert(ui != null and paused, "O piano abre em close")
	# Sequências erradas não fazem nada
	for note: int in [1, 3, 5, 6, 3, 1, 5, 5, 8]:
		ui.play(note)
	assert(not state.is_set(FLAG), "Sequência errada não abre")
	# A certa, mesmo depois de notas soltas, abre
	for note: int in [3, 1, 5, 6]:
		ui.play(note)
	assert(state.is_set(FLAG), "3 · 1 · 5 · 6 solta o painel")
	for i in 90:
		await process_frame
	assert(_piano() == null and not paused, "O piano fecha sozinho depois da valsa")
	assert(current_scene.get_node("World1923/Painel").rotation_degrees.y < -80.0)
	assert(current_scene.get_node("World1923/VaoTorre").visible)
	# A folha aberta é sólida: o que se vê é o que colide
	var helena = current_scene.get_node("Helena")
	var stop: Vector3 = await _walk(helena, Vector3(19.0, 0, 5.6), Vector2.DOWN, 90)
	assert(stop.z < 6.6, "A folha aberta do painel bloqueia: %s" % stop)
	await _use("Helena", "World1923/Painel1923", Vector3(18.6, 0, 7.1))

	# Hoje: a lona e o painel aberto
	await _reload(LOBBY, 1)
	assert(current_scene.get_node("WorldToday/Painel").rotation_degrees.y < -80.0, "Hoje o painel ficou aberto")
	await _use("Lia", "WorldToday/LonaPiano", Vector3(14.4, 0, 7.2))
	await _use("Lia", "WorldToday/PainelHoje", Vector3(18.6, 0, 7.1))
	print("PASS: Piano do Saguão: teclado em close, erro sem efeito, valsa abre o painel nas duas épocas, folha sólida")
	quit()


func _piano() -> Node:
	for child in root.get_children():
		if child.get_script() and child.get_script().resource_path == PIANO_UI:
			return child
	return null


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
