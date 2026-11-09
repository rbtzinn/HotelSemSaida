// Hotel Sem Saída — material procedural das superfícies do hotel (Claude Code, 04/11/2026).
// Um shader para todo o cenário: o padrão (papel de parede, mármore, madeira, metal, tapete,
// reboco, lona, tela de quadro) é escolhido por uniform, e as coordenadas vêm da posição no
// mundo (projeção pelos três eixos), então qualquer caixa repete o padrão sem emendas.
// `age` envelhece a mesma superfície em 100 anos (manchas, mofo, rasgos, rachaduras, ferrugem);
// `retro` dá o ar de 1923 com cores levemente reduzidas (os texels grandes e o tremido de
// vértices do PS1 foram retirados: em primeira pessoa faziam o cenário piscar).
// Texturas CC0 (Poly Haven, `art/textures/`) dão o detalhe de madeira, reboco, pedra, mármore,
// metal e tecidos: projetadas pelo plano da face (as peças são caixas alinhadas), tingidas para a
// paleta de cada época, com mipmaps (sem cintilar ao longe) e normal map.
// Alvo: Forward+ (cai para Compatibility sem mudanças). Orçamento: até ~2 fbm e 1 Voronoi por
// pixel, mais 3 leituras de textura nas superfícies com detalhe. O `if` sobre `pattern` é uniforme por material (todos os pixels seguem o
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

// Desenho dentro da faixa larga do papel de parede: um por andar do hotel.
const int MOTIF_DIAMOND = 0;
const int MOTIF_FAN = 1;
const int MOTIF_FLOWER = 2;
// Rachaduras do reboco: células por metro, meia-largura do traço (em células) e quanto a
// poeira entorta as linhas (sem isso elas saem retas, como vidro trincado).
// Raios do leque do papel de parede do Salão.
const float FAN_RAYS = 5.0;
const float CRACK_CELLS = 2.3;
const float CRACK_WIDTH = 0.016;
const float CRACK_WARP = 0.9;

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
// Papel de parede: 0 losango (Saguão e Biblioteca), 1 leque (Salão), 2 flor (Quartos).
uniform int wallpaper_motif : hint_range(0, 2) = 0;
group_uniforms;

group_uniforms aging;
// 0 = 1923, novo; 1 = 100 anos de abandono.
uniform float age : hint_range(0.0, 1.0) = 0.0;
uniform vec4 stain_color : source_color = vec4(0.18, 0.15, 0.1, 1.0);
uniform vec4 moss_color : source_color = vec4(0.22, 0.29, 0.16, 1.0);
uniform vec4 bare_color : source_color = vec4(0.55, 0.53, 0.48, 1.0);
group_uniforms;

group_uniforms detail;
// Liga a textura de detalhe. Modo 0: a textura vira a cor (tingida por detail_tint, que leva a
// média dela até a cor do papel); modo 1: só o brilho dela modula o padrão (mármore, metal).
uniform bool use_detail = false;
uniform int detail_mode : hint_range(0, 1) = 0;
uniform sampler2D detail_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D detail_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D detail_rough : hint_roughness_gray, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 detail_tint = vec3(1.0);
// Tamanho de uma repetição da textura, em metros.
uniform float detail_scale : hint_range(0.1, 8.0) = 1.0;
uniform float detail_normal_strength : hint_range(0.0, 2.0) = 1.0;
// Quanto a rugosidade da textura substitui a do papel.
uniform float detail_rough_mix : hint_range(0.0, 1.0) = 0.7;
group_uniforms;

group_uniforms retro;
uniform bool retro = false;
// Níveis por canal de cor no modo retrô.
uniform float retro_color_steps = 40.0;
// Grade de tela em que os vértices encaixam (0 = desliga). Desligado por padrão:
// em primeira pessoa o "tremido" fazia o cenário de 1923 piscar a cada passo.
uniform vec2 retro_snap_resolution = vec2(0.0, 0.0);
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

// Borda suave na largura de um pixel: degraus duros cintilam quando a câmera anda.
float soft_band(float x, float start, float end, float pixel) {
	return smoothstep(start - pixel, start + pixel, x) * (1.0 - smoothstep(end - pixel, end + pixel, x));
}

vec3 wallpaper(vec2 uv, float fade) {
	vec2 p = uv / pattern_scale;
	float pixel = fwidth(p.x);
	// Faixa larga, faixa estreita e filete fino, como um listrado art déco
	float band = fract(p.x);
	float wide = soft_band(band, 0.01, 0.47, pixel);
	float pin = soft_band(band, 0.625, 0.655, pixel);
	// Desenho discreto dentro da faixa larga, um por andar
	vec2 grid = vec2(p.x * 2.0, p.y * 2.4);
	vec2 cell = fract(grid) - 0.5;
	float motif_pixel = fwidth(grid.x) + fwidth(grid.y);
	float diamond = 0.0;
	if (wallpaper_motif == MOTIF_FAN) {
		// Leque art déco: meia-lua de cinco raios aberta para cima (v cresce para baixo)
		vec2 fan = cell - vec2(0.0, 0.3);
		float radius = length(fan);
		float turn = atan(-fan.y, fan.x) / PI * FAN_RAYS;
		float rays = soft_band(fract(turn), 0.22, 0.78, motif_pixel * FAN_RAYS / max(radius * PI, 0.05));
		diamond = rays * (1.0 - smoothstep(0.44 - motif_pixel, 0.44 + motif_pixel, radius))
			* smoothstep(0.1 - motif_pixel, 0.1 + motif_pixel, radius)
			* smoothstep(0.0, motif_pixel, -fan.y);
	} else if (wallpaper_motif == MOTIF_FLOWER) {
		// Flor de quatro pétalas com miolo vazado
		float radius = length(cell);
		float petal = 0.2 + 0.11 * cos(4.0 * atan(cell.y, cell.x));
		diamond = (1.0 - smoothstep(petal - motif_pixel, petal + motif_pixel, radius))
			* smoothstep(0.05 - motif_pixel, 0.05 + motif_pixel, radius);
	} else {
		diamond = 1.0 - smoothstep(0.29 - motif_pixel, 0.29 + motif_pixel, abs(cell.x) + abs(cell.y));
	}
	vec3 base = mix(color_b.rgb, color_a.rgb, wide);
	base = mix(base, color_c.rgb, pin * 0.85 * (1.0 - fade));
	base = mix(base, mix(base, color_c.rgb, 0.35), diamond * wide * 0.5 * (1.0 - fade));
	return base;
}

vec3 marble_tiles(vec2 uv, float fade, out float grout) {
	vec2 p = uv / pattern_scale;
	vec2 tile = floor(p);
	vec2 local = fract(p);
	// Xadrez filtrado (média exata do padrão dentro do pixel): sem serrilhado nas bordas
	vec2 pixel = fwidth(p) + 0.0001;
	vec2 integral = 2.0 * (abs(fract((p - 0.5 * pixel) * 0.5) - 0.5) - abs(fract((p + 0.5 * pixel) * 0.5) - 0.5)) / pixel;
	float checker = 0.5 - 0.5 * integral.x * integral.y;
	vec3 base = mix(color_a.rgb, color_b.rgb, checker);
	// Veios: senoide deformada por fbm, fina e clara
	float veins = abs(sin((p.x + p.y) * 2.2 + fbm(p * 1.7 + tile * 3.1 + seed) * 7.0));
	base = mix(base, mix(base, vec3(1.0), 0.35), (1.0 - smoothstep(0.0, 0.07, veins)) * 0.8 * (1.0 - fade));
	base *= mix(0.92 + 0.12 * fbm(p * 5.0 + seed), 0.98, fade);
	// Rejunte: faixa estreita nas bordas de cada ladrilho
	vec2 edge = min(local, 1.0 - local);
	float grout_pixel = max(pixel.x, pixel.y);
	grout = (1.0 - smoothstep(0.018 - grout_pixel, 0.018 + grout_pixel, min(edge.x, edge.y))) * (1.0 - fade);
	return mix(base, color_c.rgb, grout);
}

vec3 wood(vec2 uv, float fade) {
	vec2 p = uv / pattern_scale;
	// Tábuas na direção u, cada fileira deslocada
	float row = floor(p.y * 4.0);
	float plank_shift = hash12(vec2(row, seed)) * 3.0;
	float along = p.x + plank_shift;
	float grain = fract(p.y * 4.0 * 6.0 + fbm(vec2(along * 0.6, p.y * 14.0)) * 2.5);
	float ring = smoothstep(0.35, 0.5, grain) * (1.0 - smoothstep(0.5, 0.65, grain));
	vec3 base = mix(color_a.rgb, color_b.rgb, mix(ring * 0.7, 0.35, fade) + fbm(vec2(along * 2.0, row)) * 0.3);
	float seam_pixel = fwidth(p.y * 4.0);
	float seam = 1.0 - smoothstep(0.03 - seam_pixel, 0.03 + seam_pixel, min(fract(p.y * 4.0), 1.0 - fract(p.y * 4.0)));
	return mix(base, base * 0.45, seam * (1.0 - fade));
}

vec3 metal(vec2 uv, float fade) {
	vec2 p = uv / pattern_scale;
	float brushed = mix(value_noise(vec2(p.x * 40.0, p.y * 2.0)), 0.5, fade);
	return color_a.rgb * (0.85 + 0.25 * brushed);
}

vec3 rug(vec2 world_xz) {
	vec2 local = (world_xz - rug_center) / rug_half_size;
	vec2 border = abs(local);
	float box = max(border.x, border.y);
	float frame = soft_band(box, 0.86, 0.96, fwidth(box));
	float radius = length(local * vec2(1.0, rug_half_size.y / rug_half_size.x));
	float ring_pixel = fwidth(radius * 4.0);
	float rings = 1.0 - smoothstep(0.42 - ring_pixel, 0.42 + ring_pixel, abs(fract(radius * 4.0) - 0.5));
	float medallion = 1.0 - smoothstep(0.31 - fwidth(radius), 0.31 + fwidth(radius), radius);
	float sector = fract(atan(local.y, local.x) / 6.2832 * 12.0);
	float petals = soft_band(sector, 0.5, 1.0, 0.04) * medallion;
	vec3 base = color_a.rgb;
	base = mix(base, color_b.rgb, max(rings * (1.0 - medallion), petals));
	base = mix(base, color_c.rgb, frame);
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
	// Quanto do padrão cabe num pixel da tela. Longe, os detalhes finos (filetes, veios,
	// rejunte, blocos do modo retrô) ficam menores que um pixel e cintilam ao andar;
	// nesse caso o padrão se dissolve na cor média.
	float footprint = max(length(dFdx(uv)), length(dFdy(uv)));
	// Os traços finos medem ~3% da repetição: some quando ficam menores que um pixel
	float detail_fade = smoothstep(0.6, 1.6, footprint / (pattern_scale * 0.03));
	// O padrão em blocos (texels grandes sem filtro) foi retirado: em primeira pessoa
	// os blocos "nadavam" a cada movimento da câmera. 1923 fica retrô só pelas cores.

	vec3 albedo = color_a.rgb;
	float roughness = roughness_value;
	float metallic = metallic_value;
	float grout = 0.0;
	if (pattern == PATTERN_WALLPAPER) {
		albedo = wallpaper(uv, detail_fade);
	} else if (pattern == PATTERN_MARBLE_TILES) {
		albedo = marble_tiles(uv, detail_fade, grout);
		roughness = mix(roughness, 0.95, grout);
	} else if (pattern == PATTERN_WOOD) {
		albedo = wood(uv, detail_fade);
	} else if (pattern == PATTERN_METAL) {
		albedo = metal(uv, detail_fade);
	} else if (pattern == PATTERN_RUG) {
		albedo = rug(rug_xz);
	} else if (pattern == PATTERN_PLASTER) {
		albedo = plaster(uv);
	} else if (pattern == PATTERN_CLOTH) {
		albedo = cloth(uv);
	} else if (pattern == PATTERN_PAINTING) {
		albedo = painting(uv);
	}

	if (use_detail) {
		// Deslocamento por material, para peças vizinhas não repetirem a mesma emenda
		vec2 detail_uv = uv / detail_scale + vec2(seed * 0.137, seed * 0.071);
		vec3 sample_color = texture(detail_albedo, detail_uv).rgb;
		const vec3 LUMA = vec3(0.299, 0.587, 0.114);
		vec3 replaced = sample_color * detail_tint;
		vec3 modulated = albedo * dot(sample_color, LUMA) * detail_tint.r;
		albedo = detail_mode == 0 ? replaced : modulated;
		roughness = mix(roughness, texture(detail_rough, detail_uv).r, detail_rough_mix);
		// Tangentes do plano usado para projetar (o mesmo de planar_uv), no espaço da câmera
		vec3 axis = abs(world_normal);
		vec3 tangent = vec3(1.0, 0.0, 0.0);
		vec3 binormal = vec3(0.0, 0.0, 1.0);
		if (axis.y < axis.x || axis.y < axis.z) {
			tangent = axis.x >= axis.z ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
			binormal = vec3(0.0, -1.0, 0.0);
		}
		TANGENT = normalize((VIEW_MATRIX * vec4(tangent, 0.0)).xyz);
		BINORMAL = normalize((VIEW_MATRIX * vec4(binormal, 0.0)).xyz);
		NORMAL_MAP = texture(detail_normal, detail_uv).rgb;
		NORMAL_MAP_DEPTH = detail_normal_strength;
	}

	// Envelhecimento: tudo some sob camadas de pó, manchas, mofo e rachaduras.
	// Em 1923 (age = 0) o bloco inteiro é pulado: é a parte mais cara do shader.
	if (age > 0.0) {
	float dust = fbm(uv * 0.8 + seed + 3.7);
	float stains = smoothstep(0.55, 0.78, fbm(vec2(uv.x * 1.6, uv.y * 0.5) + seed * 1.3));
	float moss = smoothstep(0.62, 0.8, fbm(uv * 1.1 + seed + 11.0)) * (0.4 + 0.6 * grout);
	// Rachaduras só no que racha: reboco, azulejo e mármore inteiros, o papel de parede de
	// leve (é o reboco por baixo). Madeira, metal e pano não trincam. Finas e tortas; ao longe
	// o traço engrossa e clareia até sumir, em vez de cintilar.
	float crack_amount = (pattern == PATTERN_PLASTER || pattern == PATTERN_MARBLE_TILES) ? 1.0
		: (pattern == PATTERN_WALLPAPER ? 0.4 : 0.0);
	float crack_pixel = footprint * CRACK_CELLS;
	float crack_edge = voronoi_edge(uv * CRACK_CELLS + (dust - 0.5) * CRACK_WARP + seed);
	float cracks = (1.0 - smoothstep(0.0, CRACK_WIDTH + crack_pixel, crack_edge))
		* CRACK_WIDTH / (CRACK_WIDTH + crack_pixel);
	cracks *= smoothstep(0.5, 0.72, fbm(uv * 0.6 + seed + 5.0)) * crack_amount;
	vec3 aged = mix(albedo, vec3(dot(albedo, vec3(0.33))), 0.45) * (0.75 + 0.2 * dust);
	if (pattern == PATTERN_WALLPAPER) {
		// Papel rasgado mostrando o reboco por baixo
		float torn = smoothstep(0.60, 0.63, fbm(uv * 0.55 + seed + 21.0));
		aged = mix(aged, bare_color.rgb * (0.85 + 0.2 * dust), torn);
	}
	if (pattern == PATTERN_METAL) {
		aged = mix(aged, color_c.rgb, smoothstep(0.4, 0.75, fbm(uv * 3.0 + seed)));
	}
	if (pattern == PATTERN_WOOD) {
		// Madeira gasta: veios lavados e claros ao longo das tábuas, largos o bastante para
		// não cintilar
		float worn = smoothstep(0.55, 0.85, value_noise(vec2(uv.x * 1.5, uv.y * 22.0) + seed));
		aged = mix(aged, aged * 1.35 + 0.02, worn * 0.45);
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
