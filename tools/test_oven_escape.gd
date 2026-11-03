extends SceneTree

class TestInput extends CharacterInput:
	var direction := Vector2.ZERO
	var jump_requested := false
	func get_move() -> Vector2:
		return direction
	func is_jump_just_pressed() -> bool:
		var pressed := jump_requested
		jump_requested = false
		return pressed

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.get_node("WorldState").set_flag("cozinha.forno.massa",true)
	root.get_node("EraManager").set_era(1)
	var room = load("res://scenes/rooms/cozinha.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	var lia = room.get_node("Lia")
	await physics_frame
	var controls := TestInput.new()
	lia.input = controls
	# Posições reais dentro do bolso entre forno e parede.
	for start_x in [541.0,552.0,563.0]:
		lia.position = Vector2(start_x,200)
		lia.velocity = Vector2.ZERO
		controls.direction = Vector2.ZERO
		for tick in 6:
			await physics_frame
		controls.direction = Vector2.LEFT
		controls.jump_requested = true
		var highest := 200.0
		for tick in 90:
			await physics_frame
			highest = minf(highest,lia.position.y)
		var escaped: bool = lia.position.x < 468.0
		print("pocket x=", start_x," escaped=",escaped," highest=",highest)
		if "--expect-trapped" in OS.get_cmdline_user_args():
			assert(not escaped)
		else:
			assert(escaped,"Lia precisa sair pelo forno ao pular para a esquerda")
	if "--expect-trapped" in OS.get_cmdline_user_args():
		print("REPRODUZIDO: teto da prateleira prende Lia nas tres posicoes")
		quit()
		return
	# O primeiro pulo não pode ignorar o enigma e alcançar a prateleira direto.
	lia.position = Vector2(552,200)
	lia.velocity = Vector2.ZERO
	controls.direction = Vector2.ZERO
	for tick in 6:
		await physics_frame
	controls.jump_requested = true
	for tick in 90:
		await physics_frame
	assert(absf(lia.position.y-200.0)<1.0)
	# Do forno, o segundo pulo deve pousar na prateleira e dar acesso à portinhola.
	lia.position = Vector2(516,168)
	lia.velocity = Vector2.ZERO
	for tick in 6:
		await physics_frame
	controls.direction = Vector2.RIGHT
	controls.jump_requested = true
	for tick in 20:
		await physics_frame
	controls.direction = Vector2.ZERO
	for tick in 60:
		await physics_frame
	assert(absf(lia.position.y-136.0)<1.0,"Deve pousar no topo da prateleira")
	assert(room.get_node("WorldToday/CabineEmbaixo/Olhar").has_body(lia))
	print("PASS: fuga3posicoes, forno solido, sem atalho pelo chao, salto forno/prateleira/portinhola")
	quit()
