shader_type canvas_item;
uniform sampler2D wind_noise;
uniform vec2 wind_direction;
//uniform bool mirror_horizontal;
//const vec4 target_color = vec4(0.8, 0.8, 0.0, 1.0);
//const float color_mobility = .2;

void vertex() {
	// Called for every vertex the material is visible on.
	
	if(VERTEX_ID == 2 || VERTEX_ID == 3){
		
		//int wind_sample_x = int(VERTEX.x);
		//int wind_sample_y = int(VERTEX.y);
		
		
		
		//wind_sample_x %= 512;
		//wind_sample_y %= 512;
		
		//float wind_intensity = texelFetch(wind_noise, ivec2(wind_sample_x, wind_sample_y), 0).a;
		
		//wind_intensity *= 100.0;
		
		VERTEX += vec2(cos(TIME) * 4.0, 0.0);//sin(TIME) * 5.0);
		//VERTEX += wind_direction * wind_intensity;
	
	
	}
	
	//VERTEX += vec2(cos(TIME)*100.0, sin(TIME)*100.0);
	
}

void fragment() {
	// Called for every pixel the material is visible on.
	
	//if(mirror_horizontal)
	//	COLOR = texture(TEXTURE, vec2(1.0 - UV.x, UV.y));
	
	//texture(TEXTURE, UV)
	if(COLOR.a != 0.0){
		
		float height_proportion = 1.0 - UV.y;
		//height_proportion = clamp(height_proportion + .4, 0.0, 1.0);
		
		height_proportion = clamp(height_proportion * 3.0 - 1.0, 0.0, 1.0);
		
		COLOR.a = height_proportion; // 2.0;
		
		//COLOR.r += height_proportion * color_mobility;
		//COLOR.g += height_proportion * color_mobility;
		//COLOR.b -= height_proportion * color_mobility;
		
	}
	
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
