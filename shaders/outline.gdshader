shader_type canvas_item;

// Draws a real outline around the opaque parts of the texture.
// Use on a child TextureRect that overlays its parent exactly (same texture,
// same expand/stretch mode, zero offsets) with show_behind_parent enabled.
// The quad is grown outward so the outline is never clipped by the rect.

uniform vec4 outline_color : source_color = vec4(1.0);
// Outline thickness in the node's local pixels.
uniform float outline_width : hint_range(0.0, 32.0) = 6.0;
// Alpha above which a texel counts as part of the shape.
uniform float alpha_threshold : hint_range(0.0, 1.0) = 0.1;

const int ANGLES = 24;
const int RINGS = 3;

varying vec2 local_pos;

void vertex() {
	// Corners have UV 0 or 1: push each one outward by the padding.
	VERTEX += (UV * 2.0 - 1.0) * (outline_width + 2.0);
	local_pos = VERTEX;
}

void fragment() {
	float pad = outline_width + 2.0;

	// Recover the original rect size from how fast UV changes per local pixel.
	vec2 duv_x = dFdx(UV);
	vec2 duv_y = dFdy(UV);
	vec2 dp_x = dFdx(local_pos);
	vec2 dp_y = dFdy(local_pos);
	vec2 per_px = (duv_x * dp_x + duv_y * dp_y) / max(dp_x * dp_x + dp_y * dp_y, vec2(1e-12));
	vec2 grown_size = 1.0 / per_px;
	vec2 rect_size = max(grown_size - 2.0 * pad, vec2(1.0));
	vec2 uv = (UV * grown_size - pad) / rect_size;
	vec2 px = 1.0 / rect_size;

	float a = 0.0;
	if (all(greaterThanEqual(uv, vec2(0.0))) && all(lessThanEqual(uv, vec2(1.0)))) {
		a = textureLod(TEXTURE, uv, 0.0).a;
	}
	for (int r = 1; r <= RINGS; r++) {
		float radius = outline_width * float(r) / float(RINGS);
		for (int i = 0; i < ANGLES; i++) {
			float ang = TAU * float(i) / float(ANGLES);
			vec2 s = uv + vec2(cos(ang), sin(ang)) * radius * px;
			if (all(greaterThanEqual(s, vec2(0.0))) && all(lessThanEqual(s, vec2(1.0)))) {
				a = max(a, textureLod(TEXTURE, s, 0.0).a);
			}
		}
	}

	// Soft edge around the threshold keeps the outline anti-aliased.
	a = smoothstep(alpha_threshold * 0.5, alpha_threshold * 1.5, a);
	COLOR = vec4(outline_color.rgb, outline_color.a * a);
}
