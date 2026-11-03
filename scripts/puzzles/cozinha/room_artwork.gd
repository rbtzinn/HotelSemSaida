extends Node
## Cenário consolidado. A física e os objetos mutáveis continuam na cena original.

const ART := "res://art/environment/"

func _ready() -> void:
	_install("World1923", "kitchen_1923.png", ["Escada", "Prateleiras", "GeladeiraMovel", "Forno/Corpo"], false)
	_install("WorldToday", "kitchen_present.png", ["EscombrosPorta", "EscadaDesabada", "PrateleiraQuebrada", "PrateleiraTorta", "GeladeiraEnferrujada"], true)
	var stairwell = get_parent().get_node("World1923/Stairwell")
	stairwell.baked_background = get_parent().get_node("World1923").has_node("RoomArtwork")
	stairwell.queue_redraw()


func _install(world_name: String, file: String, fixed_visuals: Array, painted: bool) -> void:
	if not ResourceLoader.exists(ART + file):
		return
	var world := get_parent().get_node(world_name)
	var artwork := Sprite2D.new()
	artwork.name = "RoomArtwork"
	artwork.texture = load(ART + file)
	artwork.centered = false
	artwork.scale = Vector2(640.0 / artwork.texture.get_width(), 360.0 / artwork.texture.get_height())
	artwork.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if painted else CanvasItem.TEXTURE_FILTER_NEAREST
	world.add_child(artwork)
	world.move_child(artwork,0)
	# Apenas a visibilidade muda: os corpos estáticos continuam sólidos.
	for child in world.get_children():
		if child.has_meta("generated") and child is CanvasItem:
			child.hide()
	for path in fixed_visuals:
		world.get_node(path).hide()
