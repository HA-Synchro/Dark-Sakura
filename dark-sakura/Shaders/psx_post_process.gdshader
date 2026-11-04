shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

group_uniforms Resolution;
uniform bool enable_pixelation = true;
uniform vec2 target_resolution = vec2(480.0, 270.0);

group_uniforms Dithering;
uniform bool enable_dither = true;
uniform float color_depth : hint_range(4.0, 64.0, 1.0) = 32.0;
uniform float dither_strength : hint_range(0.0, 2.0, 0.05) = 0.75;

group_uniforms DarkSakuraVignette;
uniform float vignette_intensity : hint_range(0.0, 1.0, 0.02) = 0.45;
uniform float vignette_softness : hint_range(0.1, 1.0, 0.05) = 0.55;
uniform vec4 vignette_color : source_color = vec4(0.11, 0.02, 0.07, 1.0);
uniform float chromatic_aberration : hint_range(0.0, 0.01, 0.0005) = 0.0018;

// 4x4 Ordered Bayer Dither Matrix
const float bayer_matrix[16] = float[16](
    0.0 / 16.0,  8.0 / 16.0,  2.0 / 16.0, 10.0 / 16.0,
   12.0 / 16.0,  4.0 / 16.0, 14.0 / 16.0,  6.0 / 16.0,
    3.0 / 16.0, 11.0 / 16.0,  1.0 / 16.0,  9.0 / 16.0,
   15.0 / 16.0,  7.0 / 16.0, 13.0 / 16.0,  5.0 / 16.0
);

void fragment() {
	vec2 uv = SCREEN_UV;
	
	// Pixelation grid calculation
	if (enable_pixelation && target_resolution.x > 0.0 && target_resolution.y > 0.0) {
		uv = floor(uv * target_resolution) / target_resolution;
	}
	
	// Chromatic Aberration around edges
	vec2 uv_center_offset = uv - vec2(0.5);
	float dist_from_center = length(uv_center_offset);
	vec2 ca_dir = normalize(uv_center_offset + vec2(0.0001));
	vec2 ca_offset = ca_dir * (dist_from_center * chromatic_aberration);
	
	float r = texture(screen_texture, uv - ca_offset).r;
	float g = texture(screen_texture, uv).g;
	float b = texture(screen_texture, uv + ca_offset).b;
	vec3 col = vec3(r, g, b);
	
	// PSX Ordered Bayer Dithering
	if (enable_dither) {
		vec2 dither_coord = enable_pixelation ? (uv * target_resolution) : FRAGCOORD.xy;
		int x = int(floor(dither_coord.x)) % 4;
		int y = int(floor(dither_coord.y)) % 4;
		float dither_val = (bayer_matrix[y * 4 + x] - 0.5) * (dither_strength / color_depth);
		col += vec3(dither_val);
	}
	
	// Color Quantization (simulate 15-bit RGB palette)
	col = floor(col * color_depth) / color_depth;
	
	// Dark Sakura Corner Vignette
	float vignette = smoothstep(vignette_softness, vignette_softness + (1.0 - vignette_intensity), dist_from_center);
	col = mix(col, vignette_color.rgb, vignette * vignette_intensity);
	
	COLOR = vec4(col, 1.0);
}
