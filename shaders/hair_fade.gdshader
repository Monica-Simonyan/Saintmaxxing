shader_type canvas_item;

// Fades the left part of the sprite toward transparent; strength 0 = solid.
uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform float fade_width : hint_range(0.05, 1.0) = 0.4;
uniform float min_alpha : hint_range(0.0, 1.0) = 0.35;

void fragment() {
	float edge = smoothstep(0.0, fade_width, UV.x);
	float alpha = mix(1.0, mix(min_alpha, 1.0, edge), strength);
	COLOR.a *= alpha;
}
