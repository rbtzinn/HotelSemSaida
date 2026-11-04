// Hotel Sem Saída — material procedural das superfícies do hotel (Claude Code, 04/11/2026).
// Um shader para todo o cenário: o padrão (papel de parede, mármore, madeira, metal, tapete,
// reboco, lona, tela de quadro) é escolhido por uniform, e as coordenadas vêm da posição no
// mundo (projeção pelos três eixos), então qualquer caixa repete o padrão sem emendas.
// `age` envelhece a mesma superfície em 100 anos (manchas, mofo, rasgos, rachaduras, ferrugem);
// `retro` dá o ar de PS1 de 1923 (padrão em texels grandes, cores reduzidas, vértices presos
// a uma grade de tela).
// Alvo: Forward+ (cai para Compatibility sem mudanças). Orçamento: até ~2 fbm e 1 Voronoi por
// pixel, sem texturas. O `if` sobre `pattern` é uniforme por material (todos os pixels seguem o
// mesmo caminho), então não diverge.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

#include "res://shaders/noise.gdshaderinc"

const int PATTERN_PLAIN = 0;
const int PATTERN_WALLPAPER = 1;
const int PATTERN_MARBLE_TILES = 2;
const int PATTERN_WOOD = 3;
const int PATTERN_METAL = 4;
const int PATTERN_RUG = 5;
const int PATTERN_PLASTER = 6;
const int PATTERN_CLOTH = 7;
const int PATTERN_PAINTING = 8;

group_uniforms base;
uniform int pattern : hint_range(0, 8) = 0;
uniform vec4 color_a : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform vec4 color_b : source_color = vec4(0.4, 0.4, 0.4, 1.0);
uniform vec4 color_c : source_color = vec4(0.8, 0.7, 0.4, 1.0);
// Tamanho de uma repetição do padrão, em metros.
uniform float pattern_scale : hint_range(0.05, 8.0) = 1.0;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.8;
uniform float metallic_value : hint_range(0.0, 1.0) = 0.0;
// Muda o sorteio do ruído entre peças do mesmo material.
uniform float seed = 0.0;
// Tapete: centro e meia-extensão no plano do piso (x, z), em metros.
uniform vec2 rug_center = vec2(0.0);
uniform vec2 rug_half_size = vec2(1.0);
group_uniforms;

group_uniforms aging;
// 0 = 1923, novo; 1 = 100 anos de abandono.
uniform float age : hint_range(0.0, 1.0) = 0.0;
uniform vec4 stain_color : source_color = vec4(0.18, 0.15, 0.1, 1.0);
uniform vec4 moss_color : source_color = vec4(0.22, 0.29, 0.16, 1.0);
uniform vec4 bare_color : source_color = vec4(0.55, 0.53, 0.48, 1.0);
group_uniforms;

group_uniforms retro;
uniform bool retro = false;
// Texels por metro do padrão no modo retrô (blocos visíveis).
uniform float retro_texels_per_meter = 24.0;
// Níveis por canal de cor no modo retrô.
uniform float retro_color_steps = 24.0;
// Grade de tela em que os vértices encaixam (0 = desliga).
uniform vec2 retro_snap_resolution = vec2(320.0, 180.0);
group_uniforms;

varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	// Quando o shader usa POSITION, ela precisa ser escrita sempre: sem isso os vértices
	// desabam na origem e a peça some (era o que apagava o presente inteiro).
	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	if (retro && retro_snap_resolution.x > 0.0) {
		// Vértices presos a uma grade de tela baixa, como no PS1 (sem precisão sub-pixel)
		vec2 grid = retro_snap_resolution * 0.5;
		clip.xy = floor(clip.xy / clip.w * grid + 0.5) / grid * clip.w;
	}
	POSITION = clip;
}

// Coordenada do plano mais alinhado à face: piso/teto em xz, paredes em zy ou xy.
vec2 planar_uv(vec3 position, vec3 normal) {
	vec3 axis = abs(normal);
	if (axis.y >= axis.x && axis.y >= axis.z) {
		return position.xz;
	}
	if (axis.x >= axis.z) {
		return vec2(position.z, -position.y);
	}
	return vec2(position.x, -position.y);
}

vec3 wallpaper(vec2 uv) {
	vec2 p = uv / pattern_scale;
	// Faixa larga, faixa estreita e filete fino, como um listrado art déco
	float band = fract(p.x);
	float wide = smoothstep(0.0, 0.02, band) * (1.0 - smoothstep(0.46, 0.48, band));
	float pin = smoothstep(0.62, 0.63, band) * (1.0 - smoothstep(0.65, 0.66, band));
	// Losangos discretos dentro da faixa larga
	vec2 cell = fract(vec2(p.x * 2.0, p.y * 2.4)) - 0.5;
	float diamond = 1.0 - smoothstep(0.28, 0.31, abs(cell.x) + abs(cell.y));
	vec3 base = mix(color_b.rgb, color_a.rgb, wide);
	base = mix(base, color_c.rgb, pin * 0.85);
	base = mix(base, mix(base, color_c.rgb, 0.35), diamond * wide * 0.5);
	return base;
}

vec3 marble_tiles(vec2 uv, out float grout) {
	vec2 p = uv / pattern_scale;
	vec2 tile = floor(p);
	vec2 local = fract(p);
	float checker = mod(tile.x + tile.y, 2.0);
	vec3 base = mix(color_a.rgb, color_b.rgb, checker);
	// Veios: senoide deformada por fbm, fina e clara
	float veins = abs(sin((p.x + p.y) * 2.2 + fbm(p * 1.7 + tile * 3.1 + seed) * 7.0));
	base = mix(base, mix(base, vec3(1.0), 0.35), (1.0 - smoothstep(0.0, 0.07, veins)) * 0.8);
	base *= 0.92 + 0.12 * fbm(p * 5.0 + seed);
	// Rejunte: faixa estreita nas bordas de cada ladrilho
	vec2 edge = min(local, 1.0 - local);
	grout = 1.0 - smoothstep(0.0, 0.018, min(edge.x, edge.y));
	return mix(base, color_c.rgb, grout);
}

vec3 wood(vec2 uv) {
	vec2 p = uv / pattern_scale;
	// Tábuas na direção u, cada fileira deslocada
	float row = floor(p.y * 4.0);
	float plank_shift = hash12(vec2(row, seed)) * 3.0;
	float along = p.x + plank_shift;
	float grain = fract(p.y * 4.0 * 6.0 + fbm(vec2(along * 0.6, p.y * 14.0)) * 2.5);
	float ring = smoothstep(0.35, 0.5, grain) * (1.0 - smoothstep(0.5, 0.65, grain));
	vec3 base = mix(color_a.rgb, color_b.rgb, ring * 0.7 + fbm(vec2(along * 2.0, row)) * 0.3);
	float seam = 1.0 - smoothstep(0.0, 0.03, min(fract(p.y * 4.0), 1.0 - fract(p.y * 4.0)));
	return mix(base, base * 0.45, seam);
}

vec3 metal(vec2 uv) {
	vec2 p = uv / pattern_scale;
	float brushed = value_noise(vec2(p.x * 40.0, p.y * 2.0));
	return color_a.rgb * (0.85 + 0.25 * brushed);
}

vec3 rug(vec2 world_xz) {
	vec2 local = (world_xz - rug_center) / rug_half_size;
	vec2 border = abs(local);
	float frame = step(0.86, max(border.x, border.y)) - step(0.96, max(border.x, border.y));
	float radius = length(local * vec2(1.0, rug_half_size.y / rug_half_size.x));
	float rings = smoothstep(0.02, 0.0, abs(fract(radius * 4.0) - 0.5) - 0.42);
	float medallion = 1.0 - smoothstep(0.30, 0.33, radius);
	float petals = step(0.5, fract(atan(local.y, local.x) / 6.2832 * 12.0)) * medallion;
	vec3 base = color_a.rgb;
	base = mix(base, color_b.rgb, max(rings * (1.0 - medallion), petals));
	base = mix(base, color_c.rgb, frame);
	base *= 0.9 + 0.15 * value_noise(world_xz * 60.0);
	return base;
}

vec3 plaster(vec2 uv) {
	return color_a.rgb * (0.88 + 0.18 * fbm(uv * 2.5 + seed));
}

vec3 cloth(vec2 uv) {
	// Dobras largas da lona
	float folds = fbm(vec2(uv.x * 1.3, uv.y * 3.0) + seed);
	return mix(color_b.rgb, color_a.rgb, smoothstep(0.25, 0.75, folds));
}

vec3 painting(vec2 uv) {
	vec2 p = uv / pattern_scale + seed;
	float horizon = smoothstep(0.0, 0.08, fract(-p.y) - 0.45 - fbm(vec2(p.x * 2.0, seed)) * 0.25);
	vec3 sky = mix(color_a.rgb, color_c.rgb, fbm(p * 3.0));
	vec3 land = mix(color_b.rgb, color_b.rgb * 0.5, fbm(p * 6.0));
	return mix(land, sky, horizon);
}

void fragment() {
	vec2 uv = planar_uv(world_position, world_normal);
	vec2 rug_xz = world_position.xz;
	if (retro) {
		// Padrão em blocos grandes, como uma textura de baixa resolução sem filtro
		uv = floor(uv * retro_texels_per_meter) / retro_texels_per_meter;
		rug_xz = floor(rug_xz * retro_texels_per_meter) / retro_texels_per_meter;
	}

	vec3 albedo = color_a.rgb;
	float roughness = roughness_value;
	float metallic = metallic_value;
	float grout = 0.0;
	if (pattern == PATTERN_WALLPAPER) {
		albedo = wallpaper(uv);
	} else if (pattern == PATTERN_MARBLE_TILES) {
		albedo = marble_tiles(uv, grout);
		roughness = mix(roughness, 0.95, grout);
	} else if (pattern == PATTERN_WOOD) {
		albedo = wood(uv);
	} else if (pattern == PATTERN_METAL) {
		albedo = metal(uv);
	} else if (pattern == PATTERN_RUG) {
		albedo = rug(rug_xz);
	} else if (pattern == PATTERN_PLASTER) {
		albedo = plaster(uv);
	} else if (pattern == PATTERN_CLOTH) {
		albedo = cloth(uv);
	} else if (pattern == PATTERN_PAINTING) {
		albedo = painting(uv);
	}

	// Envelhecimento: tudo some sob camadas de pó, manchas, mofo e rachaduras.
	// Em 1923 (age = 0) o bloco inteiro é pulado: é a parte mais cara do shader.
	if (age > 0.0) {
	float dust = fbm(uv * 0.8 + seed + 3.7);
	float stains = smoothstep(0.55, 0.78, fbm(vec2(uv.x * 1.6, uv.y * 0.5) + seed * 1.3));
	float moss = smoothstep(0.62, 0.8, fbm(uv * 1.1 + seed + 11.0)) * (0.4 + 0.6 * grout);
	float cracks = 1.0 - smoothstep(0.0, 0.025, voronoi_edge(uv * 1.4 + seed));
	cracks *= smoothstep(0.45, 0.7, fbm(uv * 0.6 + seed + 5.0));
	vec3 aged = mix(albedo, vec3(dot(albedo, vec3(0.33))), 0.45) * (0.75 + 0.2 * dust);
	if (pattern == PATTERN_WALLPAPER) {
		// Papel rasgado mostrando o reboco por baixo
		float torn = smoothstep(0.60, 0.63, fbm(uv * 0.55 + seed + 21.0));
		aged = mix(aged, bare_color.rgb * (0.85 + 0.2 * dust), torn);
	}
	if (pattern == PATTERN_METAL) {
		aged = mix(aged, color_c.rgb, smoothstep(0.4, 0.75, fbm(uv * 3.0 + seed)));
	}
	aged = mix(aged, stain_color.rgb, stains * 0.65);
	aged = mix(aged, moss_color.rgb, moss);
	aged = mix(aged, aged * 0.35, cracks);
	albedo = mix(albedo, aged, age);
	roughness = mix(roughness, min(1.0, roughness + 0.25), age);
	metallic = mix(metallic, metallic * 0.3, age);
	}

	if (retro) {
		albedo = floor(albedo * retro_color_steps + 0.5) / retro_color_steps;
	}
	ALBEDO = albedo;
	ROUGHNESS = roughness;
	METALLIC = metallic;
}
