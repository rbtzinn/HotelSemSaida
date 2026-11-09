class_name EraEnvironment
extends WorldEnvironment
## Ambiente de cada época, trocado junto com o cenário:
## 1923, quente e brilhante, com névoa leve e brilho das lâmpadas;
## hoje, frio, escuro e com névoa volumétrica para os fachos de luar e da lanterna.

## Cena a céu aberto (Torre): névoa e fundo de noite azulada em vez do marrom dos salões,
## que tingia o céu e a silhueta da cidade de 1923.
@export var outdoor: bool = false

const NIGHT_SKY := preload("res://shaders/sky_env_night.gdshader")

var _past: Environment
var _present: Environment


func _ready() -> void:
	_rebuild()
	EraManager.era_changed.connect(_apply)
	Settings.changed.connect(_rebuild)


## Monta os dois ambientes de novo (a qualidade gráfica liga ou desliga SSAO e névoa volumétrica).
func _rebuild() -> void:
	_past = _make_past()
	_present = _make_present()
	_apply(EraManager.current_era)


func _apply(era: Era.Id) -> void:
	environment = _past if era == Era.Id.PAST_1923 else _present


func _make_past() -> Environment:
	var env := _base()
	env.background_color = Color("#070405")
	env.ambient_light_color = Color("#8A5A3E")
	env.ambient_light_energy = 0.35
	env.tonemap_exposure = 1.05
	env.glow_intensity = 0.8
	env.glow_bloom = 0.04
	env.fog_enabled = true
	env.fog_light_color = Color("#3A2014")
	env.fog_density = 0.008
	env.adjustment_saturation = 1.08
	if outdoor:
		env.background_color = Color("#04060C")
		env.fog_light_color = Color("#141A28")
		env.fog_density = 0.004
		_use_night_sky(env, 1.0)
	return env


func _make_present() -> Environment:
	var env := _base()
	env.background_color = Color("#020305")
	# Ambiente frio mas claro o bastante para ler o salão no escuro; a lanterna faz o resto
	env.ambient_light_color = Color("#6A7E96")
	env.ambient_light_energy = 0.95
	env.tonemap_exposure = 1.15
	env.glow_intensity = 0.55
	# Sem névoa volumétrica (qualidade baixa), uma névoa comum fria faz o mesmo papel, mais barata
	env.volumetric_fog_enabled = Settings.volumetric_fog_enabled()
	env.fog_enabled = not env.volumetric_fog_enabled
	env.fog_light_color = Color("#1E2630")
	env.fog_density = 0.02
	env.volumetric_fog_density = 0.012
	# A névoa recebe um pouco da luz ambiente; sem isso ela só absorve e o salão some no preto
	env.volumetric_fog_ambient_inject = 0.5
	env.volumetric_fog_albedo = Color("#9AA8B8")
	env.volumetric_fog_length = 24.0
	env.adjustment_saturation = 0.72
	env.adjustment_contrast = 1.08
	if outdoor:
		env.background_color = Color("#030409")
		# Hoje o céu é o mesmo, um pouco mais apagado pela bruma
		_use_night_sky(env, 0.7)
	return env


## Céu com lua e estrelas no lugar da cor chapada. Só o fundo: a luz ambiente continua a cor
## da época, e a névoa não cobre o céu (senão a lua sumia atrás dela).
func _use_night_sky(env: Environment, energy: float) -> void:
	var material := ShaderMaterial.new()
	material.shader = NIGHT_SKY
	material.set_shader_parameter("star_energy", 0.9 * energy)
	material.set_shader_parameter("moon_energy", 1.6 * energy)
	var sky := Sky.new()
	sky.sky_material = material
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	sky.process_mode = Sky.PROCESS_MODE_INCREMENTAL
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.fog_sky_affect = 0.0
	env.volumetric_fog_sky_affect = 0.0


func _base() -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_hdr_threshold = 1.0
	env.ssao_enabled = Settings.ssao_enabled()
	env.ssao_radius = 1.2
	env.ssao_intensity = 1.6
	env.adjustment_enabled = true
	return env
