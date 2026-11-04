class_name ChapterEnd3D
extends Interactable3D
## Saída de um andar: liga a flag de conclusão e, depois de um fade, leva quem saiu ao Saguão.

@export var flag_key: String = ""
@export_file("*.tscn") var target_scene: String = ""
@export var target_spawn: String = ""
@export_multiline var message: String = ""


func _on_interact(by: FirstPersonMotor) -> void:
	if RoomManager.is_changing():
		return
	WorldState.set_flag(flag_key)
	say(message)
	RoomManager.change_room_alone(target_scene, target_spawn, by.era)
