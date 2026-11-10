class_name HotelMaterials
extends RefCounted
## Catálogo de materiais do hotel por papel ("wallpaper", "brass"...) e época.
## As duas épocas usam o mesmo shader procedural; hoje, o mesmo desenho envelhecido 100 anos.
## Os materiais ficam em cache: todas as peças do mesmo papel compartilham um só.

const SURFACE_SHADER := preload("res://shaders/spatial_env_hotel_surface.gdshader")
const NIGHT_SHADER := preload("res://shaders/spatial_env_night_window.gdshader")

enum Pattern { PLAIN, WALLPAPER, MARBLE_TILES, WOOD, METAL, RUG, PLASTER, CLOTH, PAINTING }

## papel: [padrão, cor A, cor B, cor C, escala (m), aspereza, metálico]
const PAST := {
	"wallpaper": [Pattern.WALLPAPER, "#5E2329", "#401A1F", "#C9973B", 0.55, 0.85, 0.0],
	# Um papel por andar: Quartos (flor miúda, verde-musgo e ouro velho) e Salão (leque, azul-noite)
	"wallpaper_rooms": [Pattern.WALLPAPER, "#2F3D2E", "#263326", "#A88C50", 0.42, 0.85, 0.0],
	"wallpaper_ballroom": [Pattern.WALLPAPER, "#23304A", "#1A2438", "#C9A45A", 0.7, 0.8, 0.0],
	"wainscot": [Pattern.WOOD, "#3A1C12", "#25110B", "#000000", 1.4, 0.55, 0.0],
	"panel": [Pattern.WOOD, "#2C140D", "#1A0B07", "#000000", 1.1, 0.5, 0.0],
	"floor": [Pattern.MARBLE_TILES, "#1E3A2D", "#D6CAB0", "#0D1912", 0.8, 0.25, 0.0],
	"marble": [Pattern.MARBLE_TILES, "#E2D8C2", "#D8CDB4", "#BFB39A", 3.0, 0.2, 0.0],
	"column": [Pattern.MARBLE_TILES, "#2A4A3A", "#24402F", "#2A4A3A", 4.0, 0.3, 0.0],
	"ceiling": [Pattern.PLASTER, "#CDBF9E", "#000000", "#000000", 1.0, 0.9, 0.0],
	"coffer": [Pattern.PLASTER, "#3B1A1F", "#000000", "#000000", 1.0, 0.85, 0.0],
	"brass": [Pattern.METAL, "#C9973B", "#000000", "#3F6B5A", 0.6, 0.32, 0.9],
	"iron": [Pattern.METAL, "#2A2624", "#000000", "#5A3A22", 0.6, 0.45, 0.8],
	"mahogany": [Pattern.WOOD, "#5A1E16", "#3A120C", "#000000", 0.9, 0.4, 0.0],
	"dark_wood": [Pattern.WOOD, "#2E1A12", "#1C0F0A", "#000000", 0.9, 0.5, 0.0],
	"velvet": [Pattern.CLOTH, "#7A2230", "#4A1018", "#000000", 1.0, 0.95, 0.0],
	"leather": [Pattern.PLAIN, "#573526", "#35221B", "#1E140F", 0.8, 0.63, 0.0],
	"green_velvet": [Pattern.CLOTH, "#2A5A42", "#173526", "#000000", 1.0, 0.95, 0.0],
	"rug": [Pattern.RUG, "#6B1E2A", "#A8782C", "#1F3A2E", 1.0, 0.95, 0.0],
	"runner": [Pattern.RUG, "#5A1622", "#7A2230", "#C9973B", 1.0, 0.95, 0.0],
	"lacquer": [Pattern.PLAIN, "#1C1416", "#000000", "#000000", 1.0, 0.1, 0.0],
	"ivory": [Pattern.PLAIN, "#EDE4CF", "#000000", "#000000", 1.0, 0.3, 0.0],
	"paper": [Pattern.PLAIN, "#E8DCC0", "#000000", "#000000", 1.0, 0.9, 0.0],
	"leaf": [Pattern.CLOTH, "#2F5A2A", "#1E3E1C", "#000000", 0.4, 0.8, 0.0],
	"pot": [Pattern.PLAIN, "#7A3A22", "#000000", "#000000", 1.0, 0.7, 0.0],
	"painting": [Pattern.PAINTING, "#3A5A7A", "#2E3A22", "#E0B070", 1.2, 0.7, 0.0],
	"night": [Pattern.PLAIN, "#0A1020", "#000000", "#000000", 1.0, 1.0, 0.0],
	"rubble": [Pattern.PLASTER, "#6B665C", "#000000", "#000000", 1.0, 1.0, 0.0],
	"plank": [Pattern.WOOD, "#5A4A38", "#3E3226", "#000000", 1.2, 0.9, 0.0],
	"tarp": [Pattern.CLOTH, "#6E7A84", "#4C565E", "#000000", 1.2, 0.95, 0.0],
	"dark": [Pattern.PLAIN, "#050608", "#000000", "#000000", 1.0, 1.0, 0.0],
	# Cozinha e despensa
	"tile": [Pattern.MARBLE_TILES, "#E9E3D3", "#E1DACA", "#8E887C", 0.15, 0.25, 0.0],
	"kitchen_floor": [Pattern.MARBLE_TILES, "#1B1B1B", "#D8D2C2", "#2A2A2A", 0.3, 0.35, 0.0],
	"plaster_cream": [Pattern.PLASTER, "#D6CDB4", "#000000", "#000000", 1.0, 0.9, 0.0],
	"stone": [Pattern.MARBLE_TILES, "#5E5448", "#564C40", "#2E2822", 0.45, 0.95, 0.0],
	"floorboards": [Pattern.WOOD, "#6A4A30", "#4E3420", "#000000", 0.8, 0.75, 0.0],
	"enamel": [Pattern.PLAIN, "#EDEBE2", "#000000", "#000000", 1.0, 0.25, 0.0],
	"copper": [Pattern.METAL, "#B8703C", "#000000", "#3F6B5A", 0.4, 0.3, 0.9],
	"cast_iron": [Pattern.METAL, "#1E1C1B", "#000000", "#5A3A22", 0.5, 0.55, 0.7],
	"dough": [Pattern.PLAIN, "#E6CF98", "#000000", "#000000", 1.0, 0.8, 0.0],
	"petrified": [Pattern.PLASTER, "#8E826C", "#000000", "#000000", 1.0, 1.0, 0.0],
	"flour": [Pattern.CLOTH, "#D9D0B8", "#B8AE96", "#000000", 0.5, 0.95, 0.0],
	"ham": [Pattern.PLAIN, "#7A3A2A", "#000000", "#000000", 1.0, 0.6, 0.0],
	"oak": [Pattern.WOOD, "#7A5230", "#5A3A1E", "#000000", 0.7, 0.55, 0.0],
}

## Hoje: as mesmas peças envelhecidas; alguns papéis ganham cor própria (lona, escombros).
const PRESENT_COLORS := {
	"wallpaper": ["#3C4752", "#2B343D", "#58626C"],
	"wallpaper_rooms": ["#3E4640", "#2E3530", "#5E6458"],
	"wallpaper_ballroom": ["#2E3644", "#222834", "#565E6C"],
	"ceiling": ["#5A5E5C", "#000000", "#000000"],
	"coffer": ["#2A3036", "#000000", "#000000"],
	"brass": ["#6E5A34", "#000000", "#3F6B5A"],
	"velvet": ["#34272A", "#211A1C", "#000000"],
	"green_velvet": ["#2E3E36", "#1C2620", "#000000"],
	"leaf": ["#4A3A22", "#2E2416", "#000000"],
	"paper": ["#8C8A70", "#000000", "#000000"],
	"night": ["#060A12", "#000000", "#000000"],
	"floor": ["#1A2620", "#6E6C62", "#101410"],
	"marble": ["#77746A", "#6E6B62", "#5E5B54"],
	"column": ["#26342E", "#202C27", "#26342E"],
	"ivory": ["#8E8A7C", "#000000", "#000000"],
	"tile": ["#8E8B80", "#86837A", "#3A3A34"],
	"kitchen_floor": ["#161816", "#6A675E", "#121412"],
	"plaster_cream": ["#5E5A50", "#000000", "#000000"],
	"enamel": ["#7E7C72", "#000000", "#000000"],
	"copper": ["#5A4A30", "#000000", "#3F6B5A"],
	"dough": ["#8A7E66", "#000000", "#000000"],
	"flour": ["#6E685A", "#5A5448", "#000000"],
	"ham": ["#3A2A22", "#000000", "#000000"],
}

## Texturas de detalhe por papel: [pasta em art/textures, modo (0 cor, 1 só brilho), metros por
## repetição, força do normal map]. Papéis fora daqui ficam só com o padrão procedural.
const DETAIL := {
	"mahogany": ["fine_grained_wood", 0, 1.2, 0.8], "dark_wood": ["fine_grained_wood", 0, 1.2, 0.8],
	"panel": ["fine_grained_wood", 0, 1.4, 0.8], "wainscot": ["fine_grained_wood", 0, 1.4, 0.8],
	"oak": ["fine_grained_wood", 0, 1.0, 0.8],
	"floorboards": ["wood_floor", 0, 2.0, 1.0], "plank": ["old_planks_02", 0, 1.6, 1.0],
	"ceiling": ["plastered_wall_02", 0, 2.5, 0.6], "coffer": ["plastered_wall_02", 0, 2.5, 0.6],
	"plaster_cream": ["plastered_wall_02", 0, 2.0, 0.7], "stone": ["plastered_stone_wall", 0, 2.0, 1.0],
	"rubble": ["chipped_concrete", 0, 1.5, 1.0], "petrified": ["chipped_concrete", 0, 1.0, 1.0],
	"floor": ["marble_01", 1, 1.2, 0.5], "marble": ["marble_01", 1, 1.5, 0.5], "column": ["marble_01", 1, 1.5, 0.5],
	"tile": ["marble_01", 1, 0.8, 0.4], "kitchen_floor": ["marble_01", 1, 1.0, 0.4],
	"brass": ["metal_plate_02", 1, 0.8, 0.4], "iron": ["metal_plate_02", 1, 0.8, 0.6],
	"copper": ["metal_plate_02", 1, 0.8, 0.4], "cast_iron": ["metal_plate_02", 1, 0.8, 0.6],
	"velvet": ["velour_velvet", 0, 0.6, 0.8], "green_velvet": ["velour_velvet", 0, 0.6, 0.8],
	"tarp": ["denim_fabric_03", 1, 0.6, 0.8], "flour": ["denim_fabric_03", 1, 0.5, 0.8],
	"leather": ["brown_leather", 0, 0.5, 0.8],
}
## Desenho do papel de parede por papel (ver wallpaper_motif no shader); os outros usam o losango.
const WALLPAPER_MOTIF := {"wallpaper_rooms": 2, "wallpaper_ballroom": 1}
const TEXTURES := "res://art/textures/%s/%s.jpg"

static var _cache: Dictionary = {}
static var _textures: Dictionary = {}
static var _averages: Dictionary = {}


static func get_material(role: String, present: bool) -> Material:
	var key := "%s:%s" % [role, present]
	if _cache.has(key):
		return _cache[key]
	var material: Material
	match role:
		"glass":
			material = _glass(present)
		"bulb":
			material = _emissive(Color("#FFD9A0") if not present else Color("#3A3A36"), 2.6 if not present else 0.0)
		"moonlight":
			material = _emissive(Color("#8FA6C8"), 0.6)
		"street":
			material = _emissive(Color("#F2C27A"), 3.0)
		"night":
			material = _night(present)
		"ice":
			var ice := _glass(false)
			ice.albedo_color = Color(0.8, 0.92, 0.98, 0.7)
			ice.roughness = 0.1
			material = ice
		_:
			material = _surface(role, present)
	_cache[key] = material
	return material


static func _surface(role: String, present: bool) -> ShaderMaterial:
	var spec: Array = PAST.get(role, PAST["dark"])
	var colors := [Color(spec[1]), Color(spec[2]), Color(spec[3])]
	if present and PRESENT_COLORS.has(role):
		colors = PRESENT_COLORS[role].map(func(hex: String) -> Color: return Color(hex))
	var material := ShaderMaterial.new()
	material.shader = SURFACE_SHADER
	material.set_shader_parameter("pattern", spec[0])
	material.set_shader_parameter("color_a", colors[0])
	material.set_shader_parameter("color_b", colors[1])
	material.set_shader_parameter("color_c", colors[2])
	material.set_shader_parameter("wallpaper_motif", WALLPAPER_MOTIF.get(role, 0))
	material.set_shader_parameter("pattern_scale", spec[4])
	material.set_shader_parameter("roughness_value", spec[5])
	material.set_shader_parameter("metallic_value", spec[6])
	material.set_shader_parameter("seed", float(role.hash() % 97))
	material.set_shader_parameter("age", 0.95 if present else 0.0)
	material.set_shader_parameter("retro", false)
	material.set_shader_parameter("lite", GamePlatform.is_lite())
	# Reboco que aparece sob o papel rasgado: escuro, para não brilhar no escuro
	material.set_shader_parameter("bare_color", Color("#46403A"))
	if DETAIL.has(role):
		_apply_detail(material, DETAIL[role], colors[0])
	return material


static func _apply_detail(material: ShaderMaterial, detail: Array, color: Color) -> void:
	var folder: String = detail[0]
	material.set_shader_parameter("use_detail", true)
	material.set_shader_parameter("detail_mode", detail[1])
	material.set_shader_parameter("detail_scale", detail[2])
	material.set_shader_parameter("detail_normal_strength", detail[3])
	material.set_shader_parameter("detail_albedo", _texture(folder, "albedo"))
	material.set_shader_parameter("detail_normal", _texture(folder, "normal"))
	material.set_shader_parameter("detail_rough", _texture(folder, "rough"))
	var average: Color = _averages[folder]
	if int(detail[1]) == 0:
		# A média da textura vira a cor do papel na época
		material.set_shader_parameter("detail_tint", Vector3(color.r / maxf(average.r, 0.02),
			color.g / maxf(average.g, 0.02), color.b / maxf(average.b, 0.02)))
	else:
		var luma := average.r * 0.299 + average.g * 0.587 + average.b * 0.114
		material.set_shader_parameter("detail_tint", Vector3.ONE / maxf(luma, 0.05))


## Textura com mipmaps (as importadas vêm sem; sem mipmaps elas cintilam ao longe). Guardada
## para todos os materiais que usam a mesma.
static func _texture(folder: String, map: String) -> Texture2D:
	var path := TEXTURES % [folder, map]
	if _textures.has(path):
		return _textures[path]
	var image := (load(path) as Texture2D).get_image()
	if image.is_compressed():
		image.decompress()
	if map == "albedo":
		var small := image.duplicate() as Image
		small.resize(1, 1, Image.INTERPOLATE_BILINEAR)
		_averages[folder] = small.get_pixel(0, 0)
	if map == "rough" and image.get_format() != Image.FORMAT_L8:
		image.convert(Image.FORMAT_L8)
	image.generate_mipmaps()
	var texture := ImageTexture.create_from_image(image)
	_textures[path] = texture
	return texture


## O tapete precisa saber onde está para desenhar a borda e o medalhão.
static func rug_material(role: String, present: bool, center: Vector2, half_size: Vector2) -> ShaderMaterial:
	var material := (_surface(role, present) as ShaderMaterial)
	material.set_shader_parameter("rug_center", center)
	material.set_shader_parameter("rug_half_size", half_size)
	return material


## Noite atrás das janelas: degradê com estrelas (hoje, mais apagado pela bruma).
static func _night(present: bool) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = NIGHT_SHADER
	if present:
		material.set_shader_parameter("low_color", Color("#060A12"))
		material.set_shader_parameter("star_energy", 0.5)
	return material


static func _glass(present: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.75, 0.85, 0.9, 0.18) if not present else Color(0.5, 0.55, 0.5, 0.35)
	material.roughness = 0.05 if not present else 0.6
	material.metallic_specular = 0.9
	return material


static func _emissive(color: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = energy > 0.0
	material.emission = color
	material.emission_energy_multiplier = energy
	return material
