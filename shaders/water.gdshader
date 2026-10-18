shader_type canvas_item;

const int MAX_RIPPLES = 8;
const int MAX_TRAILS = 24;
const int MAX_BUBBLES = 16;

uniform vec4 water_color : source_color = vec4(0.40, 0.62, 0.85, 1.0);
uniform float aspect = 1.5;
uniform float heat : hint_range(0.0, 1.0) = 0.5;
uniform vec3 light_tint : source_color = vec3(0.90, 0.94, 1.0);
uniform vec4 ripples[MAX_RIPPLES];
uniform vec4 trails[MAX_TRAILS];
uniform float trail_ages[MAX_TRAILS];
// Bubbles: xy = centre in UV, z = age as 0..1 fraction of its life (< 0 inactive), w = size
uniform vec4 bubbles[MAX_BUBBLES];

const float TRAIL_LIFE = 1.4;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

vec2 squash(vec2 uv) {
	return vec2(uv.x * aspect, uv.y * aspect * 1.6);
}

vec2 seg(vec2 p, vec2 a, vec2 b) {
	vec2 ab = b - a;
	float h = clamp(dot(p - a, ab) / max(dot(ab, ab), 0.00001), 0.0, 1.0);
	return vec2(length(p - a - ab * h), h);
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * (0.5 + heat * 0.6);
	vec2 p = squash(uv);
	p += vec2(sin(p.y * 13.0 + t * 0.5), cos(p.x * 11.0 - t * 0.4)) * 0.005;

	vec3 base = mix(water_color.rgb, vec3(dot(water_color.rgb, vec3(0.33))), 0.18);
	vec3 col = base * mix(0.74, 1.04, smoothstep(0.0, 1.0, uv.y));

	vec2 gp = vec2(p.x * 7.0 + t * 0.25, p.y * 9.0 - t * 0.12);
	vec2 id = floor(gp);
	vec2 f = fract(gp);
	float h = hash21(id);
	float dash_y = 0.25 + 0.5 * hash21(id + 4.1) + sin(f.x * 6.0 + h * 6.0) * 0.06;
	float len = 0.25 + 0.35 * hash21(id + 9.3);
	float x0 = hash21(id + 1.7) * (1.0 - len);
	float in_x = step(x0, f.x) * step(f.x, x0 + len);
	float taper = sin(clamp((f.x - x0) / len, 0.0, 1.0) * 3.14159);
	float dash = smoothstep(0.07 * taper, 0.03 * taper, abs(f.y - dash_y)) * in_x * step(0.58, h);
	col = mix(col, light_tint, dash * 0.32);

	vec2 g = (uv - vec2(0.3, 0.4)) * vec2(aspect, aspect * 1.6);
	g.y += sin(t * 1.3) * 0.01;
	col = mix(col, light_tint, smoothstep(0.1, 0.0, length(g * vec2(1.0, 2.2))) * 0.28);

	vec2 e = (uv - 0.5) * 2.0;
	col *= 1.0 - smoothstep(0.7, 1.0, length(e * vec2(0.9, 1.2))) * 0.3;

	float ring = 0.0;
	for (int i = 0; i < MAX_RIPPLES; i++) {
		vec4 r = ripples[i];
		if (r.z < 0.0) continue;
		float d = length(p - squash(r.xy));
		float front = 0.04 + r.z * 0.4;
		float life = clamp(1.0 - r.z / 1.5, 0.0, 1.0) * r.w;
		ring = max(ring, smoothstep(0.014, 0.006, abs(d - front)) * life);
		ring = max(ring, smoothstep(0.01, 0.004, abs(d - front * 0.62)) * life * 0.5);
		col *= 1.0 - smoothstep(0.1, 0.0, d) * clamp(1.0 - r.z * 3.0, 0.0, 1.0) * 0.12 * r.w;
	}
	col = mix(col, light_tint, ring * 0.7);

	float streak = 0.0;
	for (int i = 0; i < MAX_TRAILS; i++) {
		float age = trail_ages[i];
		if (age < 0.0) continue;
		vec4 s = trails[i];
		vec2 a = squash(s.xy);
		vec2 b = squash(s.zw);
		vec2 dir = normalize(b - a + 0.00001);
		vec2 nrm = vec2(-dir.y, dir.x);
		float spread = 0.018 + age * 0.025;
		vec2 along = seg(p, a, b);
		float side = dot(p - mix(a, b, along.y), nrm);
		float life = clamp(1.0 - age / TRAIL_LIFE, 0.0, 1.0);
		float thin = 0.007 * (0.4 + 0.6 * life);
		float line = smoothstep(thin, thin * 0.4, abs(abs(side) - spread)) * step(along.x, spread + thin * 2.0);
		streak = max(streak, line * life * (0.6 + 0.4 * along.y));
	}
	col = mix(col, light_tint, streak * 0.75);

	// Bubbles: a small thin-lined circle swells up, then pops into a quick fading ring.
	float bub = 0.0;
	float bub_fill = 0.0;
	for (int i = 0; i < MAX_BUBBLES; i++) {
		vec4 b = bubbles[i];
		if (b.z < 0.0) continue;
		vec2 d2 = (p - squash(b.xy)) * vec2(1.0, 1.5); // flatter than ring ripples
		float d = length(d2);
		float grow = smoothstep(0.0, 0.7, b.z);
		float pop = smoothstep(0.7, 1.0, b.z);
		float radius = b.w * (0.35 + 0.65 * grow) + pop * b.w * 0.8;
		float alpha = 1.0 - pop;
		float line = smoothstep(0.006, 0.002, abs(d - radius));
		bub = max(bub, line * (0.4 + 0.6 * alpha));
		// soft fill and a tiny highlight while it is still whole
		bub_fill = max(bub_fill, smoothstep(radius, 0.0, d) * 0.18 * alpha);
		vec2 hl = d2 - vec2(-radius * 0.35, -radius * 0.35);
		bub = max(bub, smoothstep(radius * 0.22, radius * 0.1, length(hl)) * alpha * 0.9);
	}
	col = mix(col, light_tint, bub_fill);
	col = mix(col, light_tint, bub * 0.8);

	COLOR = vec4(col, texture(TEXTURE, UV).a * water_color.a);
}
