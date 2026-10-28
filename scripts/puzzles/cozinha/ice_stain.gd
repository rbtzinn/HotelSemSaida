class_name IceStain
extends EraLinkedObject
## Hoje: mancha de água no piso da despensa, onde Helena deixou o último bloco de gelo.

func _apply() -> void:
	super()
	position.x = float(WorldState.get_flag(IceDropZone.X_FLAG, 0))
