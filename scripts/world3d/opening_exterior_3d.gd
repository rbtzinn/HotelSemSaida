extends HotelBuilder3D
## Fachada da abertura. As duas épocas compartilham a planta e os detalhes principais.

const FRONT: float = 7.0
const WARM := Color("#F6BE78")
const COLD := Color("#849DC4")

var _lit_glass: StandardMaterial3D
var _dark_glass: StandardMaterial3D


func _build_room() -> void:
	_cast_shadows = false
	_lit_glass = StandardMaterial3D.new()
	_lit_glass.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_lit_glass.albedo_color = Color("#E7B06F")
	_dark_glass = StandardMaterial3D.new()
	_dark_glass.albedo_color = Color("#282F3B")
	_dark_glass.roughness = 0.55
	_block(Vector3(0, -0.36, 13), Vector3(114, 0.6, 102), "stone")
	_block(Vector3(0, -0.13, 10), Vector3(53, 0.3, 7.5), "stone")
	_block(Vector3(0, -0.01, 13.8), Vector3(53, 0.16, 0.25), "marble")
	for i in 3:
		_block(Vector3(0, 0.12 + i * 0.16, 9.15 - i * 0.55),
			Vector3(7.0 - i * 0.35, 0.24, 1.5), "stone")

	_block(Vector3(0, 6.3, 0), Vector3(31.6, 12.6, 14.0), "plaster_cream")
	_block(Vector3(0, 0.45, 0), Vector3(32.0, 0.9, 14.4), "stone")
	for y: float in [3.8, 7.9, 11.85, 12.65]:
		_block(Vector3(0, y, 0), Vector3(32.2, 0.18, 14.55), "marble")
	_block(Vector3(0, 12.92, 0), Vector3(31.6, 0.42, 14.0), "stone")
	_block(Vector3(0, 13.18, 0), Vector3(28.8, 0.2, 11.7), "iron")

	for side: float in [-1.0, 1.0]:
		for i in 4:
			var x := side * (4.6 + i * 2.9)
			_block(Vector3(x + side * 1.43, 6.4, FRONT), Vector3(0.34, 11.7, 0.38), "stone")
			_window(Vector3(x, 2.2, FRONT), 0.0, Vector2(1.52, 2.6), i, true)
			_window(Vector3(x, 5.9, FRONT), 0.0, Vector2(1.28, 2.25), i + 1)
			_window(Vector3(x, 9.9, FRONT), 0.0, Vector2(1.28, 2.2), i + 2)
		for i in 4:
			for y: float in [2.2, 5.9, 9.9]:
				_window(Vector3(15.8 * side, y, 4.9 - i * 3.2), 90.0 * side,
					Vector2(1.28, 2.2), i + int(y))
		_wall_lamp(Vector3(side * 3.1, 2.5, FRONT + 0.24), 0.0, 1.9, 6.0)

	_build_portal()
	_build_clock_tower()
	_build_street()


func _window(at: Vector3, yaw: float, size: Vector2, index: int, tall: bool = false) -> void:
	var frame := _group(at, yaw)
	var trim := "stone" if present else "marble"
	_child_box(frame, Vector3(0, 0, 0.045), Vector3(size.x + 0.34, size.y + 0.34, 0.18), trim)
	_child_box(frame, Vector3(0, 0, 0.145), Vector3(size.x, size.y, 0.06), "dark")
	var pane := _child_box(frame, Vector3(0, 0, 0.185), Vector3(size.x - 0.14, size.y - 0.14, 0.03), "dark")
	pane.material_override = _lit_glass if not present and index % 5 != 4 else _dark_glass
	_child_box(frame, Vector3(0, 0, 0.217), Vector3(0.055, size.y, 0.055), "iron")
	_child_box(frame, Vector3(0, size.y * 0.18, 0.217), Vector3(size.x, 0.065, 0.055), "iron")
	_child_box(frame, Vector3(0, -size.y / 2.0, 0.23), Vector3(size.x + 0.48, 0.13, 0.36), trim)
	if tall:
		_child_box(frame, Vector3(0, size.y / 2.0 + 0.2, 0.12), Vector3(size.x * 0.55, 0.32, 0.22), trim)
	if present and (tall or index % 3 == 0):
		_child_box(frame, Vector3(0, -0.2, 0.27), Vector3(size.x + 0.25, 0.23, 0.08),
			"plank", Vector3(0, 0, 12.0 if index % 2 == 0 else -17.0))


func _build_portal() -> void:
	_block(Vector3(0, 6.55, 6.9), Vector3(6.5, 13.1, 1.4), "stone")
	_block(Vector3(0, 2.0, 7.64), Vector3(3.25, 3.85, 0.16), "dark_wood")
	var glass := _block(Vector3(0, 2.44, 7.75), Vector3(2.66, 2.68, 0.09), "dark")
	glass.material_override = _dark_glass if present else _lit_glass
	for x: float in [-1.35, 0.0, 1.35]:
		_block(Vector3(x, 2.1, 7.86), Vector3(0.1, 3.25, 0.12), "iron" if present else "brass")
	for x: float in [-2.7, -2.08, 2.08, 2.7]:
		_block(Vector3(x, 6.4, 7.69), Vector3(0.35, 11.3, 0.42), "marble")
	_block(Vector3(0, 4.3, 8.15), Vector3(6.55, 0.3, 2.4), "iron")
	_block(Vector3(0, 4.5, 9.36), Vector3(6.6, 0.38, 0.22), "stone" if present else "brass")
	_block(Vector3(0, 5.12, 7.75), Vector3(4.4, 0.84, 0.22), "lacquer")
	var sign := _label("GRAND HOTEL AURORA", Vector3(0, 5.13, 7.92), 0.29, COLD if present else WARM)
	sign.shaded = false
	if present:
		for i in 3:
			_block(Vector3(0, 1.2 + i * 0.74, 7.96), Vector3(3.62, 0.27, 0.11),
				"plank", Vector3(0, 0, -13.0 + i * 10.0))
	else:
		_omni(Vector3(0, 3.8, 8.65), WARM, 2.4, 10.0)
	for y: float in [7.0, 10.3]:
		_window(Vector3(0, y, 7.6), 0.0, Vector2(2.6, 1.75), 0)


func _build_clock_tower() -> void:
	_block(Vector3(0, 13.65, 3.7), Vector3(7.7, 1.42, 7.4), "stone")
	_block(Vector3(0, 15.85, 3.7), Vector3(6.35, 4.1, 6.3), "plaster_cream")
	_block(Vector3(0, 18.25, 3.7), Vector3(5.5, 1.25, 5.5), "stone")
	_block(Vector3(0, 19.05, 3.7), Vector3(4.15, 0.55, 4.15), "iron")
	_block(Vector3(0, 19.47, 3.7), Vector3(2.6, 0.45, 2.6), "stone")
	_cylinder(Vector3(0, 19.67, 3.7), 0.12, 0.04, 1.05, "iron")
	for x: float in [-2.56, 2.56]:
		_block(Vector3(x, 15.73, 6.86), Vector3(0.42, 3.3, 0.31), "marble")
	var clock := Vector3(0, 15.95, 7.0)
	_cylinder(clock, 1.45, 1.45, 0.13, "iron" if present else "brass", Vector3(90, 0, 0), 32)
	var dial := _cylinder(clock + Vector3(0, 0, 0.135), 1.28, 1.28, 0.03, "marble", Vector3(90, 0, 0), 32)
	if not present:
		dial.material_override = _lit_glass
	for i in 12:
		var angle := i * TAU / 12.0
		var mark := Vector3(-sin(angle), cos(angle), 0.0) * 1.07
		_block(clock + mark + Vector3(0, 0, 0.18), Vector3(0.065, 0.15, 0.025),
			"iron", Vector3(0, 0, rad_to_deg(angle)))

	var hour := 3.0 + 7.0 / 60.0 if present else 11.0 + 40.0 / 60.0
	_clock_hand(clock, hour * TAU / 12.0, 0.68, 0.1, 0.22)
	_clock_hand(clock, (7.0 if present else 40.0) * TAU / 60.0, 0.98, 0.065, 0.25)


func _clock_hand(clock: Vector3, angle: float, length_m: float, width: float, depth: float) -> void:
	var offset := Vector3(sin(angle), cos(angle), 0.0) * length_m * 0.45
	_block(clock + offset + Vector3(0, 0, depth), Vector3(width, length_m, 0.035),
		"iron", Vector3(0, 0, -rad_to_deg(angle)))


func _build_street() -> void:
	for side: float in [-1.0, 1.0]:
		for i in 5:
			var at := Vector3(side * (23.0 + i * 5.4), 0, -10.0 - _random(i, 7.0) * 12.0)
			var height := 4.0 + _random(i, 9.0) * 7.0
			_block(at + Vector3.UP * height / 2.0, Vector3(4.9, height, 5.5), "stone")
			for row in int(height / 1.6):
				for x: float in [-1.25, 1.25]:
					if not present or _random(row + i, x) > 0.65:
						_block(at + Vector3(x, 1.0 + row * 1.55, 2.77), Vector3(0.5, 0.72, 0.05),
							"moonlight" if present else "street")
		var lamp := Vector3(side * 8.1, 0, 12.3)
		_cylinder(lamp, 0.19, 0.1, 0.46, "iron")
		_cylinder(lamp + Vector3.UP * 0.46, 0.07, 0.05, 2.48, "iron")
		_block(lamp + Vector3.UP * 3.0, Vector3(0.3, 0.48, 0.3), "glass" if present else "bulb")
		_block(lamp + Vector3.UP * 3.27, Vector3(0.46, 0.1, 0.46), "iron")
		if present:
			for i in 5:
				_block(Vector3(side * (3.5 + i * 0.62), 0.12, 8.4 + _random(i, 5.0) * 1.8),
					Vector3(0.46, 0.24, 0.42), "rubble", Vector3(0, _random(i) * 90.0, i * 8.0))
		else:
			_omni(lamp + Vector3.UP * 2.92, WARM, 2.5, 6.0)
