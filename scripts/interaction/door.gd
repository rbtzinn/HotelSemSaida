class_name Door
extends Interactable
## Porta para outra sala. Leva Helena e Lia juntas ao ponto de entrada indicado.

@export_file("*.tscn") var target_scene: String = ""
## Nome do Marker2D de entrada na sala de destino.
@export var target_spawn: String = ""


func interact(by: PlayerMotor) -> void:
	# Ignora a porta no meio de um fade (de época ou de sala)
	if EraManager.is_switching() or RoomManager.is_changing():
		return
	super(by)


func _on_interact(_by: PlayerMotor) -> void:
	RoomManager.change_room(target_scene, target_spawn)
