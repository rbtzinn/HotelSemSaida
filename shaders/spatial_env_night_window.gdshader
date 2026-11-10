// Hotel Sem Saída — noite vista pelas janelas (Claude Code, 09/11/2026).
// Painel sem luz atrás dos vidros: degradê do pé ao alto e estrelas sorteadas por célula do
// plano da face (coordenadas do mundo, então painéis vizinhos continuam o mesmo céu).
// Alvo: Forward+ e Compatibility. Orçamento: 3 sorteios por pixel, sem texturas.
shader_type spatial;
render_mode unshaded, cull_back;

#include "res://shaders/noise.gdshaderinc"

uniform vec3 low_color : source_color = vec3(0.05, 0.065, 0.11);
uniform vec3 high_color : source_color = vec3(0.012, 0.018, 0.045);
// Altura (m) em que o céu chega à cor de cima.
uniform float gradient_height : hint_range(1.0, 20.0) = 7.0;
// Lado de uma célula de estrela, em metros.
uniform float star_cell : hint_range(0.05, 2.0) = 0.22;
uniform float star_amount : hint_range(0.0, 1.0) = 0.1;
uniform float star_energy : hint_range(0.0, 4.0) = 0.8;

// Raio de uma estrela dentro da célula; largo para não cintilar com a câmera.
const float STAR_RADIUS = 0.13;

varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	// Plano da face: paredes em zy ou xy
	vec2 uv = abs(world_normal.x) >= abs(world_normal.z) ? world_position.zy : world_position.xy;
	vec3 color = mix(low_color, high_color, clamp(world_position.y / gradient_height, 0.0, 1.0));
	vec2 grid = uv / star_cell;
	vec2 cell = floor(grid);
	vec2 center = 0.2 + 0.6 * hash22(cell);
	float star = (1.0 - smoothstep(0.0, STAR_RADIUS, length(fract(grid) - center)))
		* step(1.0 - star_amount, hash12(cell + 17.0));
	color += vec3(star * star_energy * (0.15 + 0.85 * pow(hash12(cell + 3.0), 2.0)));
	ALBEDO = color;
}
