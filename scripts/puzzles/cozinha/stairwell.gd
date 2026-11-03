extends Node2D
## Vão da escada em corte e porta aberta após retirar o cadeado.
var baked_background: bool = false

func _ready() -> void:
	WorldState.flag_changed.connect(_on_flag_changed)
	_refresh()


func _on_flag_changed(key: String, _value: Variant) -> void:
	if key == "cozinha.despensa.aberta":
		_refresh()


func _refresh() -> void:
	get_parent().get_node("PortaDespensa/Porta").visible = not WorldState.is_set("cozinha.despensa.aberta")
	queue_redraw()


func _draw() -> void:
	# O vão atravessa a espessura do piso e termina no primeiro degrau.
	if not baked_background:
		draw_rect(Rect2(48, 200, 32, 36), Color("211318"))
		draw_rect(Rect2(48, 216, 104, 128), Color("2b171c"))
		draw_rect(Rect2(48, 200, 2, 36), Color("79552e"))
		draw_rect(Rect2(78, 200, 2, 36), Color("79552e"))
		draw_rect(Rect2(144, 341, 24, 3), Color("93672a"))
	if WorldState.is_set("cozinha.despensa.aberta"):
		draw_rect(Rect2(48, 136, 32, 64), Color("93672a"))
		draw_rect(Rect2(51, 139, 26, 61), Color("161015"))
		draw_rect(Rect2(51, 139, 5, 60), Color("51242a"))
		draw_rect(Rect2(56, 139, 1, 60), Color("c9973b"))
