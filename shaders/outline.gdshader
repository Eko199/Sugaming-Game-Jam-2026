shader_type canvas_item;

// The color you want the non-transparent parts to become
uniform vec4 target_color : source_color = vec4(0.8, 0.6, 0.4, 1.0);

void fragment() {
    // Sample the current pixel's color and alpha from the TextureRect
    vec4 tex_color = texture(TEXTURE, UV);
    
    // Replace RGB with target color, multiplying alpha so soft/feathered edges stay smooth
    COLOR = vec4(target_color.rgb, tex_color.a * target_color.a);
}