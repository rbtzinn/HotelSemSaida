class_name Door3D
extends Interactable3D
## Porta para outra sala. Só quem passou por ela vai; a outra fica onde estava.

@export_file("*.tscn") var target_scene: String = ""
## Nome do Marker3D de entrada na sala de destino.
@export var target_spawn: String = ""


func interact(by: FirstPersonMotor) -> void:
	# Ignora a porta no meio de um fade (de época ou de sala)
	if EraManager.is_switching() or RoomManager.is_changing():
		return
	super(by)


func _default_sound() -> String:
	return "porta_abre"


func _on_interact(by: FirstPersonMotor) -> void:
	RoomManager.change_room_alone(target_scene, target_spawn, by.era)
