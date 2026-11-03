class_name Items
extends RefCounted
## Catálogo dos objetos que uma personagem pode segurar na mão.

const DATA: Dictionary = {
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
