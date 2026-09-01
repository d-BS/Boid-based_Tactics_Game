extends Node2D
var DEBUG_LOG = false


var NUM_BOIDS:int = 20096


#scale was 1.5 while 16 x 16


#TODO:
#
#Have initial boids in squads[1], keep squads[0] empty a very start
#Have goal-less boids removed from squad structure overall?
#get rid of 'selection squad' idea, just have a squad be selected
#be able to reselect a squad
#
#Add formation structure, replace squad_bias (replace bias_loc?)
#
#Make NUM_BOIDS dynamic rather than hardcoded
#(Add in MAX_BOIDS, and only update texture/arrays when passed?)
#be able to create boids, have boids be killed, etc
#
#Binning: Boids only check their own bin, and bins orthoganal to them
#Bins have side len vision_radius
#to get bin # for each boid, we:
#vec2i bin_pair = int(pos / vision_rad)
#
#bin_pair.x = bin_pair.x < 0 ? 2 * -bin_pair.x - 1 : 2 * bin_pair.x
#(same w y)
#
#int bin_num = (x + y) * (x + y + 1) / 2 + y
#
#bin_list.insert_at(bin_list.bsearch(bin_num), vec2(bin_num, boid_id))
#
#
#
#
#Optimizations for later:
#
#Convert vec2 arrays to vec2i arrays / int arrays twice as long
#In shader, convert distance to dist^2
#

#buffers-to-be
var boid_pos:PackedVector2Array = []
var boid_vel:PackedVector2Array = []
var bias_locations:PackedVector2Array = []
var squad_biases:PackedVector2Array = []
## Stores bin #, boid id #
var bin_list:PackedVector2Array = []

#turn into packed byte array later? -> turn into squad_color
#var is_selected:Array[bool]
var squad_color:Array[Color]

## contains positions of boids, and is actively updated
var boid_pos_active:PackedColorArray = []

## Each unit's location within the squad structure
var squad_indeces:PackedVector2Array

#list of squads
var squads:Array[Squad]

#which squad is selected
var selection_squad:int = -1

#lists which squads are empty
var empty_squads:Array[int] = []

var IMAGE_SIZE:int = int(ceil(sqrt(NUM_BOIDS))) + 1
var boid_data : Image
var boid_data_texture : ImageTexture

var vision_radius:float = 35
var avoid_radius:float = 25
var min_vel:float = 0
#formerly 60, also not doing anything
var max_vel:float = 30.0
#formerly .5
var alignment_factor:float = -.7
#formerly -.05
var cohesion_factor:float = -.05
#formerly 10, then 15 w old formula, .25 w new
var separation_factor:float = .25
var damp_factor:float = 1.5

# GPU Variables
var SIMULATE_GPU:bool = true
var rd : RenderingDevice
var boid_compute_shader : RID
var pipeline : RID
var bindings : Array
var uniform_set : RID

var boid_pos_buffer : RID
var boid_vel_buffer : RID
var boid_bias_loc_buffer:RID
var squad_bias_buffer:RID
var params_buffer: RID
var params_uniform : RDUniform
var boid_data_buffer : RID





func _ready():
	
	seed(0)
	
	
	
	
	boid_data = Image.create(IMAGE_SIZE, IMAGE_SIZE, false, Image.FORMAT_RGBAF)								
	boid_data_texture = ImageTexture.create_from_image(boid_data)
	
	bias_locations.resize(NUM_BOIDS)
	squad_biases.resize(NUM_BOIDS)
	bias_locations.fill(Vector2.INF)
	squad_biases.fill(Vector2.ZERO)
	
	#REMEMBER TO CHANGE IN GDSHADER
	#is_selected.resize(20000)
	#is_selected.fill(false)
	
	squad_color.resize(20096)
	squad_color.fill(Color.BLACK)
	
	
	
	_generate_boids()
	
	
	$boid_particles.amount = NUM_BOIDS
	$boid_particles.process_material.set_shader_parameter("boid_data", boid_data_texture)
	#$boid_particles.process_material.set_shader_parameter("is_selected", is_selected)
	$boid_particles.process_material.set_shader_parameter("colors", squad_color)
	
	#DANGER (potentially?)
	$boid_particles.visibility_rect = Rect2(-Vector2.INF, Vector2.INF)
	
	
	
	if SIMULATE_GPU:
		_setup_compute_shader()
		
		_update_boids_gpu(0)
	
	
	
	#destroys the now-useless buffers
	boid_pos = []
	boid_vel = []
	

func _generate_boids():
	
	var array_o_boids:Array[int]
	array_o_boids.resize(NUM_BOIDS)
	boid_pos.resize(NUM_BOIDS)
	boid_vel.resize(NUM_BOIDS)
	squad_indeces.resize(NUM_BOIDS)
	
	for i in NUM_BOIDS:
		
		boid_pos[i] = Vector2(randf() * get_viewport_rect().size.x * 5, randf()  * get_viewport_rect().size.y * 5)
		boid_vel[i] = Vector2(randf_range(-1.0, 1.0) * max_vel, randf_range(-1.0, 1.0) * max_vel)
		array_o_boids[i] = i
		squad_indeces[i] = Vector2(0, i)
	
	
	squads = [Squad.new([])]
	squads[0].boid_manager = self
	squads[0].units = array_o_boids


func _process(delta):	
	
	
	
	get_window().title = "Boids: " + str(NUM_BOIDS) + " / FPS: " + str(Engine.get_frames_per_second())
	
	
	
	if SIMULATE_GPU:
		_sync_boids_gpu()
	
	
	
	_update_data_texture()
	
	
	
	if SIMULATE_GPU:
		_update_boids_gpu(delta)
		
	
	
	for s in squads:
		
		s.update(delta)
		
	
	queue_redraw()
	
func _draw() -> void:
	
	#draw_rect($boid_particles.visibility_rect, Color.AQUA)
	
	for s in squads:
		
		if(!is_inf(s.goal.x)):
			draw_line(s.goal, s.appx_location, Color.GREEN, 30)
		#draw_circle(s.appx_location, 10, Color.GREEN)
		#draw_circle(s.goal, 10, Color.RED)
		
	
	pass

func _update_boids_gpu(delta):
	rd.free_rid(params_buffer)
	params_buffer = _generate_parameter_buffer(delta)
	params_uniform.clear_ids()
	params_uniform.add_id(params_buffer)
	uniform_set = rd.uniform_set_create(bindings, boid_compute_shader, 0)
	
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	
	#DANGER not really actually, im just not sure if 128 is the right number
	#rd.compute_list_dispatch(compute_list, floor(NUM_BOIDS/128.), 1, 1)
	#Magic number!! 157 * 128 = 20096
	rd.compute_list_dispatch(compute_list, 157, 1, 1)
	rd.compute_list_end()
	rd.submit()
		
func _sync_boids_gpu():
	rd.sync()
	
func _update_data_texture():
	
	
	#if Engine.get_frames_drawn() == 1:
		
		#double checking to make sure that they actually exist at this point in time
		#get_node("../SelectionBox").selectionRect = Rect2(-INF, -INF, INF, INF)
		
	#	get_node("../SelectionBox")._finalize_selection_gpu()
	
	
	if SIMULATE_GPU:
		var boid_data_image_data:PackedByteArray = rd.texture_get_data(boid_data_buffer, 0)
		boid_data.set_data(IMAGE_SIZE, IMAGE_SIZE, false, Image.FORMAT_RGBAF, boid_data_image_data)
	
	
	#updates boid_pos_active
	var boid_pos_bytes:PackedByteArray = boid_data.get_data()
	boid_pos_active = boid_pos_bytes.to_color_array()
	
	#if Engine.get_frames_drawn() == 1:
	#	get_node("../SelectionBox")._finalize_selection_gpu()
	
	boid_data_texture.update(boid_data)
	
	
	

func _setup_compute_shader():
	
	rd = RenderingServer.create_local_rendering_device()
	
	var shader_file := load("res://scripts/boid_compute_shader.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	boid_compute_shader = rd.shader_create_from_spirv(shader_spirv)
	pipeline = rd.compute_pipeline_create(boid_compute_shader)
	
	boid_pos_buffer = _generate_vec2_buffer(boid_pos)
	var boid_pos_uniform = _generate_uniform(boid_pos_buffer, RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 0)
	
	boid_vel_buffer = _generate_vec2_buffer(boid_vel)
	var boid_vel_uniform = _generate_uniform(boid_vel_buffer, RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 1)
	
	boid_bias_loc_buffer = _generate_vec2_buffer(bias_locations)
	var boid_bias_loc_uniform = _generate_uniform(boid_bias_loc_buffer, RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 2)
	
	squad_bias_buffer = _generate_vec2_buffer(squad_biases)
	var squad_bias_uniform = _generate_uniform(squad_bias_buffer, RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 3)
	
	params_buffer = _generate_parameter_buffer(0)
	params_uniform = _generate_uniform(params_buffer, RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 4)
	
	var fmt := RDTextureFormat.new()
	fmt.width = IMAGE_SIZE
	fmt.height = IMAGE_SIZE
	fmt.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	
	var view := RDTextureView.new()
	boid_data_buffer = rd.texture_create(fmt, view, [boid_data.get_data()])
	var boid_data_buffer_uniform = _generate_uniform(boid_data_buffer, RenderingDevice.UNIFORM_TYPE_IMAGE, 5)
	
	bindings = [boid_pos_uniform, boid_vel_uniform, boid_bias_loc_uniform, squad_bias_uniform, params_uniform, boid_data_buffer_uniform]
	
func _generate_vec2_buffer(data):
	var data_buffer_bytes := PackedVector2Array(data).to_byte_array()
	var data_buffer = rd.storage_buffer_create(data_buffer_bytes.size(), data_buffer_bytes)
	return data_buffer

func _generate_uniform(data_buffer, type, binding):
	var data_uniform = RDUniform.new()
	data_uniform.uniform_type = type
	data_uniform.binding = binding
	data_uniform.add_id(data_buffer)
	return data_uniform

func _generate_parameter_buffer(delta):
	var params_buffer_bytes : PackedByteArray = PackedFloat32Array(
		[NUM_BOIDS, 
		IMAGE_SIZE, 
		vision_radius,
		avoid_radius,
		min_vel, 
		max_vel,
		alignment_factor,
		cohesion_factor,
		separation_factor,
		damp_factor,
		get_viewport_rect().size.x,
		get_viewport_rect().size.y,
		delta]).to_byte_array()
	
	return rd.storage_buffer_create(params_buffer_bytes.size(), params_buffer_bytes)

func _exit_tree():
	if SIMULATE_GPU:
		_sync_boids_gpu()
		
		
		#DANGER -> for some reason if this isnt commented out i get an error
		#upon reloading the scene
		#rd.free_rid(uniform_set)
		rd.free_rid(boid_data_buffer)
		rd.free_rid(params_buffer)
		rd.free_rid(boid_pos_buffer)
		rd.free_rid(boid_vel_buffer)
		rd.free_rid(pipeline)
		rd.free_rid(boid_compute_shader)
		
		rd.free_rid(boid_bias_loc_buffer)
		rd.free_rid(squad_bias_buffer)
		
		
		
		rd.free()


func set_selected_bias(new_bias:Vector2):
	
	#just sets all of them
	squads[0].set_bias(new_bias)
	
	
	pass


func select_boids(new_selection:Array[int]):
	
	#is_selected.fill(false)
	
	#remeves selected boids from whatever squads they were in
	for b:int in new_selection:
	
		
		#b is now selected
		#is_selected[b] = true
		
		var squad_getting_removed_from:int = int(squad_indeces[b].x)
		
		
		
		#removes b from current squad
		squads[squad_getting_removed_from].remove_boid(int(squad_indeces[b].y))
		
		#if b's squad is now empty, adds to empty_squads
		if squad_getting_removed_from != 0 && squads[squad_getting_removed_from].units.is_empty():
			empty_squads.insert(empty_squads.bsearch(squad_getting_removed_from), squad_getting_removed_from)
			
		
	
	
	
	#removes any remaining boids from selection squad
	deselect_boids()
	
	
	
	#new_selection is selection squad now
	squads[0] = Squad.new(new_selection)
	
	
	
	#updates the bias
	#I bet this is causing the abberant boids, or at least a part of the cause
	rd.free_rid(boid_bias_loc_buffer)
	boid_bias_loc_buffer = _generate_vec2_buffer(bias_locations)
	var boid_bias_loc_uniform = _generate_uniform(boid_bias_loc_buffer, RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 2)
	bindings[2] = boid_bias_loc_uniform
	
	
	
	
	#clears any back bloat
	while !empty_squads.is_empty() && empty_squads.back() == squads.size() - 1:
		
		empty_squads.pop_back()
		squads.pop_back()
		
	
	
	
	#colors selected boids
	$boid_particles.process_material.set_shader_parameter("color", squad_color)
	
	pass


func deselect_boids():
	
	
	if squads[0].units.is_empty():
		return
	
	var new_color: Color = Color.from_ok_hsl(randf(), .8, .8)
	
	#moves selection squad from [0] to either end or first empty
	if empty_squads.is_empty():
		
		#append new squad to end of squads
		
		squads.append(Squad.new(squads[0].units, squads.size(), squads[0].goal, new_color))
		
		
		pass
	else:
		
		squads[empty_squads[0]] = Squad.new(squads[0].units, empty_squads[0], squads[0].goal, new_color)
		empty_squads.pop_front()
		
		pass
	
	
	pass
