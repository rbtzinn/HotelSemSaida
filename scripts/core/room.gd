class_name Room
extends Node2D
## Raiz de cada sala. Declara como a câmera vê a sala e repassa o modo às personagens.

enum CameraMode { SIDE_SCROLLER, TOP_DOWN }

@export var camera_mode: CameraMode = CameraMode.SIDE_SCROLLER


func _ready() -> void:
	# Os filhos já estão prontos aqui, então as personagens recebem o modo certo
	for node in find_children("*", "", true, false):
		if node is PlayerMotor:
			node.mode = camera_mode
