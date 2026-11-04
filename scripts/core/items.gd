class_name Items
extends RefCounted
## Catálogo dos objetos que uma personagem pode segurar na mão.

const DATA: Dictionary = {
	"chave_quadro": {"name": "Chave da recepção", "color": Color("#C9973B")},
	"pinhao_f2": {"name": "Pinhão da F-2", "color": Color("#B9864C")},
	"coroa_f2": {"name": "Coroa da F-2", "color": Color("#B59966")},
	"chave_biblioteca": {"name": "Chave da Biblioteca", "color": Color("#C9973B")},
	"atlas": {"name": "Atlas do Aurora", "color": Color("#5A1E16")},
	"fermento": {"name": "Fermento", "color": Color("#E8D9B0")},
	"gelo": {"name": "Bloco de gelo", "color": Color("#BFE3F0")},
}


static func display_name(item_id: String) -> String:
	return DATA[item_id]["name"] if DATA.has(item_id) else item_id


static func color(item_id: String) -> Color:
	return DATA[item_id]["color"] if DATA.has(item_id) else Color.WHITE


static func texture(item_id: String) -> Texture2D:
	var files := {"fermento": "res://art/sprites/fermento.png", "gelo": "res://art/sprites/gelo.png"}
	return load(files[item_id]) if files.has(item_id) else null
