extends Node
## Autoload: memória do que Helena mudou no passado.
## Guarda flags "andar.objeto.estado" (ex.: "cozinha.elevador.travado") com valor bool ou int.
## O arquivo de save é responsabilidade do SaveSystem (to_dict / load_dict).

signal flag_changed(key: String, value: Variant)

var _flags: Dictionary = {}


func set_flag(key: String, value: Variant = true) -> void:
	_flags[key] = value
	flag_changed.emit(key, value)


func get_flag(key: String, default: Variant = false) -> Variant:
	return _flags.get(key, default)


## Atalho para flags booleanas.
func is_set(key: String) -> bool:
	return bool(_flags.get(key, false))


func clear() -> void:
	_flags.clear()


func to_dict() -> Dictionary:
	return _flags.duplicate()


func load_dict(data: Dictionary) -> void:
	_flags.clear()
	for key in data:
		var value: Variant = data[key]
		# O JSON lê todo número como float; volta para int quando for inteiro
		if value is float and value == floorf(value):
			value = int(value)
		_flags[key] = value
