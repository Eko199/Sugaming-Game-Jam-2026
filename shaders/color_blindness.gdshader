shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 src = texture(screen_texture, SCREEN_UV);
	float gray = dot(src.rgb, vec3(0.2126, 0.7152, 0.0722));
	COLOR = vec4(mix(src.rgb, vec3(gray), intensity), src.a);
}
