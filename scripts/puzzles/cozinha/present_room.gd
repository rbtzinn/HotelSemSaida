extends "res://scripts/core/placeholder_room.gd"
## Mantém a geometria compartilhada, com materiais desenhados no presente.

func _ready() -> void:
	super._ready()
	for child in get_node("Floor").get_children():
		if child is TextureRect:
			child.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			if child.position == Vector2(576,24):
				child.texture = preload("res://art/future/wall.png")
				child.stretch_mode = TextureRect.STRETCH_SCALE
