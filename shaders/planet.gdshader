shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;

uniform vec4 ocean_deep : source_color = vec4(0.05, 0.22, 0.48, 1.0);
uniform vec4 ocean_shallow : source_color = vec4(0.12, 0.48, 0.72, 1.0);
uniform vec4 land_low : source_color = vec4(0.24, 0.58, 0.28, 1.0);
uniform vec4 land_high : source_color = vec4(0.68, 0.58, 0.42, 1.0);
uniform vec4 cloud_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 atmo_color : source_color = vec4(0.4, 0.75, 1.0, 1.0);

uniform float rotation_speed = 0.02;
uniform float atmosphere_intensity = 1.4;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float smooth_noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm_planet(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 5; ++i) {
        v += a * smooth_noise(p);
        p = p * 2.1 + vec2(1.7, 3.2);
        a *= 0.5;
    }
    return v;
}

void fragment() {
    vec2 uv = UV;
    uv.x += TIME * rotation_speed;

    // Terrain generation
    float elevation = fbm_planet(uv * 6.0);
    vec3 surface;
    float roughness = 0.8;

    if (elevation < 0.48) {
        // Ocean gradient
        float depth = smoothstep(0.25, 0.48, elevation);
        surface = mix(ocean_deep.rgb, ocean_shallow.rgb, depth);
        roughness = 0.15; // Water shine
    } else {
        // Land gradient
        float height = smoothstep(0.48, 0.75, elevation);
        surface = mix(land_low.rgb, land_high.rgb, height);
        roughness = 0.75;
    }

    // Cloud layer
    vec2 cloud_uv = uv * 9.0 + vec2(TIME * rotation_speed * 1.5, 0.0);
    float cloud_val = fbm_planet(cloud_uv);
    float clouds = smoothstep(0.52, 0.72, cloud_val);
    surface = mix(surface, cloud_tint.rgb, clouds * 0.9);

    // Atmospheric limb glow
    float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
    vec3 atmosphere = atmo_color.rgb * fresnel * atmosphere_intensity;

    ALBEDO = surface;
    ROUGHNESS = roughness;
    EMISSION = atmosphere;
}