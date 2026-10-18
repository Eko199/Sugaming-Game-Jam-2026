shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

group_uniforms grade;
uniform vec3 shadow_tint : source_color = vec3(0.30, 0.22, 0.55);
uniform vec3 highlight_tint : source_color = vec3(1.0, 0.82, 0.55);
uniform float grade_strength : hint_range(0.0, 1.0) = 0.35;
uniform float saturation : hint_range(0.0, 2.0) = 1.12;
uniform float contrast : hint_range(0.5, 1.5) = 1.06;

group_uniforms bloom;
uniform float bloom_strength : hint_range(0.0, 2.0) = 0.5;
uniform float bloom_threshold : hint_range(0.0, 1.0) = 0.6;

group_uniforms light;
uniform float flicker_strength : hint_range(0.0, 0.3) = 0.05;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.55;
uniform vec3 vignette_color : source_color = vec3(0.05, 0.02, 0.12);

group_uniforms motes;
uniform float mote_strength : hint_range(0.0, 1.0) = 0.6;
uniform vec3 mote_color : source_color = vec3(0.75, 0.55, 1.0);

group_uniforms film;
uniform float grain_strength : hint_range(0.0, 0.2) = 0.035;
uniform float aberration : hint_range(0.0, 4.0) = 1.2;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float luma(vec3 c) {
	return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

float motes(vec2 uv, float aspect, float scale, float speed, float t) {
	vec2 p = vec2(uv.x * aspect, uv.y) * scale;
	p.y += t * speed;
	vec2 id = floor(p);
	vec2 f = fract(p) - 0.5;
	float h = hash21(id);
	vec2 off = vec2(hash21(id + 7.1), hash21(id + 13.7)) - 0.5;
	off *= 0.6;
	off.x += sin(t * (0.4 + h) + h * 6.283) * 0.15;
	float d = length(f - off);
	float size = mix(0.02, 0.06, hash21(id + 3.3));
	float twinkle = 0.5 + 0.5 * sin(t * (1.0 + h * 2.5) + h * 40.0);
	float m = smoothstep(size, 0.0, d) * twinkle;
	return m * step(0.55, h);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = SCREEN_PIXEL_SIZE;
	float aspect = 1.0 / (px.x / px.y);
	float t = TIME;
	vec2 centered = uv - 0.5;
	float r = length(centered * vec2(aspect, 1.0));

	vec2 ab = centered * aberration * px * (r * 2.0);
	vec3 col;
	col.r = texture(screen_texture, uv + ab).r;
	col.g = texture(screen_texture, uv).g;
	col.b = texture(screen_texture, uv - ab).b;

	vec3 glow = vec3(0.0);
	glow += textureLod(screen_texture, uv, 3.0).rgb;
	glow += textureLod(screen_texture, uv, 5.0).rgb * 1.2;
	glow += textureLod(screen_texture, uv, 7.0).rgb * 1.5;
	glow /= 3.7;
	glow = max(glow - vec3(bloom_threshold), vec3(0.0));
	col += glow * bloom_strength * 2.0;

	float l = luma(col);
	vec3 tone = mix(shadow_tint, highlight_tint, smoothstep(0.1, 0.8, l));
	col = mix(col, col * tone * 1.7, grade_strength);
	col = mix(vec3(luma(col)), col, saturation);
	col = (col - 0.5) * contrast + 0.5;

	float flick = sin(t * 7.3) * 0.5 + sin(t * 12.9 + 1.7) * 0.3 + sin(t * 3.1) * 0.2;
	col *= 1.0 + flick * flicker_strength * (1.0 - r * 0.8);

	float m = motes(uv, aspect, 14.0, 0.05, t) + 0.6 * motes(uv + 0.31, aspect, 26.0, 0.09, t);
	col += mote_color * m * mote_strength * (1.0 - smoothstep(0.5, 0.9, l));

	float vig = smoothstep(0.45, 1.1, r);
	col = mix(col, vignette_color, vig * vignette_strength);

	float g = hash21(uv * vec2(1920.0, 1080.0) + fract(t) * 100.0) - 0.5;
	col += g * grain_strength;

	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
