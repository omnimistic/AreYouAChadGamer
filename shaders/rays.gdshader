shader_type canvas_item;

uniform vec4 ray_color_core : source_color = vec4(0.0, 0.95, 1.0, 0.9);   // Core glow
uniform vec4 ray_color_outer : source_color = vec4(1.0, 0.16, 0.43, 0.35); // Edge beam color
uniform vec4 bg_color : source_color = vec4(0.04, 0.05, 0.08, 1.0);        // Deep void background

uniform float num_rays = 12.0;
uniform float rotation_speed = 0.55;
uniform float ray_sharpness = 2.2;
uniform float pulse_speed = 2.0;

void fragment() {
    vec2 center = vec2(0.5);
    vec2 uv = UV - center;
    float dist = length(uv);

    // Angle of ray around origin
    float angle = atan(uv.y, uv.x);

    // Rotating beams
    float ray_pattern = sin(angle * num_rays + TIME * rotation_speed);
    ray_pattern = pow(max(0.0, (ray_pattern + 1.0) * 0.5), ray_sharpness);

    // Radial falloff and breathing pulse
    float radial_glow = 1.0 - smoothstep(0.0, 0.55, dist);
    float pulse = 0.88 + 0.12 * sin(TIME * pulse_speed);

    vec4 beam_col = mix(ray_color_core, ray_color_outer, dist * 1.8);
    vec3 final_rgb = mix(bg_color.rgb, beam_col.rgb, ray_pattern * radial_glow * pulse * beam_col.a);

    COLOR = vec4(final_rgb, 1.0);
}