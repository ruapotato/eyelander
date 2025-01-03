shader_type spatial;

uniform sampler2DArray u_texture_array : source_color;

varying vec3 v_normal;
varying vec3 v_pos;

// Biome parameters
uniform float outer_rim_start = 500.0;
uniform float outer_rim_blend = 100.0;
uniform float ocean_ring_start = 300.0;
uniform float ocean_ring_blend = 50.0;
uniform float desert_center_radius = 100.0;
uniform float desert_blend = 50.0;

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

vec3 calculate_biome(vec3 world_pos) {
    float dist = length(world_pos.xz);

    float outer = smoothstep(outer_rim_start, outer_rim_start + outer_rim_blend, dist);
    float ocean = smoothstep(ocean_ring_start, ocean_ring_start + ocean_ring_blend, dist) * (1.0 - outer);
    float desert = 1.0 - smoothstep(desert_center_radius, desert_center_radius + desert_blend, dist);

    vec3 color = mix(vec3(1.0), midnight_color, outer);
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
    vec4 tex = triplanar_texture(u_texture_array, v_pos, world_normal, 0.0);
    vec3 biome = calculate_biome(v_pos);

    ALBEDO = tex.rgb * biome;
    ROUGHNESS = 0.7;
    SPECULAR = 0.3;
}