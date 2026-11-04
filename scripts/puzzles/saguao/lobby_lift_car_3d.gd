@tool
extends HotelBuilder3D

var width: float = 1.7

func _build_room() -> void:
	var x0 := -width / 2.0
	var x1 := width / 2.0
	# Cabine: atrás da grade em 1923; hoje, podre e afundada no térreo
	var cabin_role := "mahogany" if not present else "plank"
	var sink := 0.0 if not present else -0.35
	var tilt := Vector3.ZERO if not present else Vector3(4, 0, -3)
	_part(Vector3(x0, sink - 0.1, -1.8), Vector3(x1, sink, -0.05), cabin_role, tilt)
	_part(Vector3(x0, sink, -1.85), Vector3(x1, sink + 2.6, -1.8), cabin_role, tilt)
	_part(Vector3(x0, sink, -1.8), Vector3(x0 + 0.05, sink + 2.6, -0.05), cabin_role, tilt)
	_part(Vector3(x1 - 0.05, sink, -1.8), Vector3(x1, sink + 2.6, -0.05), cabin_role, tilt)
	_part(Vector3(x0, sink + 2.6, -1.85), Vector3(x1, sink + 2.65, -0.05), "dark_wood", tilt)
	_part(Vector3(x0 + 0.1, sink + 0.9, -1.78), Vector3(x1 - 0.1, sink + 0.95, -1.74), "brass", tilt)
	if not present:
		_part(Vector3(-0.3, 2.54, -1.2), Vector3(0.3, 2.6, -0.6), "bulb")
		_omni(Vector3(0, 2.3, -0.9), Color("#F2D49B"), 0.8, 3.0)
