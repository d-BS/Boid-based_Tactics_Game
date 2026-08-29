#[compute]
#version 450


//to add:
//sleeping
//bias
//squad bias
//damping
//switch all instances of 'distance' and 'length'
// to dist^2 & len^2


//flat 128 threads.
//1024 from the tutorial didn't work for me, so I settled on this.
//maybe try 16 x 16 later
layout(local_size_x = 128, local_size_y = 1, local_size_z = 1) in;

//buffer for the position of each boid
layout(set = 0, binding = 0, std430) restrict buffer Position {
	vec2 data[];
} boid_pos;

//buffer for the velocity of each boid
layout(set = 0, binding = 1, std430) restrict buffer Velocity{
	vec2 data[];
} boid_vel;

layout(set = 0, binding = 2, std430) restrict buffer BiasLocation{
	vec2 data[];
} bias_loc;

layout(set = 0, binding = 3, std430) restrict buffer SquadBias{
	vec2 data[];
} squad_bias;

//parameter buffer
layout(set = 0, binding = 4, std430) restrict buffer Params{
	float num_boids;
    float image_size;
    float vision_rad;
    float avoid_rad;
    float min_vel;
    float max_vel;
    float alignment_factor;
    float cohesion_factor;
    float avoidance_factor;
    float damp_factor;
    float viewport_x;
    float viewport_y;
    float delta_time;
} params;


//float bias_factor;
//float damp_factor; -- done!
//float sleep_cutoff;
//float wake_cutoff;


//image out
//formerly rgba16f
layout(rgba32f, binding = 5) uniform image2D boid_data;


void main() {
	
	int index = int(gl_GlobalInvocationID.x);

	vec2 position = boid_pos.data[index];
	vec2 velocity = boid_vel.data[index];


	int num_neighbors = 0;
	vec2 avoid_direction = vec2(0,0);
	vec2 average_velocity = vec2(0,0);
	vec2 average_position = vec2(0,0);

	//bool kicker = velocity.length() >= wakeup cutoff


	for(int i = 0; i < params.num_boids; i++){

		if(i!=index){

			vec2 b_pos = boid_pos.data[i];
			vec2 b_vel = boid_vel.data[i];

			float distance = distance(position, b_pos);

			if(distance < params.vision_rad){


				num_neighbors++;

				if(distance <= params.avoid_rad){
					avoid_direction += position - b_pos;

					//if is sleeping
					//wake
				}

				//if b not sleeping

				average_velocity += b_vel;
				average_position += b_pos;

				//else if kicker
				//wake

			}

		}
	}

	velocity += avoid_direction * params.avoidance_factor * params.delta_time;


	//this causes the larger slow ones, for some reason
	//aha! its because with alignment, the avg vel is ADDED to the vel, meaning groups are faster!
	if (num_neighbors > 0){

		//why the - velocity ?????!?
		//dont use this one//velocity += (average_velocity / num_neighbors - velocity) * params.alignment_factor * params.delta_time;
		velocity += (average_velocity / num_neighbors) * params.alignment_factor * params.delta_time;

		//applies average position
		velocity += (average_position / num_neighbors - position) * params.cohesion_factor * params.delta_time;
	}


	vec2 bias_location = bias_loc.data[index];

	if (!isinf(bias_location[0])){

		//magic num bs
		//var deadzone^2 = 2500
		// max speed = 20

		

		vec2 bias = bias_location - position;

		//magic
		if(dot(bias, bias) > 2500){

			//formerly 20
			//magic
			bias = normalize(bias) * 15;

		}
		else{
			bias = vec2(0, 0);
		}

		velocity += bias * params.delta_time;


	}
	
	
	//velocity += squad_bias * delta * bias_factor
	//magic number .075 for bias_factor
	velocity += squad_bias.data[index] * params.delta_time * .075;


	//applies damping
	velocity /= 1 + params.damp_factor * params.delta_time;


	//if velocity < sleep cutoff and avg_vel < sleep cutoff
	//sleep



	position += velocity * params.delta_time;


	if (isnan(position.x) || isnan(position.y) || isinf(position.x) || isinf(position.y))
		position = vec2(0, 0);

	boid_vel.data[index] = velocity;
	boid_pos.data[index] = position;

	ivec2 pixel_pos = ivec2(int(mod(index, params.image_size)), int(index / params.image_size));


	
	imageStore(boid_data, pixel_pos, vec4(position.x, position.y, 0, 1));

}

