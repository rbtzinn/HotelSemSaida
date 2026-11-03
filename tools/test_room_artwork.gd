extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var state = root.get_node("WorldState")
	var eras = root.get_node("EraManager")
	state.load_dict({})
	eras.set_era(0)
	var room = load("res://scenes/rooms/cozinha.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	await physics_frame
	await physics_frame
	for name in ["World1923","WorldToday"]:
		var world = room.get_node(name)
		assert(world.has_node("RoomArtwork"), "Falta o PNG consolidado")
		var art = world.get_node("RoomArtwork")
		assert(art.texture.get_size()*art.scale == Vector2(640,360))
		assert(not world.get_node("Floor").visible)
		assert(world.get_node("Floor").get_child_count() > 2)
	assert(not room.get_node("World1923/Prateleiras").visible)
	assert(not room.get_node("WorldToday/PrateleiraTorta").visible)
	assert(room.get_node("World1923/PortaDespensa/Porta").visible)
	assert(room.get_node("World1923/Cardapio/Papel").size == Vector2(12,16))
	assert(room.get_node("WorldToday/CardapioDesbotado/Papel").size == Vector2(10,12))
	state.set_flag("cozinha.despensa.aberta", true)
	assert(not room.get_node("World1923/PortaDespensa/Porta").visible)
	state.set_flag("cozinha.forno.massa", true)
	state.set_flag("cozinha.elevador.travado", true)
	eras.set_era(1)
	await physics_frame
	assert(room.get_node("WorldToday/FornoPetrificado").visible)
	assert(not room.get_node("WorldToday/FornoDesmoronado").visible)
	assert(room.get_node("WorldToday/PocoAberto").visible)
	assert(not room.get_node("WorldToday/CabineEmbaixo").visible)
	assert(room.get_node("WorldToday/RoomArtwork").visible)
	print("PASS: cenarios640x360, colisao preservada, moveis sem duplicacao, papeis menores, porta/forno/elevador dinamicos")
	quit()
