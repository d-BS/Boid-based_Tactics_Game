shader_type particles;

uniform sampler2D boid_colors;
uniform sampler2D boid_data;
uniform float scale = .5;

void process() {
	
	ivec2 pos_image_size = textureSize(boid_data, 0);
	
	ivec2 texel_pos = ivec2(int(mod(float(INDEX),float(pos_image_size.x))) - 1,
							int(float(INDEX)/float(pos_image_size.x)));
	
	
	vec4 boid_pos = texelFetch(boid_data, texel_pos, 0);
	
	//mat2 scale_rot_mat = mat2(vec2(cos(boid_pos_rot.b), sin(boid_pos_rot.b)), // First column
	//						  vec2(-sin(boid_pos_rot.b), cos(boid_pos_rot.b))); // Second column
	//scale_rot_mat *= scale;
	TRANSFORM[0].xy = vec2(scale, 0);
	TRANSFORM[1].xy = vec2(0, scale);
	TRANSFORM[3].xy = vec2(boid_pos.r, boid_pos.g); 
	
	
	
	//sets color
	COLOR = texelFetch(boid_colors, texel_pos, 0);
	
	
	//else if (is_selected[INDEX])
	//	COLOR = vec4(0.5294118, 0.80784315, 0.92156863, 1);
	//else
	//	COLOR = vec4(0, 0, 0, 1);
}
