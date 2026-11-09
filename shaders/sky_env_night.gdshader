// Hotel Sem Saída — céu da noite visto do telhado e das janelas (Claude Code, 09/11/2026).
// Degradê do horizonte ao zênite, estrelas sorteadas por célula de direção e a lua com halo.
// A lua fica na direção do facho de luar da Torre (`moon_direction` aponta para ela).
// Alvo: Forward+ e Compatibility. Orçamento: 2 sorteios por pixel, sem texturas.
shader_type sky;

#include "res://shaders/noise.gdshaderinc"

group_uniforms colors;
uniform vec3 zenith_color : source_color = vec3(0.012, 0.018, 0.045);
uniform vec3 horizon_color : source_color = vec3(0.05, 0.065, 0.11);
uniform vec3 moon_color : source_color = vec3(0.85, 0.88, 0.95);
group_uniforms;

group_uniforms moon;
uniform vec3 moon_direction = vec3(-0.48, 0.48, -0.74);
// Raio aparente da lua, em radianos.
uniform float moon_radius : hint_range(0.005, 0.2) = 0.035;
uniform float moon_energy : hint_range(0.0, 8.0) = 1.6;
uniform float halo_energy : hint_range(0.0, 2.0) = 0.25;
group_uniforms;

group_uniforms stars;
// Células por radiano: quanto maior, mais estrelas e menores.
uniform float star_cells : hint_range(10.0, 120.0) = 42.0;
// Fração das células que tem estrela.
uniform float star_amount : hint_range(0.0, 1.0) = 0.09;
uniform float star_energy : hint_range(0.0, 4.0) = 0.9;
group_uniforms;

// Raio de uma estrela dentro da célula; largo o bastante para não cintilar com a câmera.
const float STAR_RADIUS = 0.11;
// Quão concentrado é o halo da lua.
const float HALO_POWER = 90.0;

void sky() {
	vec3 direction = normalize(EYEDIR);
	float height = clamp(direction.y, 0.0, 1.0);
	vec3 color = mix(horizon_color, zenith_color, pow(height, 0.45));

	// Estrelas: uma por célula sorteada, em longitude e latitude
	vec2 sphere = vec2(atan(direction.x, direction.z), asin(clamp(direction.y, -1.0, 1.0))) * star_cells;
	vec2 cell = floor(sphere);
	vec2 center = 0.2 + 0.6 * hash22(cell);
	float present_star = step(1.0 - star_amount, hash12(cell + 17.0));
	float star = (1.0 - smoothstep(0.0, STAR_RADIUS, length(fract(sphere) - center))) * present_star;
	// Somem perto do horizonte, onde a bruma da cidade as apaga
	color += vec3(star * star_energy * (0.15 + 0.85 * pow(hash12(cell + 3.0), 2.0))) * smoothstep(0.04, 0.3, height);

	float toward_moon = dot(direction, normalize(moon_direction));
	float disc = smoothstep(cos(moon_radius), cos(moon_radius * 0.9), toward_moon);
	color += moon_color * (disc * moon_energy + pow(max(toward_moon, 0.0), HALO_POWER) * halo_energy);

	// Abaixo do horizonte, só o escuro
	COLOR = color * smoothstep(-0.08, 0.0, direction.y);
}
