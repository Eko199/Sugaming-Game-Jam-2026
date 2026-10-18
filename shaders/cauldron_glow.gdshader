shader_type canvas_item;
render_mode blend_add;

// Light welling up inside the cauldron. Drawn with the cauldron's opening mask as its
// texture, so the light never spills past the rim onto the outer walls.
uniform vec3 glow_color : source_color = vec3(1.0, 0.9, 0.6);
uniform float intensity : hint_range(0.0, 2.0) = 0.0;
uniform vec2 centre = vec2(0.5, 0.5);

void fragment() {
	float mask = texture(TEXTURE, UV).a;
	float d = length((UV - centre) * vec2(1.0, 1.9));
	float falloff = smoothstep(0.55, 0.0, d);
	float core = smoothstep(0.22, 0.0, d);
	vec3 light = glow_color * (falloff * 0.7 + core * 0.6);
	COLOR = vec4(light * intensity, mask);
}
