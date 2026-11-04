extends SceneTree
## Entrada pelo arquivo, leitura, ruptura, rearme e persistência da partida.
const LIBRARY := "res://scenes/rooms/biblioteca_3d.tscn"
const BOILERS := "res://scenes/rooms/caldeiras_3d.tscn"
const STAGE := "caldeiras.pressao.etapa"

class TestInput extends CharacterInput:
	var press := false
	var move := Vector2.ZERO
	func get_move() -> Vector2:
		return move
	func is_interact_just_pressed() -> bool:
		var pressed := press
		press = false
		return pressed

var controls := TestInput.new()

func _initialize() -> void:
	_run.call_deferred()
	create_timer(110).timeout.connect(func() -> void:
		push_error("O percurso nas caldeiras excedeu o tempo de teste.")
		quit(1))

func _run() -> void:
	var state := root.get_node("WorldState")
	var eras := root.get_node("EraManager")
	change_scene_to_file(LIBRARY)
	await scene_changed
	var door := "World1923/ParaCaldeiras"
	var helena = current_scene.get_node("Helena")
	assert(not current_scene.get_node(door).can_interact(helena))
	state.set_flag("biblioteca.arquivo.aberto")
	await _use("Helena", door, Vector3(6.95,0,-1.55))
	await _settle()
	assert(current_scene.scene_file_path == BOILERS)
	assert(current_scene.get_node("Helena").position.distance_to(Vector3(6,0,10.65)) < 0.05)
	await _dial(0)
	assert(not state.to_dict().has("caldeiras.tiragem.admissao"),"Sem pressão os setores permanecem presos")
	await _drain(0)
	assert(not state.get_flag("caldeiras.drenagem.ramais"), "Sem pressão a trava mantém os ralos fechados")
	helena = current_scene.get_node("Helena")
	helena.position = Vector3(6,0,10.65)
	helena.rotation.y = 0
	helena.input = controls
	controls.move = Vector2.UP
	for i in 240:
		await physics_frame
		if helena.position.z < 2.0:
			break
	controls.move = Vector2.ZERO
	assert(helena.position.z < 2.0, "Corredor livre da porta até o painel")
	await _use("Helena", "World1923/PlacaPartida", Vector3(4.2,0,1.8))
	assert(paused, "A placa abre ao mirar no texto")
	await _close_note()
	eras.switch_era()
	await _settle()
	assert(current_scene.scene_file_path == LIBRARY and eras.current_era == 1)
	await _use("Lia", "WorldToday/ParaCaldeiras", Vector3(6.95,0,-1.55))
	await _settle()
	assert(current_scene.scene_file_path == BOILERS)
	var before: Dictionary = state.to_dict()
	for index in 3:
		var x := 6.0 + index * 1.45
		await _use("Lia", "WorldToday/Marca%d" % index, Vector3(x+0.45,0,1.95), Vector3(x,1.79,0.25))
		assert(paused)
		await _close_note()
	assert(state.to_dict() == before, "Observar as marcas não altera o passado")
	eras.switch_era()
	await _settle()
	await _valve(0)
	assert(state.get_flag(STAGE) == -1)
	await _valve(2)
	assert(state.get_flag(STAGE) == -1, "Ruptura exige isolar a alimentação")
	eras.switch_era()
	await _settle()
	assert(is_equal_approx(current_scene.get_node("WorldToday/AguaDaBacia").position.y, -0.08))
	eras.switch_era()
	await _settle()
	# A ponta da alavanca erguida fica fora da antiga área fixa ao redor do eixo.
	var grip: Vector3 = current_scene._feed_handles[0].to_global(Vector3(0.375,0,0))
	await _use("Helena", "World1923/RegistroGeral", Vector3(11.2,0,2), grip)
	assert(state.get_flag(STAGE) == 0)
	await _valve(2)
	assert(state.get_flag(STAGE) == 1)
	var save: Dictionary = JSON.parse_string(JSON.stringify(state.to_dict()))
	state.clear()
	state.load_dict(save)
	reload_current_scene()
	await scene_changed
	assert(is_equal_approx(current_scene._wheels[2].rotation_degrees.z,-85))
	await _valve(0)
	await _valve(1)
	assert(state.get_flag(STAGE) == 3)
	await _valve(2)
	assert(state.get_flag(STAGE) == 3, "Em regime, os volantes ficam travados")
	eras.switch_era()
	await _settle()
	for needle in current_scene._needles:
		assert(is_equal_approx(needle.rotation_degrees.z,-60), "Ponteiro em regime alinhado à graduação")
	assert(is_equal_approx(current_scene.get_node("WorldToday/AguaDaBacia").position.y, -1.34))
	# A lateral alta do casco recua em direção ao topo, inclusive na colisão.
	for z: float in [2.5, 7.7]:
		var query := PhysicsRayQueryParameters3D.create(Vector3(3.6,2.42,z), Vector3(2.15,2.42,z), 1)
		var hit: Dictionary = current_scene.get_world_3d().direct_space_state.intersect_ray(query)
		var expected_x := 2.15 + sqrt(1.08*1.08 - pow(2.42-1.47,2))
		assert(not hit.is_empty() and absf(hit.position.x-expected_x)<0.035, "A colisão precisa acompanhar o casco")
	await _test_drainage()
	await _use("Lia", "WorldToday/ParaArquivo", Vector3(6,0,10.6))
	await _settle()
	assert(current_scene.scene_file_path == LIBRARY)
	assert(current_scene.get_node("Lia").position.distance_to(Vector3(6.95,0,-1.55)) < 0.05)
	eras.switch_era()
	await _settle()
	assert(current_scene.scene_file_path == BOILERS and state.get_flag(STAGE) == 3)
	assert(is_equal_approx(current_scene.get_node("WorldToday/AguaDaBacia").position.y, -1.34))
	assert(state.is_set("caldeiras.concluida"), "Conclusão mantida na volta do arquivo")
	print("PASS: pressão, drenagem, engrenagens, tiragem, caixa de limpeza, registro de Tomás, recarga e retorno individual")
	quit()

func _test_drainage() -> void:
	var state := root.get_node("WorldState")
	var eras := root.get_node("EraManager")
	var lia = current_scene.get_node("Lia")
	var page = current_scene.get_node("WorldToday/TiragemF2/BilheteTomas")
	assert(not page.can_interact(lia))
	await _use("Lia","WorldToday/TiragemF2/TampaLimpeza/Puxador",Vector3(4.95,0,9.03))
	assert(not state.is_set("caldeiras.limpeza.aberta"), "A inspeção fechada retém o ferrolho")
	var before: Dictionary = state.to_dict()
	for i in 3:
		await _use("Lia","WorldToday/Galeria/Saida%d" % i,Vector3(15.90+1.45*i,0,6.55))
		assert(paused)
		await _close_note()
	assert(state.to_dict() == before, "Observar a descarga não manobra os ralos")
	# Caminha pela abertura da parede. A grade precisa barrar o caminho real.
	lia.position = Vector3(14.15,0,6.8)
	await _walk_to_x(lia,22)
	assert(lia.position.x > 19.5 and lia.position.x < 20.05, "Lia alcança a galeria, mas a água mantém a grade fechada")
	eras.switch_era()
	await _settle()
	await _dial(1)
	assert(not state.to_dict().has("caldeiras.tiragem.chamine"), "Drenagem incompleta mantém a trava")
	await _drain(0)
	assert(state.get_flag("caldeiras.drenagem.ramais") == 1)
	eras.switch_era()
	await _settle()
	assert(is_equal_approx(current_scene.get_node("WorldToday/Galeria/AguaDoCanal").position.y,-0.78))
	eras.switch_era()
	await _settle()
	await _drain(1)
	await _drain(2)
	assert(state.get_flag("caldeiras.drenagem.ramais") == 7, "Abrir todos mantém o retorno rompido ligado")
	# Uma partida antiga sem flags de drenagem e uma tentativa incompleta são válidas.
	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.to_dict()))
	state.load_dict(saved)
	reload_current_scene()
	await scene_changed
	assert(is_equal_approx(current_scene.get_node("WorldToday/Galeria/AguaDoCanal").position.y,-0.06))
	assert(is_zero_approx(current_scene.get_node("WorldToday/Galeria/GradeDaBoia").position.y))
	await _drain(1)
	await _drain(0)
	assert(state.get_flag("caldeiras.drenagem.ramais") == 5, "A cunha mantém a travessia livre")
	eras.switch_era()
	await _settle()
	lia = current_scene.get_node("Lia")
	lia.position = Vector3(14.15,0,6.8)
	await _walk_to_x(lia,24.3)
	assert(lia.position.x > 24 and lia.position.y < -1.54, "Lia desce pela rampa e pisa no fundo drenado")
	await _walk_to_x(lia,29.85)
	assert(lia.position.x > 29.7 and absf(lia.position.y) < 0.05, "Rampa oposta leva à oficina")
	await _use("Lia","WorldToday/Galeria/FichaDaOficina",lia.position)
	assert(paused and state.is_set("caldeiras.oficina.visitada"))
	await _close_note()
	await _test_gears()
	lia = current_scene.get_node("Lia")
	await _walk_to_x(lia,14.15)
	assert(lia.position.x < 14.3, "Volta a pé pelo mesmo caminho")
	await _walk_to_z(lia,10.0)
	await _walk_to_x(lia,4.35)
	await _walk_to_z(lia,8.15)
	# Importa alcançar a inspeção a partir da caminhada, mesmo com a inércia na curva.
	await _use("Lia","WorldToday/InspecaoF2",lia.position)
	assert(paused)
	await _close_note()
	await _test_draft()

func _dial(i: int) -> void:
	await _use("Helena","World1923/TiragemF2/Regular%d" % i,Vector3(4.90,0,7.27-0.82*i))

func _test_draft() -> void:
	var state := root.get_node("WorldState")
	var eras := root.get_node("EraManager")
	var pull := "WorldToday/TiragemF2/TampaLimpeza/Puxador"
	var page := "WorldToday/TiragemF2/BilheteTomas"
	var spot := Vector3(4.95,0,9.03)
	# O save anterior à tiragem traz a inspeção aberta, sem posições gravadas.
	assert(not state.to_dict().has("caldeiras.tiragem.admissao"))
	await _use("Lia",pull,spot)
	assert(not state.is_set("caldeiras.limpeza.aberta"))
	eras.switch_era()
	await _settle()
	await _dial(0)
	await _dial(0)
	await _dial(1)
	await _dial(1)
	eras.switch_era()
	await _settle()
	await _use("Lia",pull,spot)
	assert(not state.is_set("caldeiras.limpeza.aberta"), "Mesma posição nos dois setores não alinha os pinos")
	eras.switch_era()
	await _settle()
	for i in 3:
		await _dial(1)
	assert(state.get_flag("caldeiras.tiragem.admissao")==2 and state.get_flag("caldeiras.tiragem.chamine")==1)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.to_dict()))
	state.load_dict(saved)
	reload_current_scene()
	await scene_changed
	eras.set_era(1)
	await _use("Lia",pull,spot)
	await _settle()
	assert(state.is_set("caldeiras.limpeza.aberta") and not state.is_set("caldeiras.concluida"))
	var past_lid: Node3D = current_scene.get_node("World1923/TiragemF2/TampaLimpeza")
	var lid: Node3D = current_scene.get_node("WorldToday/TiragemF2/TampaLimpeza")
	assert(lid.position.y-past_lid.position.y > 0.64, "Lia abre somente a tampa do presente")
	var aim: Vector3 = current_scene.get_node(page).global_position
	var ray := PhysicsRayQueryParameters3D.create(Vector3(spot.x,1.60,spot.z),aim,1)
	assert(current_scene.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(),"O interior está fisicamente exposto")
	await _use("Lia",page,spot)
	assert(paused and state.is_set("caldeiras.concluida"),"A última anotação encerra o capítulo")
	await _close_note()
	reload_current_scene()
	await scene_changed
	await _use("Lia",page,spot)
	assert(paused,"O bilhete continua legível após recarregar")
	await _close_note()

func _test_gears() -> void:
	var state := root.get_node("WorldState")
	var eras := root.get_node("EraManager")
	var past := "World1923/Galeria/Transmissao/"
	var today := "WorldToday/Galeria/Transmissao/"
	var bench := Vector3(29.95,0,7.32)
	var helena = current_scene.get_node("Helena")
	var lia = current_scene.get_node("Lia")
	assert(not current_scene.get_node(today+"Reserva0").can_interact(lia))
	await _use("Lia",today+"Manivela",bench)
	assert(not state.is_set("caldeiras.f2.inspecao.aberta"))
	eras.switch_era()
	await _settle()
	for i in 2:
		var spot := Vector3(29.19+i*0.88,0,5.95)
		await _use("Helena",past+"Peca%d" % i,spot)
		assert(helena.get_held_item() == ["pinhao_f2","coroa_f2"][i])
		await _use("Helena",past+"Suporte%d" % i,spot)
		assert(helena.get_held_item().is_empty())
	eras.switch_era()
	await _settle()
	for i in 2:
		await _use("Lia",today+"Reserva%d" % i,Vector3(29.19+i*0.88,0,5.95))
		if i == 0:
			await _use("Lia",today+"Eixo1",bench)
			assert(lia.get_held_item()=="pinhao_f2","O eixo errado não consome a peça")
			var saved: Dictionary = JSON.parse_string(JSON.stringify(state.to_dict()))
			state.load_dict(saved)
			reload_current_scene()
			await scene_changed
			lia = current_scene.get_node("Lia")
			assert(lia.get_held_item()=="pinhao_f2" and not current_scene.get_node(today+"Reserva0").can_interact(lia))
		await _use("Lia",today+"Eixo%d" % i,bench)
		assert(lia.get_held_item().is_empty())
	await _use("Lia",today+"Manivela",bench)
	await _settle()
	assert(state.is_set("caldeiras.f2.inspecao.aberta"))
	assert(current_scene.get_node(today.trim_suffix("/"))._shutter.position.y > 2.10)
	assert(is_equal_approx(current_scene.get_node(past.trim_suffix("/"))._shutter.position.y,1.52))

func _walk_to_z(motor, target_z: float) -> void:
	var sign_z := signf(target_z-motor.position.z)
	motor.input = controls
	motor.rotation.y = PI if sign_z > 0 else 0.0
	controls.move = Vector2.UP
	for i in 180:
		await physics_frame
		if (target_z-motor.position.z)*sign_z <= 0:
			break
	controls.move = Vector2.ZERO

func _drain(index: int) -> void:
	await _use("Helena","World1923/Galeria/Ralo%d" % index,Vector3(15.90+1.45*index,0,6.55))

func _walk_to_x(motor, target_x: float) -> void:
	var sign_x := signf(target_x - motor.position.x)
	motor.input = controls
	motor.rotation.y = -sign_x * PI/2
	controls.move = Vector2.UP
	for i in 350:
		await physics_frame
		if (target_x-motor.position.x)*sign_x <= 0:
			break
	controls.move = Vector2.ZERO

func _valve(index: int) -> void:
	await _use("Helena", "World1923/Valvula%d" % index, Vector3(6+index*1.45,0,2))

func _close_note() -> void:
	for child in root.get_children():
		if child is CanvasLayer and child.has_method("close"):
			child.close()
	for i in 8:
		await process_frame

func _use(character: String, path: String, at: Vector3, aim_at: Vector3 = Vector3.INF) -> void:
	var motor = current_scene.get_node(character)
	var target = current_scene.get_node(path)
	motor.input = controls
	motor.position = at
	motor.velocity = Vector3.ZERO
	var point: Vector3 = target.global_position if aim_at == Vector3.INF else aim_at
	var delta: Vector3 = point - motor.get_camera().global_position
	motor.rotation.y = atan2(-delta.x,-delta.z)
	motor.get_node("Head").rotation.x = atan2(delta.y,Vector2(delta.x,delta.z).length())
	for i in 4:
		await physics_frame
	assert(motor.focused == target, "Alvo inacessível: " + path)
	controls.press = true
	for i in 3:
		await physics_frame

func _settle() -> void:
	for i in 55:
		await process_frame
