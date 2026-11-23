shader_type canvas_item;
// A soft diagonal glint that crosses the sprite as `progress` goes 0 -> 1, only over opaque pixels.
// At 0 and 1 nothing is drawn, so the script decides when each glint happens.

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float band_width = 0.18;
uniform float strength = 0.55;

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	float travel = mix(-band_width, 1.5 + band_width, progress);
	float diagonal = UV.x + UV.y * 0.5;
	float glint = smoothstep(band_width, 0.0, abs(diagonal - travel));
	COLOR = vec4(base.rgb + vec3(1.0, 0.95, 0.8) * glint * strength, base.a);
}
