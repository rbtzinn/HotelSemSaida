class_name ChapterEnd3D
extends Interactable3D
## A troca de sala acontece depois que a viajante alcança o patamar.

@export var flag_key: String = ""
@export_file("*.tscn") var target_scene: String = ""
@export var target_spawn: String = ""
@export_multiline var message: String = ""
@export var descent: PackedVector3Array
var _traveler: FirstPersonMotor

## Som ao usar (ver Interactable3D.sound).
func _default_sound() -> String:
	return ""


func _ready() -> void:
	super()
	set_physics_process(false)


func _on_interact(by: FirstPersonMotor) -> void:
	if _traveler or RoomManager.is_changing() or EraManager.is_switching():
		return
	_traveler = by
	var points := PackedVector3Array()
	for point in descent:
		points.append(to_global(point))
	by.begin_traversal(points)
	set_physics_process(true)

func _physics_process(_delta: float) -> void:
	if _traveler.is_traversing() or RoomManager.is_changing() or EraManager.is_switching():
		return
	set_physics_process(false)
	WorldState.set_flag(flag_key)
	say(message)
	RoomManager.change_room_alone(target_scene, target_spawn, _traveler.era)
	_traveler = null
