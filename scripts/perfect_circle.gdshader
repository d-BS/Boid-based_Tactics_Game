shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}


void fragment() {
	
	//dertermines if pixel is inside or outside circle
	//with radius of .5
	
	//set center of circle to be center of UV
	vec2 center = vec2(.5, .5);
	
	//calculates this pixel's distance^2 from center
	center = UV.xy - center;
	center = center * center;
	float dist_sq = center.x + center.y;
	
	//we compare dist^2 with predertermined radius^2
	if(dist_sq > .25)
		COLOR.a = 0.0;
	
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
