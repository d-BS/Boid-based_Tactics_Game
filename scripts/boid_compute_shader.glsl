#[compute]
#version 450


//to add:
//sleeping ... ?
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

//buffer for bias provided by squad
layout(set = 0, binding = 2, std430) restrict buffer SquadBias{
	vec2 data[];
} squad_bias;

//parameter buffer
layout(set = 0, binding = 3, std430) restrict buffer Params{
	float num_boids;
    float image_size;
    float vision_rad;
    float avoid_rad;

	//Currently doing nothing
    float min_vel;
    float max_vel;

    float alignment_factor;
    float cohesion_factor;
    float avoidance_factor;
    float damp_factor;

	//also doing nothing
    float viewport_x;
    float viewport_y;

    float delta_time;
} params;


//float sleep_cutoff;
//float wake_cutoff;


//image out
//formerly rgba16f
layout(rgba32f, binding = 4) uniform image2D boid_data;


void main() {
	
	int index = int(gl_GlobalInvocationID.x);



	//having this just makes some things cleaner
	if (index >= params.num_boids){
		return;
	}



	vec2 position = boid_pos.data[index];
	vec2 velocity = boid_vel.data[index];




	//last resort catches
	//dont like that I need this
	if (isnan(position.x) || isnan(position.y) || isinf(position.x) || isinf(position.y))
		position = vec2(0, 0);
	if (isnan(velocity.x) || isnan(velocity.y) || isinf(velocity.x) || isinf(velocity.y))
		velocity = vec2(0, 0);







	int num_neighbors = 0;
	
	int avoid_neighbors = 0;
	vec2 avoid_direction = vec2(0,0);
	vec2 avoid_velocity_ave = vec2(0,0);

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
					avoid_neighbors++;
					avoid_direction += position - b_pos;
					avoid_velocity_ave += b_vel;

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



	
	if (num_neighbors > 0){

		//this causes groups to go faster whn alignment_factor is positive
		velocity += (average_velocity / num_neighbors) * params.alignment_factor * params.delta_time;

		//applies average position
		velocity += (average_position / num_neighbors - position) * params.cohesion_factor * params.delta_time;
	}


	//Formerly
		//velocity += squad_bias * delta * bias_factor
		//magic number .075 for bias_factor
		//velocity += squad_bias.data[index] * params.delta_time * .075;
	

	vec2 personal_squad_bias = squad_bias.data[index];
	if(!isinf(personal_squad_bias[0])){
		
		vec2 bias = personal_squad_bias - position;

		//ridiculous degrees of magic numbers
		if(bias != vec2(0,0))
			velocity += normalize(bias) * 1000 * params.delta_time * .075;

	}

	//applies damping
	velocity /= 1 + params.damp_factor * params.delta_time;


	//if velocity < sleep cutoff and avg_vel < sleep cutoff
	//sleep


	//skips work if no collisions
	if(avoid_neighbors != 0){

		avoid_velocity_ave /= avoid_neighbors;
		avoid_direction /= avoid_neighbors;

		//makes avoid dir stronger the closer the boids are together
		//magic nums formerly 1.25, 2
		avoid_direction = -avoid_direction * 2.5 + normalize(avoid_direction) * params.avoid_rad * 3;


		//takes the weighted average of current velocity and colliding velocities
		//adds avoidance vector, for final semi-elastic collision
		float self_v_weight = .2;
		velocity = (avoid_velocity_ave * self_v_weight + velocity) / (1 + self_v_weight) + (avoid_direction * params.avoidance_factor);
		

		//velocity = avoid_velocity_ave + (avoid_direction * params.avoidance_factor);
	}


	//apply max_vel -> doesnt seem necessary
	//if(length(velocity) > params.max_vel)
	//	velocity = normalize(velocity) * params.max_vel;
	

	position += velocity * params.delta_time;



	boid_vel.data[index] = velocity;
	boid_pos.data[index] = position;

	ivec2 pixel_pos = ivec2(int(mod(index, params.image_size)), int(index / params.image_size));


	
	imageStore(boid_data, pixel_pos, vec4(position.x, position.y, velocity.x, velocity.y));

}

