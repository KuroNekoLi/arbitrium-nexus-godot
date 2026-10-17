shader_type canvas_item;
render_mode unshaded;

// Rotate in the ground plane's UV space, keeping its screen-space ellipse flat.
uniform float angle = 0.0;
varying vec4 sprite_tint;

void vertex() {
	sprite_tint = COLOR;
}

void fragment() {
	float c = cos(angle);
	float s = sin(angle);
	// sqrt(2) padding contains the complete image at diagonal angles.
	vec2 p = (UV - vec2(0.5)) * 1.45;
	vec2 sample_uv = vec2(c * p.x + s * p.y, -s * p.x + c * p.y) + vec2(0.5);
	vec4 tex = vec4(0.0);
	if (all(greaterThanEqual(sample_uv, vec2(0.0))) && all(lessThanEqual(sample_uv, vec2(1.0)))) {
		// Use the lower, ground-ring portion of the supplied illustration.
		tex = texture(TEXTURE, vec2(sample_uv.x, 0.5 + sample_uv.y * 0.5));
		tex.a *= smoothstep(0.0, 0.1, sample_uv.y);
	}
	COLOR = tex * sprite_tint;
}
