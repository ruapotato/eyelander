shader_type spatial;
uniform sampler2D color;
uniform sampler2D color2;
uniform sampler2D height_texture;
uniform vec3 color3 : source_color;
uniform float noise_scale = 20.0;
uniform float time_scale : hint_range(0.0, 0.5) = 0.025;
uniform float height_scale = 0.15;

// Varying vars
varying float height;
varying vec3 world_pos;
/*
void vertex()
{
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	height = texture(height_texture, world_pos.xz /noise_scale + TIME * time_scale).r;
	VERTEX.y = VERTEX.y + (height * height_scale);
	//VERTEX.z = VERTEX.z + (height * height_scale);
	//VERTEX.x = VERTEX.x + (height * height_scale);
}
*/
void fragment() {
	vec3 pix_color = texture(color, (UV) * 5.0).rgb;
	vec3 pix_color2 = texture(color2, UV * 10.0 + TIME/80.0).rgb;
	//vec3 final_color = color3 - (pix_color * pix_color2);
	vec3 final_color = pix_color * pix_color2 * color3;
	final_color += (color3/5.0);
	ALBEDO = final_color;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
