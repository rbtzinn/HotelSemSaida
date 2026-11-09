extends SceneTree
## Teste manual contra os servidores da Epic de verdade (precisa do plugin, das chaves e de internet).
##   --script res://tools/test_epic_sala.gd -- criar          abre uma sala e espera alguém entrar
##   --script res://tools/test_epic_sala.gd -- entrar CODIGO  entra na sala de outro processo/PC
## Sem argumentos imprime SKIP (os testes automáticos não falam com a Epic).
const WAIT_MS := 180000

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		print("SKIP: test_epic_sala precisa de -- criar | entrar CODIGO")
		quit()
		return
	var net: Node = root.get_node("NetSession")
	var missing: String = net.EPIC.missing()
	if missing != "":
		printerr("FAIL: ", missing)
		quit(1)
		return
	root.get_node("Settings").data.player_name = "Ana" if args[0] == "criar" else "Bia"
	var started := Time.get_ticks_msec()
	if args[0] == "criar":
		net.host_room(Era.Id.PAST_1923)
		while net.phase == net.Phase.OPENING:
			await process_frame
		if net.phase != net.Phase.HOSTING:
			printerr("FAIL: sala não abriu · ", net.status)
			quit(1)
			return
		print("SALA ABERTA em %d ms · código %s" % [Time.get_ticks_msec() - started, net.room_code])
		while net.phase == net.Phase.HOSTING and Time.get_ticks_msec() - started < WAIT_MS:
			await process_frame
		if net.phase != net.Phase.WAITING:
			printerr("FAIL: ninguém entrou · ", net.phase, " · ", net.status)
			await net.rooms.close_room()
			quit(1)
			return
		print("PASS: %s entrou na sala" % net.partner_name)
	else:
		net.join_room(args[1])
		while net.phase in [net.Phase.OPENING, net.Phase.JOINING] and Time.get_ticks_msec() - started < WAIT_MS:
			await process_frame
		if net.phase != net.Phase.WAITING:
			printerr("FAIL: não entrou · ", net.phase, " · ", net.status)
			quit(1)
			return
		print("PASS: entrou na sala de %s" % net.partner_name)
	# Dá tempo de o outro lado ver a entrada antes de fechar
	var until := Time.get_ticks_msec() + 3000
	while Time.get_ticks_msec() < until:
		await process_frame
	await net.rooms.close_room()
	quit()
