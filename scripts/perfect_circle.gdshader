shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	
	
	vec2 center = vec2(.5, .5);
	center = UV.xy - center;
	center = center * center;
	
	float dist_sq = center.x + center.y;
	
	if(dist_sq > .25)
		COLOR.a = 0.0;
	
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
