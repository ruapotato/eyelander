shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx,skip_vertex_transform;

// Private uniforms
uniform float _region_size = 1024.0;
uniform float _region_texel_size = 0.0009765625;
uniform float _vertex_spacing = 1.0;
uniform float _vertex_density = 1.0;
uniform int _region_map_size = 32;
uniform int _region_map[1024];
uniform vec2 _region_locations[1024];
uniform highp sampler2DArray _height_maps : repeat_disable;
uniform highp usampler2DArray _control_maps : repeat_disable;
uniform highp sampler2DArray _color_maps : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform highp sampler2DArray _texture_array_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform highp sampler2DArray _texture_array_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform highp sampler2D noise_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;

uniform float _texture_uv_scale_array[32];
uniform float _texture_detile_array[32];
uniform vec4 _texture_color_array[32];
uniform uint _background_mode = 1u;
uniform uint _mouse_layer = 0x80000000u;

// Biome boundaries
uniform float outer_rim_start = 8000.0;
uniform float outer_rim_blend = 1000.0;
uniform float ocean_ring_start = 4000.0;
uniform float ocean_ring_blend = 1000.0;
uniform float desert_center_radius = 2000.0;
uniform float desert_blend = 500.0;

// Base height settings
uniform float base_height = 1.0;
uniform float height_falloff = 0.5;

// Biome colors
uniform vec3 midnight_color : source_color = vec3(0.05, 0.05, 0.08);
uniform vec3 ocean_deep_color : source_color = vec3(0.05, 0.15, 0.3);
uniform vec3 ocean_shallow_color : source_color = vec3(0.2, 0.5, 0.7);
uniform vec3 beach_color : source_color = vec3(0.76, 0.7, 0.5);
uniform vec3 desert_color : source_color = vec3(0.8, 0.6, 0.3);

// Biome-specific noise settings
uniform float desert_noise_scale = 1.0;
uniform float desert_noise_height = 1.0;
uniform float desert_octaves = 4.0;

uniform float ocean_noise_scale = 1.0;
uniform float ocean_noise_height = 1.0;
uniform float ocean_octaves = 3.0;

uniform float midnight_noise_scale = 1.0;
uniform float midnight_noise_height = 1.0;
uniform float midnight_octaves = 2.0;

// Biome material settings
uniform float midnight_roughness_mod = 0.2;
uniform float midnight_specular_mod = -0.1;
uniform float ocean_roughness_mod = -0.3;
uniform float ocean_specular_mod = 0.2;
uniform float beach_roughness_mod = 0.1;
uniform float beach_specular_mod = -0.1;
uniform float desert_roughness_mod = 0.3;
uniform float desert_specular_mod = -0.2;

// World noise settings
uniform float world_noise_region_blend = 0.33;
uniform float world_noise_lod_distance = 7500.0;
uniform vec3 world_noise_offset = vec3(0.0);

// Original public uniforms
uniform float vertex_normals_distance = 128.0;
uniform bool height_blending = true;
uniform float blend_sharpness = 0.87;
uniform float auto_slope = 1.0;
uniform float auto_height_reduction = 0.1;
uniform int auto_base_texture = 0;
uniform int auto_overlay_texture = 1;
uniform int dual_scale_texture = 0;
uniform float dual_scale_reduction = 0.3;
uniform float tri_scale_reduction = 0.3;
uniform float dual_scale_far = 170.0;
uniform float dual_scale_near = 100.0;
uniform vec3 macro_variation1 = vec3(1.0);
uniform vec3 macro_variation2 = vec3(1.0);
uniform float noise1_scale = 0.04;
uniform float noise1_angle = 0.0;
uniform vec2 noise1_offset = vec2(0.5);
uniform float noise2_scale = 0.076;
uniform float noise3_scale = 0.225;

// Structs
struct Material {
    vec4 alb_ht;
    vec4 nrm_rg;
    int base;
    int over;
    float blend;
};

struct BiomeColors {
    vec3 albedo_tint;
    float roughness_mod;
    float specular_mod;
    float noise_scale;
    float noise_height;
    float octaves;
};

struct BiomeData {
    float factor;
    float noise_scale;
    float noise_height;
    float octaves;
    float roughness_mod;
    float specular_mod;
    vec3 color;
};

// Varyings
varying flat vec3 v_vertex;
varying flat vec3 v_camera_pos;
varying float v_vertex_xz_dist;
varying flat ivec3 v_region;
varying flat vec2 v_uv_offset;
varying flat vec2 v_uv2_offset;
varying vec3 v_normal;
varying float v_region_border_mask;

// Helper functions
ivec3 get_region_uv(const vec2 uv) {
    ivec2 pos = ivec2(floor(uv * _region_texel_size)) + (_region_map_size / 2);
    int bounds = int(uint(pos.x | pos.y) < uint(_region_map_size));
    int layer_index = _region_map[ pos.y * _region_map_size + pos.x ] * bounds - 1;
    return ivec3(ivec2(mod(uv,_region_size)), layer_index);
}

vec3 get_region_uv2(const vec2 uv2) {
    ivec2 pos = ivec2(floor(uv2 - vec2(_region_texel_size * 0.5))) + (_region_map_size / 2);
    int bounds = int(uint(pos.x | pos.y) < uint(_region_map_size));
    int layer_index = _region_map[ pos.y * _region_map_size + pos.x ] * bounds - 1;
    return vec3(uv2 - _region_locations[layer_index], float(layer_index));
}

float check_region(const vec2 uv2) {
    ivec2 pos = ivec2(floor(uv2)) + (_region_map_size / 2);
    int layer_index = 0;
    if (uint(pos.x | pos.y) < uint(_region_map_size)) {
        layer_index = clamp(_region_map[ pos.y * _region_map_size + pos.x ] - 1, -1, 0) + 1;
    }
    return float(layer_index);
}

float region_blend(vec2 uv2) {
    uv2 -= 0.5;
    const vec2 offset = vec2(0.0,1.0);
    float a = check_region(uv2 + offset.xy);
    float b = check_region(uv2 + offset.yy);
    float c = check_region(uv2 + offset.yx);
    float d = check_region(uv2 + offset.xx);
    vec2 w = smoothstep(vec2(0.0), vec2(1.0), fract(uv2));
    float blend = mix(mix(d, c, w.x), mix(a, b, w.x), w.y);
    return 1.0 - blend;
}

float hashf(float f) {
    return fract(sin(f) * 1e4);
}

float hashv2(vec2 v) {
    return fract(1e4 * sin(fma(17.0, v.x, v.y * 0.1)) *
           (0.1 + abs(sin(fma(v.y, 13.0, v.x)))));
}

vec3 noise2D(vec2 x) {
    vec2 f = fract(x);
    vec2 u = f*f*f*(f*(f*6.0-15.0)+10.0);
    vec2 du = 30.0*f*f*(f*(f-2.0)+1.0);

    vec2 p = floor(x);

    float a = hashv2(p+vec2(0,0));
    float b = hashv2(p+vec2(1,0));
    float c = hashv2(p+vec2(0,1));
    float d = hashv2(p+vec2(1,1));

    float k0 = a;
    float k1 = b - a;
    float k2 = c - a;
    float k3 = a - b - c + d;

    return vec3(k0 + k1*u.x + k2*u.y + k3*u.x*u.y,
                du*(vec2(k1,k2) + k3*u.yx));
}

BiomeColors calculate_biome(vec3 world_pos) {
    float dist_from_center = length(world_pos.xz);
    float height_factor = max(0.0, 1.0 - (dist_from_center / outer_rim_start));
    float base_terrain_height = base_height * height_factor * height_factor;

    // Initialize biome data structures
    BiomeData midnight = BiomeData(
        smoothstep(outer_rim_start, outer_rim_start + outer_rim_blend, dist_from_center),
        midnight_noise_scale,
        midnight_noise_height,
        midnight_octaves,
        midnight_roughness_mod,
        midnight_specular_mod,
        midnight_color
    );

    BiomeData ocean = BiomeData(
        smoothstep(ocean_ring_start, ocean_ring_start + ocean_ring_blend, dist_from_center) *
        (1.0 - midnight.factor),
        ocean_noise_scale,
        ocean_noise_height,
        ocean_octaves,
        ocean_roughness_mod,
        ocean_specular_mod,
        ocean_deep_color
    );

    BiomeData desert = BiomeData(
        1.0 - smoothstep(desert_center_radius, desert_center_radius + desert_blend, dist_from_center),
        desert_noise_scale,
        desert_noise_height,
        desert_octaves,
        desert_roughness_mod,
        desert_specular_mod,
        desert_color
    );

    BiomeColors colors;
    colors.albedo_tint = desert.color;
    colors.roughness_mod = desert.roughness_mod;
    colors.specular_mod = desert.specular_mod;
    colors.noise_scale = desert.noise_scale;
    colors.noise_height = desert.noise_height;
    colors.octaves = desert.octaves;

    // Ocean zone
    if (ocean.factor > 0.0) {
        colors.albedo_tint = mix(colors.albedo_tint, ocean.color, ocean.factor);
        colors.roughness_mod = mix(colors.roughness_mod, ocean.roughness_mod, ocean.factor);
        colors.specular_mod = mix(colors.specular_mod, ocean.specular_mod, ocean.factor);
        colors.noise_scale = mix(colors.noise_scale, ocean.noise_scale, ocean.factor);
        colors.noise_height = mix(colors.noise_height, ocean.noise_height, ocean.factor);
        colors.octaves = mix(colors.octaves, ocean.octaves, ocean.factor);
    }

    // Midnight zone
    if (midnight.factor > 0.0) {
        colors.albedo_tint = mix(colors.albedo_tint, midnight.color, midnight.factor);
        colors.roughness_mod = mix(colors.roughness_mod, midnight.roughness_mod, midnight.factor);
        colors.specular_mod = mix(colors.specular_mod, midnight.specular_mod, midnight.factor);
        colors.noise_scale = mix(colors.noise_scale, midnight.noise_scale, midnight.factor);
        colors.noise_height = mix(colors.noise_height, midnight.noise_height, midnight.factor);
        colors.octaves = mix(colors.octaves, midnight.octaves, midnight.factor);
    }

    return colors;
}
float world_noise(vec2 p) {
    float a = 0.0;
    float b = 1.0;
    vec2 d = vec2(0.0);

    BiomeColors biome = calculate_biome(v_vertex);
    int octaves = int(biome.octaves);

    for(int i=0; i < octaves; i++) {
        vec3 n = noise2D(p * biome.noise_scale);
        d += n.yz;
        a += b * n.x / (1.0 + dot(d,d));
        b *= 0.5;
        p = mat2(vec2(0.8, -0.6), vec2(0.6, 0.8)) * p * 2.0;
    }

    return a * biome.noise_height;
}

float get_noise_height(const vec2 uv) {
    float weight = region_blend(uv);
    if (weight <= 1.0 - world_noise_region_blend) {
        return 0.0;
    }

    float noise = world_noise((uv + world_noise_offset.xz * 1024.0 / _region_size) * 0.1);
    weight = smoothstep(1.0 - world_noise_region_blend, 1.0, weight);
    return mix(0.0, noise, weight);
}

float get_height(vec2 uv) {
    highp float height = 0.0;
    vec3 region = get_region_uv2(uv);
    if (region.z >= 0.0) {
        height = texture(_height_maps, region).r;
    }

    // Calculate world distance based on UV directly
    float dist_from_center = length(uv / _vertex_density);
    float height_factor = max(0.0, 1.0 - (dist_from_center / (outer_rim_start * _vertex_density)));
    height *= height_factor * height_factor;

    if (_background_mode == 2u) {
        BiomeColors biome = calculate_biome(v_vertex);
        height += get_noise_height(uv);
    }
    return height;
}

void vertex() {
    v_camera_pos = INV_VIEW_MATRIX[3].xyz;
    v_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    v_vertex_xz_dist = length(v_vertex.xz - v_camera_pos.xz);
    UV = round(v_vertex.xz * _vertex_density);
    UV2 = fma(UV, vec2(_region_texel_size), vec2(0.5 * _region_texel_size));

    v_region = get_region_uv(UV);
    uint control = texelFetch(_control_maps, v_region, 0).r;
    bool hole = bool(control >>2u & 0x1u);

    if (!(CAMERA_VISIBLE_LAYERS == _mouse_layer) &&
        (hole || (_background_mode == 0u && (get_region_uv(UV - _region_texel_size) & v_region).z < 0))) {
        VERTEX.x = 0. / 0.;
    } else {
        // Apply biome-specific height modifications
        VERTEX.y = get_height(UV2);
        v_vertex.y = VERTEX.y;

        // Calculate normals with biome-aware height sampling
        v_normal = vec3(
            v_vertex.y - get_height(UV2 + vec2(_region_texel_size, 0)),
            _vertex_spacing,
            v_vertex.y - get_height(UV2 + vec2(0, _region_texel_size))
        );

        v_region_border_mask = mod(UV.x + 2.5, _region_size) - fract(UV.x) < 5.0 ||
                              mod(UV.y + 2.5, _region_size) - fract(UV.y) < 5.0 ? 1. : 0.;
    }

    v_uv_offset = MODEL_MATRIX[3].xz * _vertex_density;
    UV -= v_uv_offset;
    v_uv2_offset = v_uv_offset * _region_texel_size;
    UV2 -= v_uv2_offset;

    VERTEX = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    VERTEX = (VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
    NORMAL = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
    BINORMAL = normalize((MODELVIEW_MATRIX * vec4(BINORMAL, 0.0)).xyz);
    TANGENT = normalize((MODELVIEW_MATRIX * vec4(TANGENT, 0.0)).xyz);
}
vec3 get_normal(vec2 uv, out vec3 tangent, out vec3 binormal) {
    float u, v, height;
    vec3 normal;

    // Use vertex normals within radius of vertex_normals_distance, and along region borders
    if ((v_region_border_mask > 0.5 || v_vertex_xz_dist < vertex_normals_distance) && v_region.z >= 0) {
        normal = normalize(v_normal);
    } else {
        height = get_height(uv);
        u = height - get_height(uv + vec2(_region_texel_size, 0));
        v = height - get_height(uv + vec2(0, _region_texel_size));
        normal = normalize(vec3(u, _vertex_spacing, v));
    }

    tangent = normalize(cross(normal, vec3(0, 0, 1)));
    binormal = normalize(cross(normal, tangent));
    return normal;
}

vec2 rotate(vec2 v, float cosa, float sina) {
    return vec2(fma(cosa, v.x, -sina * v.y), fma(sina, v.x, cosa * v.y));
}

vec2 rotate_around(vec2 point, vec2 pivot, float angle) {
    float x = pivot.x + (point.x - pivot.x) * cos(angle) - (point.y - pivot.y) * sin(angle);
    float y = pivot.y + (point.x - pivot.x) * sin(angle) + (point.y - pivot.y) * cos(angle);
    return vec2(x, y);
}

float random(in vec2 xy) {
    return fract(sin(dot(xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 detiling(vec2 uv, vec2 uv_center, int mat_id, inout float normal_rotation) {
    if (_texture_detile_array[mat_id] >= 0.001) {
        uv_center = floor(uv_center) + 0.5;
        float detile = fma(random(uv_center), 2.0, -1.0) * TAU * _texture_detile_array[mat_id];
        uv = rotate_around(uv, uv_center, detile);
        normal_rotation += detile;
    }
    return uv;
}

vec3 unpack_normal(vec4 rgba) {
    vec3 n = fma(rgba.xzy, vec3(2.0, 2.0, -2.0), vec3(-1.0, -1.0, 1.0));
    return n;
}

vec4 pack_normal(vec3 n, float a) {
    return vec4(fma(n.xzy, vec3(0.5, -0.5, 0.5), vec3(0.5)), a);
}

vec4 height_blend(vec4 a_value, float a_height, vec4 b_value, float b_height, float blend) {
    if(height_blending) {
        float ma = max(a_height + (1.0 - blend), b_height + blend) - (1.001 - blend_sharpness);
        float b1 = max(a_height + (1.0 - blend) - ma, 0.0);
        float b2 = max(b_height + blend - ma, 0.0);
        return (a_value * b1 + b_value * b2) / (b1 + b2);
    } else {
        float contrast = 1.0 - blend_sharpness;
        float factor = (blend - contrast) / contrast;
        return mix(a_value, b_value, clamp(factor, 0.0, 1.0));
    }
}
float blend_weights(float weight, float detail) {
    weight = smoothstep(0.0, 1.0, weight);
    weight = sqrt(weight * 0.5);
    float result = max(0.1 * weight, fma(10.0, (weight + detail), 1.0f - (detail + 10.0)));
    return result;
}

vec2 rotate_normal(vec2 normal, float angle) {
    angle = fma(PI, 0.5, angle);
    float new_y = dot(vec2(cos(angle), sin(angle)), normal);
    angle = fma(PI, -0.5, angle);
    float new_x = dot(vec2(cos(angle), sin(angle)), normal);
    return vec2(new_x, new_y);
}

void get_material(vec2 base_uv, uint control, ivec3 iuv_center, vec3 normal, out Material out_mat) {
    out_mat = Material(vec4(0.), vec4(0.), 0, 0, 0.0);
    vec2 uv_center = vec2(iuv_center.xy);
    int region = iuv_center.z;

    // Enable Autoshader if outside regions or painted in regions, otherwise manual painted
    bool auto_shader = region < 0 || bool(control & 0x1u);
    out_mat.base = int(auto_shader) * auto_base_texture + int(!auto_shader) * int(control >>27u & 0x1Fu);
    out_mat.over = int(auto_shader) * auto_overlay_texture + int(!auto_shader) * int(control >> 22u & 0x1Fu);
    out_mat.blend = float(auto_shader) * clamp(
            dot(vec3(0., 1., 0.), normal * auto_slope * 2. - (auto_slope * 2. - 1.))
            - auto_height_reduction * .01 * v_vertex.y // Reduce as vertices get higher
            , 0., 1.) +
             float(!auto_shader) * float(control >>14u & 0xFFu) * 0.003921568627450; // 1./255.0

    // Control map scale & rotation, apply to both base and
    // uv_center. Translate uv center to the current region.
    uv_center += _region_locations[region] * _region_size;

    // Define base scale from control map value as array index. 0.5 as baseline.
    float[8] scale_array = { 0.5, 0.4, 0.3, 0.2, 0.1, 0.8, 0.7, 0.6};
    float control_scale = scale_array[(control >>7u & 0x7u)];
    base_uv *= control_scale;
    uv_center *=  control_scale;

    // Calculate baseline derivatives
    vec2 ddx = dFdxCoarse(base_uv);
    vec2 ddy = dFdyCoarse(base_uv);

    // Apply global uv rotation from control map
    float uv_rotation = float(control >>10u & 0xFu) / 16. * TAU;
    base_uv = rotate_around(base_uv, vec2(0), uv_rotation);
    uv_center = rotate_around(uv_center, vec2(0), uv_rotation);

    vec2 matUV = base_uv;
    vec4 albedo_ht = vec4(0.);
    vec4 normal_rg = vec4(0.5f, 0.5f, 1.0f, 1.0f);
    vec4 albedo_far = vec4(0.);
    vec4 normal_far = vec4(0.5f, 0.5f, 1.0f, 1.0f);
    float mat_scale = _texture_uv_scale_array[out_mat.base];
    float normal_angle = uv_rotation;
    vec2 ddx1 = ddx;
    vec2 ddy1 = ddy;

    // If dual scaling, apply to base texture
    if(region < 0) {
        mat_scale *= tri_scale_reduction;
    }

    //each time we change scale, recalculate antitiling from baseline to maintain continuity
    matUV = detiling(base_uv * mat_scale, uv_center * mat_scale, out_mat.base, normal_angle);
    ddx1 *= mat_scale;
    ddy1 *= mat_scale;
    albedo_ht = textureGrad(_texture_array_albedo, vec3(matUV, float(out_mat.base)), ddx1, ddy1);
    normal_rg = textureGrad(_texture_array_normal, vec3(matUV, float(out_mat.base)), ddx1, ddy1);

    // Unpack & rotate base normal for blending
    normal_rg.xz = unpack_normal(normal_rg).xz;
    normal_rg.xz = rotate_normal(normal_rg.xz, normal_angle);

    if(out_mat.base == dual_scale_texture || out_mat.over == dual_scale_texture) {
        mat_scale *= dual_scale_reduction;
        ddx1 *= dual_scale_reduction;
        ddy1 *= dual_scale_reduction;
        float dual_scale_normal = uv_rotation; //do not add near & far rotations
        // Do not apply detiling if tri-scale reduction occurs
        matUV = region < 0 ? base_uv * mat_scale : detiling(base_uv * mat_scale, uv_center * mat_scale, dual_scale_texture, dual_scale_normal);
        albedo_far = textureGrad(_texture_array_albedo, vec3(matUV, float(dual_scale_texture)), ddx1, ddy1);
        normal_far = textureGrad(_texture_array_normal, vec3(matUV, float(dual_scale_texture)), ddx1, ddy1);

        // Unpack & rotate dual scale normal for blending
        normal_far.xz = unpack_normal(normal_far).xz;
        normal_far.xz = rotate_normal(normal_far.xz, dual_scale_normal);
    }

    float far_factor = clamp(smoothstep(dual_scale_near, dual_scale_far, length(v_vertex - v_camera_pos)), 0.0, 1.0);
    if(out_mat.base == dual_scale_texture) {
        albedo_ht = mix(albedo_ht, albedo_far, far_factor);
        normal_rg = mix(normal_rg, normal_far, far_factor);
    }

    // Apply color to base
    albedo_ht.rgb *= _texture_color_array[out_mat.base].rgb;

    // Setup overlay texture to blend
    float mat_scale2 = _texture_uv_scale_array[out_mat.over];
    float normal_angle2 = uv_rotation;
    vec2 matUV2 = detiling(base_uv * mat_scale2, uv_center * mat_scale2, out_mat.over, normal_angle2);
    vec2 ddx2 = ddx * mat_scale2;
    vec2 ddy2 = ddy * mat_scale2;
    vec4 albedo_ht2 = textureGrad(_texture_array_albedo, vec3(matUV2, float(out_mat.over)), ddx2, ddy2);
    vec4 normal_rg2 = textureGrad(_texture_array_normal, vec3(matUV2, float(out_mat.over)), ddx2, ddy2);

    // Though it would seem having the above lookups in this block, or removing the branch would
    // be more optimal, the first introduces artifacts #276, and the second is noticably slower.
    // It seems the branching off dual scaling and the color array lookup is more optimal.
    if (out_mat.blend > 0.f) {
        // Unpack & rotate overlay normal for blending
        normal_rg2.xz = unpack_normal(normal_rg2).xz;
        normal_rg2.xz = rotate_normal(normal_rg2.xz, normal_angle2);

        // If dual scaling, apply to overlay texture
        if(out_mat.over == dual_scale_texture) {
            albedo_ht2 = mix(albedo_ht2, albedo_far, far_factor);
            normal_rg2 = mix(normal_rg2, normal_far, far_factor);
        }

        // Apply color to overlay
        albedo_ht2.rgb *= _texture_color_array[out_mat.over].rgb;

        // Blend overlay and base
        albedo_ht = height_blend(albedo_ht, albedo_ht.a, albedo_ht2, albedo_ht2.a, out_mat.blend);
        normal_rg = height_blend(normal_rg, albedo_ht.a, normal_rg2, albedo_ht2.a, out_mat.blend);
    }

    // Repack normals and return material
    normal_rg = pack_normal(normal_rg.xyz, normal_rg.a);
    out_mat.alb_ht = albedo_ht;
    out_mat.nrm_rg = normal_rg;
    return;
}
void fragment() {
    vec2 uv = UV + v_uv_offset;
    vec2 uv2 = UV2 + v_uv2_offset;

    vec3 w_tangent, w_binormal;
    vec3 w_normal = get_normal(uv2, w_tangent, w_binormal);
    NORMAL = mat3(VIEW_MATRIX) * w_normal;
    TANGENT = mat3(VIEW_MATRIX) * w_tangent;
    BINORMAL = mat3(VIEW_MATRIX) * w_binormal;

    vec2 texel_pos = uv;
    highp vec2 texel_pos_floor = floor(uv);
    vec4 mirror = vec4(fract(texel_pos_floor * 0.5) * 2.0, 1.0, 1.0);
    mirror.zw = vec2(1.0) - mirror.xy;

    ivec3 indexUV[4] = {
        get_region_uv(texel_pos_floor + mirror.xy),
        get_region_uv(texel_pos_floor + mirror.xw),
        get_region_uv(texel_pos_floor + mirror.zy),
        get_region_uv(texel_pos_floor + mirror.zw)
    };

    uint control[4] = {
        texelFetch(_control_maps, indexUV[0], 0).r,
        texelFetch(_control_maps, indexUV[1], 0).r,
        texelFetch(_control_maps, indexUV[2], 0).r,
        texelFetch(_control_maps, indexUV[3], 0).r
    };

    Material mat[4];
    get_material(uv, control[0], indexUV[0], w_normal, mat[0]);
    get_material(uv, control[1], indexUV[1], w_normal, mat[1]);
    get_material(uv, control[2], indexUV[2], w_normal, mat[2]);
    get_material(uv, control[3], indexUV[3], w_normal, mat[3]);

    vec2 weights1 = clamp(texel_pos - texel_pos_floor, 0, 1);
    weights1 = mix(weights1, vec2(1.0) - weights1, mirror.xy);
    vec2 weights0 = vec2(1.0) - weights1;

    float noise3 = texture(noise_texture, uv*noise3_scale).r;
    vec4 weights;
    weights.x = blend_weights(weights0.x * weights0.y, clamp(mat[0].alb_ht.a + noise3, 0., 1.));
    weights.y = blend_weights(weights0.x * weights1.y, clamp(mat[1].alb_ht.a + noise3, 0., 1.));
    weights.z = blend_weights(weights1.x * weights0.y, clamp(mat[2].alb_ht.a + noise3, 0., 1.));
    weights.w = blend_weights(weights1.x * weights1.y, clamp(mat[3].alb_ht.a + noise3, 0., 1.));
    float weight_sum = weights.x + weights.y + weights.z + weights.w;
    float weight_inv = 1.0 / weight_sum;

    vec4 albedo_height = weight_inv * (
        mat[0].alb_ht * weights.x +
        mat[1].alb_ht * weights.y +
        mat[2].alb_ht * weights.z +
        mat[3].alb_ht * weights.w );

    vec4 normal_rough = weight_inv * (
        mat[0].nrm_rg * weights.x +
        mat[1].nrm_rg * weights.y +
        mat[2].nrm_rg * weights.z +
        mat[3].nrm_rg * weights.w );

    vec3 region_uv = get_region_uv2(uv2);

    vec4 color_map = vec4(1., 1., 1., .5);
    if (region_uv.z >= 0.) {
        float lod = textureQueryLod(_color_maps, uv2.xy).y;
        color_map = textureLod(_color_maps, region_uv, lod);
    }

    float noise1 = texture(noise_texture, rotate(uv*noise1_scale * .1, cos(noise1_angle), sin(noise1_angle)) + noise1_offset).r;
    float noise2 = texture(noise_texture, uv*noise2_scale * .1).r;
    vec3 macrov = mix(macro_variation1, vec3(1.), clamp(noise1 + v_vertex_xz_dist * .0002, 0., 1.));
    macrov *= mix(macro_variation2, vec3(1.), clamp(noise2 + v_vertex_xz_dist * .0002, 0., 1.));

    float roughness = fma(color_map.a - 0.5, 2.0, normal_rough.a);

    // Calculate final biome colors and material modifications
    BiomeColors biome = calculate_biome(v_vertex);

    // Apply PBR with biome modifications
    ALBEDO = albedo_height.rgb * color_map.rgb * macrov * biome.albedo_tint;
    ROUGHNESS = roughness + biome.roughness_mod;
    SPECULAR = 1.0 - normal_rough.a + biome.specular_mod;
    NORMAL_MAP = normal_rough.rgb;
    NORMAL_MAP_DEPTH = 1.0;
}