extends Node
## Preferências locais, separadas do progresso da campanha.
signal changed
const PATH := "user://settings.cfg"
const ACTIONS := ["move_left", "move_right", "move_up", "move_down", "jump", "interact", "switch_era", "pause", "quick_save", "quick_load"]
const LABELS := ["Mover à esquerda", "Mover à direita", "Mover para cima", "Mover para baixo", "Pular", "Interagir", "Trocar de época", "Pausar", "Salvar rápido", "Carregar rápido"]
var defaults: Dictionary = {}
var data: Dictionary = {}
var config_path: String = PATH

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for action in ACTIONS:
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				defaults[action] = {"kind": "key", "code": event.physical_keycode}
				break
	data = factory()
	var cfg := ConfigFile.new()
	if cfg.load(config_path) == OK:
		for key in data:
			var value: Variant = cfg.get_value("preferences", key, data[key])
			if typeof(value) == typeof(data[key]):
				data[key] = value
	apply(data)

func factory() -> Dictionary:
	return {"mode": 0, "resolution": Vector2i(1280,720), "vsync": true,
		"fps": 60, "volume": 0.8, "mute": false, "deadzone": 0.2,
		"bindings": defaults.duplicate(true)}

func apply(values: Dictionary) -> void:
	data = values.duplicate(true)
	data.mode = clampi(int(data.mode),0,2)
	var size: Vector2i = data.resolution
	size.x = clampi(size.x,640,7680)
	size.y = clampi(size.y,360,4320)
	data.resolution = size
	data.volume = clampf(float(data.volume),0,1)
	data.deadzone = clampf(float(data.deadzone),0.05,0.8)
	if DisplayServer.get_name() != "headless":
		var modes := [DisplayServer.WINDOW_MODE_WINDOWED, DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
		DisplayServer.window_set_mode(modes[data.mode])
		if data.mode == 0:
			DisplayServer.window_set_size(size)
			DisplayServer.window_set_position((DisplayServer.screen_get_usable_rect().size - size) / 2)
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if data.vsync else DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = maxi(0,int(data.fps))
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.0001,data.volume)))
	AudioServer.set_bus_mute(0,data.mute)
	for action in ACTIONS:
		for event in InputMap.action_get_events(action):
			if event is InputEventKey or event is InputEventMouseButton:
				InputMap.action_erase_event(action,event)
		var binding: Dictionary = data.bindings.get(action, defaults[action])
		var event: InputEvent
		if binding.get("kind") == "mouse":
			var mouse := InputEventMouseButton.new()
			mouse.button_index = int(binding.get("code",1))
			event = mouse
		else:
			var key := InputEventKey.new()
			key.physical_keycode = int(binding.get("code",defaults[action].code))
			event = key
		InputMap.action_add_event(action,event)
		InputMap.action_set_deadzone(action,data.deadzone)
	changed.emit()

func save() -> Error:
	var cfg := ConfigFile.new()
	for key in data:
		cfg.set_value("preferences",key,data[key])
	return cfg.save(config_path)

func binding_label(action: String, values: Dictionary = {}) -> String:
	var source: Dictionary = data if values.is_empty() else values
	var b: Dictionary = source.bindings.get(action,defaults.get(action,{}))
	if b.get("kind") == "mouse":
		return "Mouse %d" % int(b.code)
	return OS.get_keycode_string(int(b.get("code",0)))

