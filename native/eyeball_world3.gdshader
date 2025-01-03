shader_type spatial;

uniform sampler2D u_noise : source_color;
varying vec3 v_normal;
varying vec3 v_pos;

// Biome parameters
uniform float outer_rim_start = 500.0;
uniform float outer_rim_blend = 100.0;
uniform float ocean_ring_start = 300.0;
uniform float ocean_ring_blend = 50.0;
uniform float desert_center_radius = 100.0;
uniform float desert_blend = 50.0;

// Base colors for each biome
const vec3 DESERT_COLOR = vec3(0.9, 0.75, 0.35);    // Warm sand color
const vec3 OCEAN_COLOR = vec3(0.1, 0.2, 0.8);       // Deep blue
const vec3 NIGHT_COLOR = vec3(0.05, 0.2, 0.05);     // Dark green

// Material parameters
uniform float noise_scale = 20.0;

float get_slope_factor(vec3 normal) {
    // Exact same slope calculation as the example
    float raw_slope = abs(dot(normalize(normal), vec3(0.0, 1.0, 0.0)));
    return 1.0 - raw_slope; // Returns 0 for flat, 1 for vertical
}

vec3 get_slope_color(vec3 base_color, float slope) {
    // Direct color inversion for slopes
    return mix(base_color, vec3(1.0) - base_color, slope);
}

vec3 calculate_biome(vec3 world_pos, vec3 normal) {
    float dist = length(world_pos.xz);
    vec2 noise_uv = world_pos.xz / noise_scale;
    float noise = texture(u_noise, noise_uv).r;

    // Get the slope factor
    float slope = get_slope_factor(normal);

    // Calculate biome weights
    float outer = smoothstep(outer_rim_start, outer_rim_start + outer_rim_blend, dist);
    float ocean = smoothstep(ocean_ring_start, ocean_ring_start + ocean_ring_blend, dist) * (1.0 - outer);
    float desert = 1.0 - smoothstep(desert_center_radius, desert_center_radius + desert_blend, dist);

    // Get the inverted colors for slopes for each biome
    vec3 desert_terrain = get_slope_color(DESERT_COLOR, slope);
    vec3 night_terrain = get_slope_color(NIGHT_COLOR, slope);
    vec3 ocean_terrain = OCEAN_COLOR; // Ocean doesn't get inverted

    // Blend between biomes
    vec3 color = desert_terrain;
    color = mix(color, ocean_terrain, ocean);
    color = mix(color, night_terrain, outer);

    return color;
}

void vertex() {
    v_normal = NORMAL;
    v_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    vec3 world_normal = normalize((MODEL_MATRIX * vec4(v_normal, 0.0)).xyz);
    vec3 biome = calculate_biome(v_pos, world_normal);

    ALBEDO = biome;
    ROUGHNESS = 0.8; // Consistent roughness
    SPECULAR = 0.2; // Low specular to make colors more visible
}