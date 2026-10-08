shader_type canvas_item;

uniform sampler2D pattern: repeat_enable;

// Colors
uniform vec4 pattern_color: source_color = vec4(1.0);
uniform vec4 background_color: source_color = vec4(0.0, 0.0, 0.0, 1.0);

// Factor by which UVs are divided.
uniform float tiling = 100.0;
// How fast the background moves.
uniform vec2 speed = vec2(0.1, 0.5);
// Rotation of the base pattern in radians.
uniform float rotation: hint_range(-6.28318530717959, 6.28318530717959) = 0.0;

varying vec2 tiled_uv;

void vertex() {
    tiled_uv = VERTEX / tiling + TIME * speed;
    float c = cos(rotation);
    float s = sin(rotation);
    tiled_uv = mat2(vec2(c, -s), vec2(s, c)) * tiled_uv;
}

void fragment() {
    // Sample the brightness value
    float mask = texture(pattern, tiled_uv).r;

    // Blend from background_color to pattern_color
    COLOR = mix(background_color, pattern_color, mask);
}