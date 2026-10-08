shader_type canvas_item;

uniform float circle_size : hint_range(0.0, 3.0) = 0.0;
uniform vec4 circle_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    // True screen aspect ratio: width / height
    float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
    
    // Anchor to bottom-left corner
    vec2 uv = UV - vec2(0.0, 1.0);
    
    // Scale X so 1 unit of X equals 1 unit of Y in physical pixels
    uv.x *= aspect;

    if (length(uv) < circle_size) {
        COLOR = circle_color;
    } else {
        COLOR = vec4(0.0);
    }
}