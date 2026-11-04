class_name IceStain3D
extends EraLinked3D
## Hoje: mancha de água no piso da despensa, onde Helena deixou o último bloco de gelo.

func _also_refreshes(key: String) -> bool:
	return key in [IceDrop3D.ROT_FLAG, IceDrop3D.X_FLAG, IceDrop3D.Z_FLAG]

func _apply() -> void:
	super()
	if WorldState.is_set(IceDrop3D.ROT_FLAG):
		hide()
	var spot := IceDrop3D.placed_position()
	position.x = spot.x
	position.z = spot.y
