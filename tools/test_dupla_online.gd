extends SceneTree
## Rode em dois processos com diretórios de dados temporários separados.
## --script res://tools/test_dupla_online.gd -- host|guest PORTA [retomar]
const KITCHEN := "res://scenes/rooms/cozinha_3d.tscn"
var net: Node
var state: Node
var eras: Node
var host: bool

func _initialize() -> void:
	_run.call_deferred()

func _wait_for(check: Callable, description: String) -> void:
	var until := Time.get_ticks_msec()+16000
	while not check.call():
		if Time.get_ticks_msec() > until:
			printerr("FAIL: ",description," · ",net.phase," · ",net.status)
			quit(1)
			await process_frame
			return
		await process_frame

func _in_room(path: String) -> bool:
	return current_scene != null and current_scene.scene_file_path == path and not root.get_node("RoomManager").is_changing()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	host = args[0] == "host"
	var port := args[1].to_int()
	var resume := "retomar" in args
	net = root.get_node("NetSession")
	state = root.get_node("WorldState")
	eras = root.get_node("EraManager")
	change_scene_to_file(net.LOBBY)
	await scene_changed
	if host:
		net.host(0 if resume else 1,port)
		await _wait_for(func() -> bool: return net.phase == net.Phase.WAITING,"segundo jogador no lobby")
		net.start(resume)
	else:
		net.join("127.0.0.1:%d" % port)
	var my_era: int = (0 if host else 1) if resume else (1 if host else 0)
	var first_room: String = KITCHEN if resume and my_era == 1 else net.HOTEL
	await _wait_for(_in_room.bind(first_room),"cena inicial da minha época")
	assert(eras.current_era == my_era)
	eras.switch_era()
	assert(not eras.is_switching())
	var actor = current_scene.get_node(Era.character_name(my_era))
	assert(actor.get_camera().current)
	if resume:
		assert(state.is_set("cozinha.forno.massa") and state.is_set("saguao.elevador.no_alto"))
		assert(actor.get_held_item() == ("chave_biblioteca" if my_era == 1 else ""))
		assert(actor.position.distance_to(Vector3(5,4.5,4) if my_era == 1 else Vector3(7,0,6)) < 0.1)
		if not host:
			# Conclui a verificação no visitante antes de o anfitrião sair.
			state.set_flag("saguao.bolsa.marta")
		else:
			await _wait_for(func() -> bool: return state.is_set("saguao.bolsa.marta"),"dupla restaurada")
	elif host:
		current_scene.get_node("WorldToday/PortaCozinha").interact(actor)
		await _wait_for(_in_room.bind(KITCHEN),"Lia entrou sozinha")
		actor = current_scene.get_node("Lia")
		actor.position = Vector3(5,4.5,4)
		actor.set_held_item("chave_biblioteca")
		var note = load("res://scripts/ui/note_ui.gd").open(self,"Teste","Leitura local")
		await _wait_for(func() -> bool: return state.is_set("saguao.elevador.no_alto"),"receber enigmas durante a leitura")
		assert(paused and current_scene.get_node("WorldToday/FornoPetrificado").is_visible_in_tree())
		assert(not current_scene.get_node("WorldToday/FornoDesabado").is_visible_in_tree())
		note.close()
		await _wait_for(func() -> bool: return not paused,"fechar leitura")
		net.save_duo()
		await _wait_for(func() -> bool: return FileAccess.file_exists(net.SAVE),"save das duas salas")
	else:
		await _wait_for(func() -> bool: return state.get_flag("lia.mao","") == "chave_biblioteca","Lia na Cozinha")
		assert(_in_room(net.HOTEL))
		current_scene.get_node("World1923/PortaCozinha").interact(actor)
		await _wait_for(_in_room.bind(KITCHEN),"Helena entrou separadamente")
		actor = current_scene.get_node("Helena")
		actor.set_held_item("fermento")
		current_scene.get_node("World1923/Forno").interact(actor)
		await root.get_node("RoomManager").change_room_alone(net.HOTEL,"DaCozinha",0)
		actor = current_scene.get_node("Helena")
		actor.position = Vector3(7,0,6)
		current_scene.get_node("World1923/Gancho9").interact(actor)
		current_scene.get_node("World1923/PainelElevador").interact(actor)
		load("res://scripts/ui/note_ui.gd").open(self,"Teste","A desconexão deve fechar esta folha.")
	if host:
		net.leave("Teste concluído.")
	await _wait_for(_in_room.bind(net.LOBBY),"voltar ao lobby após desconexão")
	assert(not paused and net.phase == net.Phase.OFF)
	assert(not FileAccess.file_exists("user://save.json"))
	print("PASS: ",args," câmeras, salas, enigmas, save e saída da dupla")
	quit()
