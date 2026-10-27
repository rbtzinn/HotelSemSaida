class_name CharacterInput
extends RefCounted
## Comandos que uma personagem recebe. Esta base é o "input vazio":
## não pede nada, então a personagem fica parada.

func get_move() -> Vector2:
	return Vector2.ZERO


func is_jump_just_pressed() -> bool:
	return false


func is_interact_just_pressed() -> bool:
	return false
