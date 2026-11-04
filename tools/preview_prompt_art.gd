extends Node2D
## Conferência isolada dos recortes. Não instancia salas, física nem enigmas.

const ANIMATIONS: Array[StringName] = [
	&"walk_side", &"walk_front", &"walk_back", &"idle_side", &"idle_front", &"idle_back",
	&"reach_side", &"reach_down", &"gelo_walk", &"fermento_walk", &"gelo_use", &"fermento_use",
]
const LABELS: Array[String] = [
	"Caminhar de lado", "Caminhar de frente", "Caminhar de costas",
	"Parada de lado", "Parada de frente", "Parada de costas",
	"Alcançar à frente", "Alcançar no chão", "Carregar gelo", "Carregar fermento",
	"Colocar gelo no chão", "Usar fermento",
]

var _sprites: Array[AnimatedSprite2D] = []
var _caption: Label
var _index: int = 0
var _paused: bool = false


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#202832"))
	_label("Conferência dos recortes", Vector2(20, 12), 20)
	_label("Setas: trocar pose   |   Espaço: pausar   |   R: repetir", Vector2(20, 42), 12)
	_caption = _label("Aguardando os recortes", Vector2(20, 67), 14)
	for character in ["lia", "helena"]:
		var path := "res://art/processed/characters/%s/%s_animations.tres" % [character, character]
		if not ResourceLoader.exists(path):
			continue
		var frames := load(path) as SpriteFrames
		assert(frames != null, "SpriteFrames inválido: " + path)
		for animation in [&"walk_side", &"walk_front", &"walk_back"]:
			assert(frames.get_frame_count(animation) == 8, "Caminhada deve ter 8 quadros")
		for animation in frames.get_animation_names():
			for frame_index in frames.get_frame_count(animation):
				assert(frames.get_frame_texture(animation, frame_index) != null, "Textura ausente")
		var sprite := AnimatedSprite2D.new()
		sprite.name = character.capitalize()
		sprite.sprite_frames = frames
		sprite.centered = false
		if character == "lia":
			sprite.position = Vector2(160, 308)
			sprite.offset = Vector2(-128, -304)
			sprite.scale = Vector2.ONE * 0.68
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		else:
			sprite.position = Vector2(480, 308)
			sprite.offset = Vector2(-24, -60)
			sprite.scale = Vector2.ONE * 4.08
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(sprite)
		_sprites.append(sprite)
		_label(character.capitalize(), Vector2(sprite.position.x - 25, 324), 14)
	if not _sprites.is_empty():
		_play()
	queue_redraw()
	if "--verify" in OS.get_cmdline_user_args():
		assert(_sprites.size() == 2, "Os dois pacotes de recortes devem estar presentes")
		print("PASS: dois SpriteFrames, caminhadas de 8 quadros e todas as texturas carregadas")
		get_tree().quit()
	elif "--capture" in OS.get_cmdline_user_args():
		await get_tree().create_timer(0.15).timeout
		for sprite in _sprites:
			sprite.pause()
		await RenderingServer.frame_post_draw
		var target := "res://art/processed/previews/godot-preview.png"
		var result := get_viewport().get_texture().get_image().save_png(target)
		assert(result == OK, "Falha ao salvar captura")
		print("Captura: ", ProjectSettings.globalize_path(target))
		get_tree().quit()


func _draw() -> void:
	draw_line(Vector2(30, 308), Vector2(610, 308), Color("#788696"), 1.0)
	draw_line(Vector2(320, 100), Vector2(320, 340), Color("#3a4756"), 1.0)
	for x in [160, 480]:
		draw_line(Vector2(x, 100), Vector2(x, 312), Color(0.3, 0.4, 0.5, 0.3), 1.0)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_RIGHT:
			_index = (_index + 1) % ANIMATIONS.size()
			_play()
		KEY_LEFT:
			_index = posmod(_index - 1, ANIMATIONS.size())
			_play()
		KEY_SPACE:
			_paused = not _paused
			for sprite in _sprites:
				if _paused:
					sprite.pause()
				else:
					sprite.play()
		KEY_R:
			_play()


func _play() -> void:
	_caption.text = "%s (%d/%d)" % [LABELS[_index], _index + 1, ANIMATIONS.size()]
	for sprite in _sprites:
		var animation: StringName = ANIMATIONS[_index]
		if not sprite.sprite_frames.has_animation(animation):
			animation = &"idle_side"
		sprite.stop()
		sprite.play(animation)
		if _paused:
			sprite.pause()


func _label(text: String, at: Vector2, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size", size)
	add_child(label)
	return label
