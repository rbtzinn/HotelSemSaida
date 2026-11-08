extends SceneTree
## Toda flag de enigma usada no jogo precisa estar nas regras do modo online
## (scripts/online/coop_progress.gd). Sem isso, a mudança não chega ao outro jogador
## e nada avisa. Este teste varre scripts e cenas atrás de "andar.objeto.estado".
## Rodar: Godot_console.exe --headless --path . --script res://tools/test_coop_flags.gd

const RULES := preload("res://scripts/online/coop_progress.gd")
const FLOORS := "(saguao|cozinha|manutencao|biblioteca|caldeiras|jogo|quartos|salao)"
## Chaves montadas com % no código, já expandidas.
const EXPANDED := ["biblioteca.volume.0", "biblioteca.volume.1", "biblioteca.volume.2", "biblioteca.volume.3",
	"caldeiras.f2.pinhao_f2.retirada", "caldeiras.f2.pinhao_f2.guardada",
	"caldeiras.f2.pinhao_f2.recuperada", "caldeiras.f2.pinhao_f2.montada",
	"caldeiras.f2.coroa_f2.retirada", "caldeiras.f2.coroa_f2.guardada",
	"caldeiras.f2.coroa_f2.recuperada", "caldeiras.f2.coroa_f2.montada"]


func _initialize() -> void:
	var pattern := RegEx.create_from_string("\"(" + FLOORS + "[.][a-z0-9_.]+)\"")
	var keys := {}
	for key: String in EXPANDED:
		keys[key] = true
	for folder: String in ["res://scripts", "res://scenes"]:
		for path in _files(folder):
			for found in pattern.search_all(FileAccess.get_file_as_string(path)):
				var key := found.get_string(1)
				if not key.ends_with("."):
					keys[key] = true
	var missing: Array[String] = []
	for key: String in keys:
		var ok := false
		for era in [0, 1]:
			for value: Variant in [true, 0, 1, 0.5]:
				ok = ok or RULES.allowed(era, key, value)
		if not ok:
			missing.append(key)
	assert(missing.is_empty(), "Flags fora das regras do online: %s" % [missing])
	print("PASS: %d flags de enigma cobertas pelas regras do online" % keys.size())
	quit()


func _files(folder: String) -> Array[String]:
	var result: Array[String] = []
	for file in DirAccess.get_files_at(folder):
		if file.ends_with(".gd") or file.ends_with(".tscn"):
			result.append(folder.path_join(file))
	for sub in DirAccess.get_directories_at(folder):
		result.append_array(_files(folder.path_join(sub)))
	return result
