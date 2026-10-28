class_name Passage
extends Interactable
## Passagem dentro da mesma sala (escada, cabos, buraco): leva só a personagem
## que interagiu até o ponto `target`. A outra continua onde foi deixada.

@export var target: Node2D


func _on_interact(by: PlayerMotor) -> void:
	by.global_position = target.global_position
	by.velocity = Vector2.ZERO
