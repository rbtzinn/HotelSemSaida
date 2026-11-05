extends SceneTree
## Percurso jogável: chave só hoje, quatro enigmas e preservação ao recarregar.
class TestInput extends CharacterInput:
	var direction := Vector2.ZERO
	var interact := false
	func get_move() -> Vector2:
		return direction
	func is_interact_just_pressed() -> bool:
		var pressed := interact
		interact = false
		return pressed

var state: Node
var eras: Node
var controls := TestInput.new()

func _initialize() -> void:
	_run.call_deferred()
	var watchdog := create_timer(40)
	watchdog.timeout.connect(func() -> void:
		push_error("Teste da Biblioteca excedeu 40 segundos")
		quit(1))

func _run() -> void:
	state = root.get_node("WorldState")
	eras = root.get_node("EraManager")
	state.clear()
	state.set_flag("cozinha.concluida")
	eras.set_era(1)
	change_scene_to_file("res://scenes/rooms/manutencao_3d.tscn")
	await scene_changed
	var lia = current_scene.get_node("Lia")
	lia.input = controls
	lia.position = Vector3(1.55, 0, 6.5)
	await _aim(lia, Vector3(1.55, 3.4, 7.2))
	assert(lia.focused == current_scene.get_node("WorldToday/AlcapaoDespensa"), "Alçapão visível e alcançável olhando para cima")
	var ray := PhysicsRayQueryParameters3D.create(Vector3(1.55, 3.45, 7.4), Vector3(1.55, 4.15, 7.4), 1)
	assert(lia.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(), "Abertura no teto não pode estar tampada por colisão")
	# Corredor de serviço: da sala, pelo vão sul, e depois sob o Saguão até a escada.
	for leg: Array in [[Vector3(4.5, 1, 6.0), Vector3(4.5, 1, 11.4)], [Vector3(4.5, 1, 11.4), Vector3(25.8, 1, 11.4)]]:
		var walk := PhysicsRayQueryParameters3D.create(leg[0], leg[1], 1)
		assert(lia.get_world_3d().direct_space_state.intersect_ray(walk).is_empty(), "Corredor livre de %s a %s" % leg)
	lia.position = Vector3(25.0, 0, 11.4)
	await _aim(lia, Vector3(26.7, 1.3, 11.4))
	await _press()
	assert(current_scene.scene_file_path.ends_with("manutencao_3d.tscn"), "Sem chave, a porta atual continua trancada")
	assert(not state.is_set("biblioteca.porta.hoje"), "Tentativa não destranca a porta")
	lia.position = Vector3(6.4, 0, 2.0)
	await _aim(lia, Vector3(6.4, 1, 0.97))
	assert(lia.focused == current_scene.get_node("WorldToday/Chave"), "Chave alcançável sobre a bancada")
	await _press()
	assert(lia.get_held_item()=="chave_biblioteca", "Lia pega a chave de 1951")
	assert(not state.is_set("biblioteca.estante.ordenada"), "Pegar a chave hoje não altera mecanismo no passado")
	lia.position = Vector3(25.0, 0, 11.4)
	await _aim(lia, Vector3(26.7, 1.3, 11.4))
	assert(lia.focused == current_scene.get_node("WorldToday/ParaBiblioteca"), "Escada de serviço alcançável")
	await _press()
	await _transition()
	assert(current_scene.scene_file_path.ends_with("biblioteca_3d.tscn"), "A manutenção leva à Biblioteca")
	assert(state.is_set("biblioteca.porta.hoje"), "A chave abre só a fechadura atual")
	root.get_node("RoomManager").clear_away()
	eras.set_era(0)
	var helena = current_scene.get_node("Helena")
	helena.input = controls
	var room = current_scene
	# Duas trocas físicas de volumes: [1,2,3,4] -> [2,4,1,3].
	helena.position = Vector3(4.3, 0, 2.1)
	for slot in [0, 1, 1, 3, 2, 3]:
		await _aim(helena, Vector3(3.45+slot*0.55, 1.7, 1.1))
		assert(helena.focused == room.get_node("World1923/Volume%d" % slot), "Volume %d alcançável" % slot)
		await _press()
	assert(state.is_set("biblioteca.estante.ordenada"), "Silhuetas resolvem a ordem")
	# Livro errado: pode ser guardado, mas não vira pista; Helena o tira e devolve à mesa.
	helena.position = Vector3(4.65, 0, 7.85)
	await _aim(helena, Vector3(4.65, 1.15, 7.02))
	assert(helena.focused == room.get_node("World1923/Titulo1"), "Botânica alcançável na mesa")
	await _press()
	assert(helena.get_held_item()=="livro_botanica", "Qualquer livro pode ser levado")
	assert(not room.get_node("World1923/LivroMesa1").visible, "Saiu da mesa")
	helena.position = Vector3(3.6, 0, 10.9)
	await _aim(helena, Vector3(2.65, 1.4, 10.9))
	await _press()
	assert(int(state.get_flag("biblioteca.registro", 0))==2 and not state.is_set("biblioteca.livro.guardado"), "Livro errado no registro não conta")
	assert(not room.get_node("World1923/EstanteSecreta/FechaduraArquivo").can_interact(helena), "Fechadura segue inerte")
	await _press()
	assert(helena.get_held_item()=="livro_botanica" and int(state.get_flag("biblioteca.registro", 0))==0, "Tira o livro errado")
	helena.position = Vector3(4.65, 0, 7.85)
	await _aim(helena, Vector3(4.65, 1.15, 7.02))
	await _press()
	assert(helena.get_held_item()=="" and room.get_node("World1923/LivroMesa1").visible, "Devolve à mesa")
	# Atlas indicado pela cifra.
	helena.position = Vector3(4.05, 0, 7.85)
	await _aim(helena, Vector3(4.05, 1.15, 7.02))
	assert(helena.focused == room.get_node("World1923/Titulo0"), "Atlas alcançável na mesa")
	await _press()
	assert(helena.get_held_item()=="atlas", "O atlas indicado pode ser carregado")
	# Guarda num nicho seco. Hoje surge o registro de Caio.
	helena.position = Vector3(3.6, 0, 10.9)
	await _aim(helena, Vector3(2.65, 1.4, 10.9))
	assert(helena.focused == room.get_node("World1923/GuardarAtlas"), "Nicho alcançável")
	await _press()
	assert(state.is_set("biblioteca.livro.guardado") and helena.get_held_item()=="", "Atlas preservado")
	eras.set_era(1)
	lia = room.get_node("Lia")
	lia.input = controls
	lia.position = Vector3(3.6, 0, 10.9)
	await _aim(lia, Vector3(2.65, 1.4, 10.9))
	assert(lia.focused == room.get_node("WorldToday/RegistroPreservado"), "Lia alcança o livro preservado")
	await _press()
	assert(paused, "Leitura pausa movimento")
	var reading_spot: Vector3 = lia.position
	controls.direction = Vector2.UP
	for i in 20:
		await physics_frame
	controls.direction = Vector2.ZERO
	assert(lia.position.is_equal_approx(reading_spot), "Lia permanece parada durante leitura")
	assert(state.is_set("biblioteca.pagina.lida"), "Registro encontrado")
	await _close_ui()
	eras.set_era(0)
	helena.input = controls
	helena.position = Vector3(9, 0, 2.0)
	await _aim(helena, Vector3(9, 1.15, 0.92))
	assert(helena.focused == room.get_node("World1923/EstanteSecreta/FechaduraArquivo"), "Fechadura alcançável")
	await _press()
	var ui = _find_ui()
	assert(ui != null, "Minigame aberto")
	for i in 4:
		ui._digits[i] = 0
	ui._try_code()
	assert(not state.is_set("biblioteca.arquivo.aberto"), "Código errado não abre")
	for i in 4:
		ui._digits[i] = [7, 2, 6, 4][i]
	ui._try_code()
	await _close_ui()
	assert(state.is_set("biblioteca.arquivo.aberto"), "Resposta combina ordem dos volumes e registro")
	# Confere a passagem real, não apenas a flag: atravessa o vão com física.
	helena.position = Vector3(9, 0, 1.8)
	helena.rotation.y = 0
	helena.velocity = Vector3.ZERO
	controls.direction = Vector2.UP
	for i in 45:
		await physics_frame
	controls.direction = Vector2.ZERO
	assert(helena.position.z < 0, "Estante aberta libera o corredor com colisão")
	eras.set_era(1)
	lia.input = controls
	lia.position = Vector3(9, 0, -0.7)
	await _aim(lia, Vector3(9, 1.1, -1.25))
	assert(lia.focused == room.get_node("WorldToday/DossieCaio"), "Arquivo acessível")
	await _press()
	assert(state.is_set("biblioteca.concluida"), "Dossiê encerra o capítulo")
	await _close_ui()
	var data: Dictionary = state.to_dict()
	change_scene_to_file("res://scenes/rooms/biblioteca_3d.tscn")
	await scene_changed
	assert(current_scene.get_node("WorldToday/EstanteSecreta").position.x>11, "Arquivo continua aberto após recarregar")
	assert(state.to_dict()==data, "Progresso preservado")
	# A entrada pública no Saguão permite Helena entrar sem usar a chave de 1951.
	root.get_node("RoomManager").clear_away()
	eras.set_era(0)
	change_scene_to_file("res://scenes/rooms/saguao_3d.tscn")
	await scene_changed
	helena = current_scene.get_node("Helena")
	helena.input = controls
	helena.position = Vector3(18.7, 0, 3.4)
	await _aim(helena, Vector3(18.7, 1.2, 2.15))
	assert(helena.focused == current_scene.get_node("World1923/PortaBiblioteca"), "Entrada da Biblioteca alcançável no Saguão")
	assert(helena.get_held_item()=="", "Helena não precisa da chave futura")
	await _press()
	await _transition()
	assert(current_scene.scene_file_path.ends_with("biblioteca_3d.tscn"), "Helena entra pela porta pública de 1923")
	print("PASS: manutenção, chave só no presente, livros, cifra, atlas, arquivo, reload")
	quit()

func _aim(motor, point: Vector3) -> void:
	var delta: Vector3 = point - motor.get_camera().global_position
	motor.rotation.y = atan2(-delta.x, -delta.z)
	motor.get_node("Head").rotation.x = atan2(delta.y, Vector2(delta.x, delta.z).length())
	motor.velocity = Vector3.ZERO
	for i in 4:
		await physics_frame

func _press() -> void:
	controls.interact = true
	for i in 3:
		await physics_frame

func _transition() -> void:
	for i in 90:
		await process_frame

func _find_ui():
	for child in root.get_children():
		if child is CanvasLayer and child.has_method("close"):
			return child
	return null

func _close_ui() -> void:
	var ui = _find_ui()
	if is_instance_valid(ui):
		ui.close()
	for i in 8:
		await process_frame
