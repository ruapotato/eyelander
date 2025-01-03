shader_type spatial;

uniform sampler2DArray u_texture_array : source_color;
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

// Material parameters - Adjusted for more obvious slope transitions
uniform float slope_threshold = 0.4;  // Lower threshold to catch more slopes
uniform float slope_smoothness = 0.05; // Sharper transition
uniform float noise_scale = 20.0;
uniform float noise_influence = 0.1;  // Reduced noise influence

// Texture array layers
const float GRASS_FLAT_LAYER = 0.0;
const float GRASS_STEEP_LAYER = 1.0;
const float DESERT_FLAT_LAYER = 2.0;
const float DESERT_STEEP_LAYER = 3.0;
const float ROCK_FLAT_LAYER = 4.0;
const float ROCK_STEEP_LAYER = 5.0;

uniform vec3 midnight_color : source_color = vec3(0.05, 0.05, 0.08);
uniform vec3 ocean_deep_color : source_color = vec3(0.05, 0.15, 0.3);
uniform vec3 ocean_shallow_color : source_color = vec3(0.2, 0.5, 0.7);
uniform vec3 beach_color : source_color = vec3(0.76, 0.7, 0.5);
uniform vec3 desert_color : source_color = vec3(0.8, 0.6, 0.3);

vec4 triplanar_texture(sampler2DArray tex, vec3 world_pos, vec3 normal, float layer) {
    vec3 blend = abs(normal);
    blend = blend / (blend.x + blend.y + blend.z);

    vec4 tx = texture(tex, vec3(world_pos.yz * 0.2, layer));
    vec4 ty = texture(tex, vec3(world_pos.xz * 0.2, layer));
    vec4 tz = texture(tex, vec3(world_pos.xy * 0.2, layer));

    return tx * blend.x + ty * blend.y + tz * blend.z;
}

float get_slope_factor(vec3 normal, float noise) {
    // Calculate slope using world up vector
    float slope = 1.0 - abs(dot(normalize(normal), vec3(0.0, 1.0, 0.0)));
    float threshold = slope_threshold + noise * noise_influence;

    // More dramatic slope transition
    return smoothstep(threshold - slope_smoothness, threshold + slope_smoothness, slope);
}

vec4 get_biome_texture(vec3 world_pos, vec3 normal, float slope_factor, float desert_factor, float outer_blend) {
    // Debug: Output slope factor directly to see the transitions
    // return vec4(vec3(slope_factor), 1.0);

    // Get grass textures and blend
    vec4 grass_flat = triplanar_texture(u_texture_array, world_pos, normal, GRASS_FLAT_LAYER);
    vec4 grass_steep = triplanar_texture(u_texture_array, world_pos, normal, GRASS_STEEP_LAYER);
    vec4 grass_blend = mix(grass_flat, grass_steep, slope_factor);

    // Get desert textures and blend
    vec4 desert_flat = triplanar_texture(u_texture_array, world_pos, normal, DESERT_FLAT_LAYER);
    vec4 desert_steep = triplanar_texture(u_texture_array, world_pos, normal, DESERT_STEEP_LAYER);
    vec4 desert_slope_blend = mix(desert_flat, desert_steep, slope_factor);

    // Get rock textures and blend
    vec4 rock_flat = triplanar_texture(u_texture_array, world_pos, normal, ROCK_FLAT_LAYER);
    vec4 rock_steep = triplanar_texture(u_texture_array, world_pos, normal, ROCK_STEEP_LAYER);
    vec4 rock_blend = mix(rock_flat, rock_steep, slope_factor);

    // Blend between biomes
    vec4 grass_desert = mix(grass_blend, desert_slope_blend, desert_factor);
    vec4 final_blend = mix(grass_desert, rock_blend, outer_blend);

    return final_blend;
}

vec3 calculate_biome(vec3 world_pos, vec3 normal) {
    float dist = length(world_pos.xz);
    vec2 noise_uv = world_pos.xz / noise_scale;
    float noise = texture(u_noise, noise_uv).r;
    float slope = get_slope_factor(normal, noise);

    float outer = smoothstep(outer_rim_start, outer_rim_start + outer_rim_blend, dist);
    float ocean = smoothstep(ocean_ring_start, ocean_ring_start + ocean_ring_blend, dist) * (1.0 - outer);
    float desert = 1.0 - smoothstep(desert_center_radius, desert_center_radius + desert_blend, dist);

    // Get biome textures with proper blending
    vec4 biome_tex = get_biome_texture(world_pos, normal, slope, desert, outer);

    // Apply biome tinting
    vec3 color = biome_tex.rgb;
    color = mix(color, midnight_color, outer);
    color = mix(color, ocean_deep_color, ocean);
    color = mix(color, desert_color, desert);

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
    ROUGHNESS = 0.7;
    SPECULAR = 0.3;
}