class_name IceStain3D
extends EraLinked3D
## Hoje: mancha de água no piso da despensa, onde Helena deixou o último bloco de gelo.

func _apply() -> void:
	super()
	var spot := IceDrop3D.placed_position()
	position.x = spot.x
	position.z = spot.y
