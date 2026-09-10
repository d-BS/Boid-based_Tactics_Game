extends Node2D
var DEBUG_LOG = false

## current number of boids
var NUM_BOIDS:int = 25000

## maximum boids that current setup can handle w/o reallocating stuff, 
## set to nearest multiple of 128
var MAX_BOIDS:int = NUM_BOIDS + (0 if (NUM_BOIDS % 128 == 0) else (128 - NUM_BOIDS % 128))

#var MAX_BOIDS = 20096

@warning_ignore("integer_division")
var NUM_WORKGROUPS:int = MAX_BOIDS / 128


#TODO:
#
#
#Have goal-less boids removed from squad structure overall?
#
#Debug mystery 40 stuck at origin / nan
#
#fix deletion wierdness
#
#
#add more kinds of formations, remove hardcoding
#have finer-tune control of formation during gameplay, add ui for this
#
#detangle formation.location and goal, that was a bad idea
#
#be able to create boids, have boids be killed, etc
#
#
#
#Binning: Boids only check their own bin, orthoganal bins
#Bins have side len vision_radius
#to get bin # for each boid, we:
#vec2i bin_pair = int(pos / vision_rad)
#
#predertermined # of bins / arena size
#
#matrix stores first boid in bin, array which stores next boid in bin
#
#
#
#Optimizations for later:
#
#Convert vec2 arrays to vec2i arrays / int arrays twice as long?
#In shader, convert distance to dist^2
#

#buffers-to-be
var boid_pos:PackedVector2Array = []
var boid_vel:PackedVector2Array = []
var squad_biases:PackedVector2Array = []



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

#textures that store information for particle shader
var IMAGE_SIZE:int = int(ceil(sqrt(MAX_BOIDS)))
var boid_data : Image
var boid_data_texture : ImageTexture
var boid_colors_image : Image
var boid_colors_texture : ImageTexture

var boid_colors:PackedColorArray


var vision_radius:float = 35
var avoid_radius:float = 25
var min_vel:float = 0
#formerly 60, also not doing anything, 30
var max_vel:float = 30.0
#formerly .5
var alignment_factor:float = -.7
#formerly -.05
var cohesion_factor:float = -.05
#formerly 10, then 15 w old formula, .25 w new
var separation_factor:float = .25
var damp_factor:float = 1.5

# GPU Variables
var rd : RenderingDevice
var boid_compute_shader : RID
var pipeline : RID
var bindings : Array
var uniform_set : RID

var boid_pos_buffer : RID
var boid_vel_buffer : RID
var squad_bias_buffer:RID
var params_buffer: RID
var params_uniform : RDUniform
var boid_data_buffer : RID

#different queue variables

var update_squad_bias_uniform:bool = false
var update_boid_color_tex:bool = false

var remove_from_buffer:Array[int] = []


@warning_ignore("unused_signal")
signal squads_updated


func _ready():
	
	#seed(0)
	
	boid_data = Image.create_empty(IMAGE_SIZE, IMAGE_SIZE, false, Image.FORMAT_RGBAF)								
	boid_data_texture = ImageTexture.create_from_image(boid_data)
	boid_colors_image = Image.create_empty(IMAGE_SIZE, IMAGE_SIZE, false, Image.FORMAT_RGBAF)								
	boid_colors_texture = ImageTexture.create_from_image(boid_colors_image)
	
	
	#REMEMBER TO CHANGE IN GDSHADER
	squad_biases.resize(MAX_BOIDS)
	squad_biases.fill(Vector2.INF)
	
	boid_colors.resize(IMAGE_SIZE * IMAGE_SIZE)
	boid_colors.fill(Color.BLACK)
	
	
	
	_initial_boid_setup()
	queue_update_boid_colors()
	
	$boid_particles.amount = NUM_BOIDS
	$boid_particles.process_material.set_shader_parameter("boid_data", boid_data_texture)
	$boid_particles.process_material.set_shader_parameter("boid_colors", boid_colors_texture)
	
	
	#DANGER (potentially?) (using .INF in this situation feels wrong)
	$boid_particles.visibility_rect = Rect2(-Vector2.INF, Vector2.INF)
	
	
	
	
	_setup_compute_shader()
	
	_update_boids_gpu(0)
	
	
	
	#destroys the now-useless buffers
	boid_pos.clear()
	boid_vel.clear()
	

## FIX LATER
func _initial_boid_setup():
	
	var array_o_boids:Array[int]
	array_o_boids.resize(NUM_BOIDS)
	boid_pos.resize(MAX_BOIDS)
	boid_vel.resize(MAX_BOIDS)
	squad_indeces.resize(MAX_BOIDS)
	
	for i in NUM_BOIDS:
		
		boid_pos[i] = Vector2(randf() * get_viewport_rect().size.x * 5, randf()  * get_viewport_rect().size.y * 5)
		boid_vel[i] = Vector2(randf_range(-1.0, 1.0) * max_vel, randf_range(-1.0, 1.0) * max_vel)
		array_o_boids[i] = i
		squad_indeces[i] = Vector2(0, i)
	
	
	squads = [Squad.new([], 0)]
	squads[0].boid_manager = self
	squads[0].units = array_o_boids


func _process(delta):
	
	
	
	get_window().title = "Boids: " + str(NUM_BOIDS) + " / FPS: " + str(Engine.get_frames_per_second())
	
	
	
	
	
	
	_sync_boids_gpu()
	
	
	_update_data_texture()
	
	
	_update_boids_gpu(delta)
	
	
	
	
	
	
	for s in squads:
		
		s.update(delta)
		
	
	
	#excecute any queued actions
	
	_update_squad_bias_uniform()
	_update_boid_colors()
	
	
	
	queue_redraw()
	



func _draw() -> void:
	
	#draw_rect($boid_particles.visibility_rect, Color.AQUA)
	
	for s in squads:
		
		if s.formation != null:
			pass
		
		elif(!is_inf(s.goal.x)):
			draw_line(s.goal, s.appx_location, Color.GREEN, 30)
		#draw_circle(s.appx_location, 10, Color.GREEN)
		#draw_circle(s.goal, 10, Color.RED)
		
	
	pass

func _update_boids_gpu(delta):
	
	rd.free_rid(params_buffer)
	params_buffer = _generate_parameter_buffer(delta)
	params_uniform.clear_ids()
	params_uniform.add_id(params_buffer)
	
	
	#we update size and velocity buffers here!!!
	_swap_buffer_vals()
	
	
	
	uniform_set = rd.uniform_set_create(bindings, boid_compute_shader, 0)
	
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	
	#DANGER not really actually, im just not sure if 128 is the right number
	#rd.compute_list_dispatch(compute_list, ceil(NUM_BOIDS/128.), 1, 1)
	#Magic number!! 157 * 128 = 20096
	rd.compute_list_dispatch(compute_list, NUM_WORKGROUPS, 1, 1)
	rd.compute_list_end()
	rd.submit()
		

## Recieves work from gpu. is slow if gpu hasn't yet finished
func _sync_boids_gpu():
	rd.sync()
	
func _update_data_texture():
	
	
	
	var boid_data_image_data:PackedByteArray = rd.texture_get_data(boid_data_buffer, 0)
	boid_data.set_data(IMAGE_SIZE, IMAGE_SIZE, false, Image.FORMAT_RGBAF, boid_data_image_data)
	
	
	#updates boid_pos_active
	var boid_pos_bytes:PackedByteArray = boid_data.get_data()
	boid_pos_active = boid_pos_bytes.to_color_array()
	
	
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
	
	squad_bias_buffer = _generate_vec2_buffer(squad_biases)
	var squad_bias_uniform = _generate_uniform(squad_bias_buffer, RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 2)
	
	params_buffer = _generate_parameter_buffer(0)
	params_uniform = _generate_uniform(params_buffer, RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 3)
	
	var fmt := RDTextureFormat.new()
	fmt.width = IMAGE_SIZE
	fmt.height = IMAGE_SIZE
	fmt.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	
	var view := RDTextureView.new()
	boid_data_buffer = rd.texture_create(fmt, view, [boid_data.get_data()])
	var boid_data_buffer_uniform = _generate_uniform(boid_data_buffer, RenderingDevice.UNIFORM_TYPE_IMAGE, 4)
	
	bindings = [boid_pos_uniform, boid_vel_uniform, squad_bias_uniform, params_uniform, boid_data_buffer_uniform]
	
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
		#useless as of rn
		min_vel, 
		max_vel,
		
		alignment_factor,
		cohesion_factor,
		separation_factor,
		damp_factor,
		#remove soon
		get_viewport_rect().size.x,
		get_viewport_rect().size.y,
		
		delta]).to_byte_array()
	
	return rd.storage_buffer_create(params_buffer_bytes.size(), params_buffer_bytes)

func _exit_tree():
	
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
	rd.free_rid(squad_bias_buffer)
	
	
	
	rd.free()


func set_selected_bias(new_bias:Vector2):
	
	if selection_squad == -1:
		return
	
	squads[selection_squad].set_bias(new_bias)
	
	
	pass




func select_boids(new_selection:Array[int]):
	
	
	#sets color of former selection squad
	if selection_squad != -1:
		var new_color: Color = Color.from_ok_hsl(randf(), .8, .8)
		squads[selection_squad].set_color(new_color)
		
		
		
	
	
	if new_selection.is_empty():
		
		selection_squad = -1
		return
	
	
	
	
	
	#remeves selected boids from whatever squads they were in
	for b:int in new_selection:
		
		
		var squad_getting_removed_from:int = int(squad_indeces[b].x)
		
		
		
		#removes b from current squad
		squads[squad_getting_removed_from].remove_boid(int(squad_indeces[b].y))
		
		#if b's squad is now empty, adds to empty_squads
		if squads[squad_getting_removed_from].units.is_empty():
			empty_squads.insert(empty_squads.bsearch(squad_getting_removed_from), squad_getting_removed_from)
			
		
	
	
	
	#adds selection to either back or empty slot of squad structure
	if empty_squads.is_empty():
		
		selection_squad = squads.size()
		squads.append(Squad.new(new_selection, selection_squad))
		
		
	else:
		
		selection_squad = empty_squads[0]
		empty_squads.pop_front()
		squads[selection_squad] = Squad.new(new_selection, selection_squad)
		
		
	
	
	
	
	
	#clears any back bloat
	while !empty_squads.is_empty() && empty_squads.back() == squads.size() - 1:
		
		empty_squads.pop_back()
		squads.pop_back()
		
	
	
	pass


func select_squad(new_selection_squad:int):
	
	if new_selection_squad >= squads.size() || new_selection_squad < -1:
		return
	
	
	if selection_squad != -1:
		
		var new_color: Color = Color.from_ok_hsl(randf(), .8, .8)
		squads[selection_squad].set_color(new_color)
		
		pass
	
	if new_selection_squad != -1:
		
		
		squads[new_selection_squad].set_color(Color.WHITE)
		
		
		pass
	
	selection_squad = new_selection_squad
	
	pass


func queue_update_squad_bias_uniform():
	update_squad_bias_uniform = true

func _update_squad_bias_uniform():
	
	if ! update_squad_bias_uniform:
		return
	
	rd.free_rid(squad_bias_buffer)
	
	squad_bias_buffer = _generate_vec2_buffer(squad_biases)
	var squad_bias_uniform = _generate_uniform(squad_bias_buffer, RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 2)
	bindings[2] = squad_bias_uniform
	
	
	update_squad_bias_uniform = false

func queue_update_boid_colors():
	
	update_boid_color_tex = true

func _update_boid_colors():
	
	if !update_boid_color_tex:
		return
	
	var boid_colors_image_data:PackedByteArray = boid_colors.to_byte_array()
	boid_colors_image.set_data(IMAGE_SIZE, IMAGE_SIZE, false, Image.FORMAT_RGBAF, boid_colors_image_data)
	
	boid_colors_texture.update(boid_colors_image)
	
	pass


## changes num_boids, changes max_boids and tex if necissary, updates relevant uniforms
## perhaps do this over several frames?
func _add_boids():
	
	_resize_boid_lists()
	
	
	
	
	pass


## changes num_boids, changes max_boids and tex if necissary, updates relevant uniforms
func delete_boids(selection:Array[int]):
	
	#DANGER I want to get rid of this
	selection.sort()
	selection.reverse()
	
	remove_from_buffer = selection
	
	for b in selection:
		_delete_boid(b)
	
	
	
	if NUM_BOIDS <= 0:
		NUM_BOIDS = 1
	
	
	
	
	_resize_boid_lists()
	
	#boid_pos.resize(MAX_BOIDS)
	#boid_vel.resize(MAX_BOIDS)
	#squad_indeces.resize(MAX_BOIDS)
	
	pass

func _delete_boid(to_delete:int):
	
	NUM_BOIDS -= 1
	
	
	var to_delete_indeces:Vector2i = squad_indeces[to_delete]
	var last_active_indeces:Vector2i = squad_indeces[NUM_BOIDS]
	
	_swap_vals(squad_indeces, to_delete, NUM_BOIDS)
	_swap_vals(squad_biases, to_delete, NUM_BOIDS)
	_swap_vals(boid_colors, to_delete, NUM_BOIDS)
	
	
	
	squads[last_active_indeces.x].units[last_active_indeces.y] = to_delete
	squads[to_delete_indeces.x].units[to_delete_indeces.y] = NUM_BOIDS
	
	squads[to_delete_indeces.x].remove_boid(to_delete_indeces.y)
	
	
	
	
	
	#remove_from_buffer.append(to_delete)
	
	pass

## Swaps two given indeces in given array/vector/dict/ anything using '[]' operator
func _swap_vals(array: Variant, first:int, second:int):
	
	if first == second:
		return
	
	var temp:Variant = array[first]
	array[first] = array[second]
	array[second] = temp


## perhaps do this over several frames?
func _swap_buffer_vals():
	
	if remove_from_buffer == []:
		return
	
	var last_index:int = NUM_BOIDS + remove_from_buffer.size()
	
	
	var pos_swap:PackedVector2Array = rd.buffer_get_data(boid_pos_buffer).to_vector2_array()
	var vel_swap:PackedVector2Array = rd.buffer_get_data(boid_vel_buffer).to_vector2_array()
	
	
	for b in remove_from_buffer:
		
		
		last_index -= 1
		
		if b >= last_index:
			continue
		
		
		_swap_vals(pos_swap, b, last_index)
		_swap_vals(vel_swap, b, last_index)
		
		
		
		
		pass
	
	
	var pos_bytes:PackedByteArray = pos_swap.to_byte_array()
	var vel_bytes:PackedByteArray = vel_swap.to_byte_array()
	
	
	rd.buffer_update(boid_pos_buffer, 0, pos_bytes.size(), pos_bytes)
	rd.buffer_update(boid_vel_buffer, 0, vel_bytes.size(), vel_bytes)
	
	
	$boid_particles.amount = NUM_BOIDS
	
	remove_from_buffer = []
	
	pass


func _resize_boid_lists():
	
	
	
	
	
	
	pass
