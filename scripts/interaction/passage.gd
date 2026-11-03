class_name Passage
extends Interactable
## Passagem dentro da mesma sala (escada, cabos, buraco): leva só a personagem
## que interagiu até o ponto `target`. A outra continua onde foi deixada.

@export var target: Node2D
## Pontos em coordenadas da sala; vazio mantém a passagem instantânea.
@export var route: PackedVector2Array = PackedVector2Array()


func _on_interact(by: PlayerMotor) -> void:
	if target == null or by.is_traversing():
		return
	if not route.is_empty():
		var points := route.duplicate()
		points.append(target.global_position)
		by.begin_traversal(points)
		return
	by.global_position = target.global_position
	by.velocity = Vector2.ZERO
