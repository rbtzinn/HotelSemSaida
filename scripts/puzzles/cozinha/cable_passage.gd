extends "res://scripts/interaction/passage.gd"
## Entrada, descida de mão em mão e aterrissagem nos cabos do elevador.

func _on_interact(by: PlayerMotor) -> void:
	if target != null and not by.is_traversing():
		by.begin_cable_descent(target.global_position, 592.0)
