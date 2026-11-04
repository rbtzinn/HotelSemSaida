class_name Passage3D
extends Interactable3D
## Percurso guiado (descer ou subir pelos cabos): a personagem segue os marcadores
## filhos de `path_root`, em ordem, sem comandos até chegar.

@export var path_root: NodePath


func _on_interact(by: FirstPersonMotor) -> void:
	var points := PackedVector3Array()
	for marker in get_node(path_root).get_children():
		if marker is Node3D:
			points.append((marker as Node3D).global_position)
	by.begin_traversal(points)
