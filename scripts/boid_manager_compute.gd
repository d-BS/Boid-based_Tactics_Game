extends Node2D
var DEBUG_LOG = false

## current number of boids
var num_boids:int = 250_000
#current cap: 500_000

## maximum boids that current setup can handle w/o reallocating stuff, 
## set to nearest multiple of 128
var max_boids:int = num_boids + (0 if (num_boids % 128 == 0) else (128 - num_boids % 128))


@warning_ignore("integer_division")
var num_workgroups:int = max_boids / 128


#TODO:
#
#
#Have goal-less boids removed from squad structure overall?
#
#fix deletion wierdness or at least understand why its happening
#
#split boid manager into cpu-focused script and gpu-focused script?
#I think that may be better than the mess I have now
#
#add more kinds of formations, remove hardcoding
#have finer-tune control of formation during gameplay, add ui for this
#
#
#be able to create boids, have boids be killed, etc
#create faction system for this - no friendly fire, etc
#create wall 'faction' for destructable terrain
#
#
#make pos_buffer/vel_buffer single vec4 array
#
#
#Optimizations for later:
#
#Convert vec2 arrays to vec2i arrays / int arrays twice as long?
#In shader, convert distance to dist^2, reduce normalize, etc
#

#buffers-to-be
var boid_pos:PackedVector2Array = []
var boid_vel:PackedVector2Array = []
var squad_biases:PackedVector2Array = []

var bin_dims:Vector2 = Vector2(1500, 1500)
var bin_offset:Vector2 = -bin_dims * 35 / 5
var bin_first:PackedInt32Array = []
var bin_first_bytes:PackedByteArray
var bin_next:PackedInt32Array = []
var bin_next_bytes:PackedByteArray





## contains positions of boids, and is actively updated
var boid_pos_active:PackedVector4Array = []

## Each unit's location within the squad structure
var squad_indeces:PackedVector2Array

#list of squads
var squads:Array[Squad]

#which squad is selected
var selection_squad:int = -1

#lists which squads are empty
var empty_squads:Array[int] = []

#textures that store information for particle shader
var IMAGE_SIZE:int = int(ceil(sqrt(max_boids)))
var boid_data : Image
var boid_data_texture : ImageTexture
var boid_data_address : Texture2DRD
var boid_colors_image : Image
var boid_colors_texture : ImageTexture

var boid_colors:PackedColorArray


var vision_radius:float = 35
var avoid_radius:float = 25
#var min_vel:float = 0
#formerly 60, also not doing anything, 30
#var max_vel:float = 30.0
#formerly .5
var alignment_factor:float = -.7
#formerly -.05
var cohesion_factor:float = -.05
#formerly 10, then 15 w old formula, .25 w new
var separation_factor:float = .3
var damp_factor:float = 1.5


# GPU Variables
var rd : RenderingDevice
var boid_compute_shader : RID
var pipeline : RID

var bindings_0 : Array
var bindings_1 : Array
var uniform_set_0 : RID
var uniform_set_1 : RID

#buffers
var boid_pos_buffer : RID
var boid_vel_buffer : RID
var squad_bias_buffer:RID
var bin_matrix_buffer : RID
var bin_next_buffer : RID
var params_buffer_0 : RID
var params_buffer_1 : RID
var boid_data_buffer : RID

#uniforms
var boid_pos_uniform : RDUniform
var boid_vel_uniform : RDUniform
var squad_bias_uniform : RDUniform
var bin_matrix_uniform : RDUniform
var bin_next_uniform : RDUniform
var params_uniform_0 : RDUniform
var params_uniform_1 : RDUniform
var boid_data_buffer_uniform : RDUniform




#different queue variables

var update_squad_bias_uniform:bool = false
var update_boid_color_tex:bool = false

var remove_from_buffer:Array[int] = []


@warning_ignore("unused_signal")
signal squads_updated


func _ready():
	
	#Engine.time_scale = 10
	
	#seed(0)
	
	boid_data = Image.create_empty(IMAGE_SIZE, IMAGE_SIZE, false, Image.FORMAT_RGBAF)
	boid_data_texture = ImageTexture.create_from_image(boid_data)
	boid_colors_image = Image.create_empty(IMAGE_SIZE, IMAGE_SIZE, false, Image.FORMAT_RGBAF)
	boid_colors_texture = ImageTexture.create_from_image(boid_colors_image)
	
	
	squad_biases.resize(max_boids)
	squad_biases.fill(Vector2.INF)
	
	boid_colors.resize(IMAGE_SIZE * IMAGE_SIZE)
	boid_colors.fill(Color.BLACK)
	
	bin_first.resize(bin_dims.x * bin_dims.y)
	bin_first.fill(-1)
	bin_first_bytes = bin_first.to_byte_array()
	bin_first.clear()
	
	bin_next.resize(max_boids)
	bin_next.fill(-1)
	bin_next_bytes = bin_next.to_byte_array()
	bin_next.clear()
	
	
	_initial_boid_setup()
	queue_update_boid_colors()
	
	$boid_particles.amount = num_boids
	#$boid_particles.process_material.set_shader_parameter("boid_data", boid_data_address)
	$boid_particles.process_material.set_shader_parameter("boid_data", boid_data_texture)
	$boid_particles.process_material.set_shader_parameter("boid_colors", boid_colors_texture)
	
	
	#DANGER (potentially?) (using .INF in this situation feels wrong)
	$boid_particles.visibility_rect = Rect2(-Vector2.INF, Vector2.INF)
	
	
	#RenderingServer.call_on_render_thread(_setup_compute_shader)
	#RenderingServer.call_on_render_thread(_update_boids_gpu)
	
	_setup_compute_shader()
	_update_boids_gpu(0)
	
	queue_redraw()
	
	#destroys the now-useless buffers
	boid_pos.clear()
	boid_vel.clear()
	

## FIX LATER
func _initial_boid_setup():
	
	var array_o_boids:Array[int]
	array_o_boids.resize(num_boids)
	boid_pos.resize(max_boids)
	boid_vel.resize(max_boids)
	squad_indeces.resize(max_boids)
	
	for i in num_boids:
		
		boid_pos[i] = Vector2(randf() * IMAGE_SIZE * 50, randf()  * IMAGE_SIZE * 50)
		boid_vel[i] = Vector2.ZERO#Vector2(randf_range(-1.0, 1.0) * max_vel, randf_range(-1.0, 1.0) * max_vel)
		array_o_boids[i] = i
		squad_indeces[i] = Vector2(0, i)
	
	
	squads = [Squad.new([], 0)]
	squads[0].boid_manager = self
	squads[0].units = array_o_boids


func _process(delta):
	
	
	
	get_window().title = "Boids: " + str(num_boids) + " / FPS: " + str(Engine.get_frames_per_second())
	
	
	
	_sync_boids_gpu()
	
	#RenderingServer.call_on_render_thread(_update_data_texture)
	#RenderingServer.call_on_render_thread(Callable.create(self, "_update_boids_gpu").bind(delta))
	
	
	_update_data_texture()
	_update_boids_gpu(delta)
	
	
	
	
	for s in squads:
		
		s.update(delta)
		
	
	#excecute any queued actions
	_update_squad_bias_uniform()
	_update_boid_colors()
	
	



func _draw() -> void:
	
	draw_rect(Rect2(bin_offset, bin_dims * vision_radius), Color.AQUAMARINE, false, 30)
	
	pass

func _update_boids_gpu(delta):
	
	#reset perameters each frame
	rd.free_rid(params_buffer_1)
	params_buffer_1 = _generate_parameter_buffer(delta, 1)
	params_uniform_1.clear_ids()
	params_uniform_1.add_id(params_buffer_1)
	
	
	#clears bin buffers
	rd.buffer_update(bin_matrix_buffer, 0, bin_first_bytes.size(), bin_first_bytes)
	rd.buffer_update(bin_next_buffer, 0, bin_next_bytes.size(), bin_next_bytes)
	
	
	#we update size and velocity buffers here!!!
	#replace w better func later!
	_swap_buffer_vals()
	#_update_pos_vel_buffer_vals()
	
	
	
	uniform_set_0 = rd.uniform_set_create(bindings_0, boid_compute_shader, 0)
	
	uniform_set_1 = rd.uniform_set_create(bindings_1, boid_compute_shader, 0)
	
	
	
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set_0, 0)
	
	#DANGER not really actually, im just not sure if 128 is the right number
	
	#first pass, does binning
	rd.compute_list_dispatch(compute_list, num_workgroups, 1, 1)
	#barrier which is important apparently
	
	rd.compute_list_add_barrier(compute_list)
	
	
	#second pass
	
	rd.compute_list_bind_uniform_set(compute_list, uniform_set_1, 0)
	rd.compute_list_dispatch(compute_list, num_workgroups, 1, 1)
	
	
	
	rd.compute_list_end()
	rd.submit()
	

## Recieves work from gpu. is slow if gpu hasn't yet finished
func _sync_boids_gpu():
	rd.sync()
	pass
func _update_data_texture():
	
	
	
	
	var start_time = Time.get_ticks_usec()
	
	
	var boid_data_image_data:PackedByteArray = rd.texture_get_data(boid_data_buffer, 0)
	
	
	
	
	var end_time = Time.get_ticks_usec()
	var total_time = end_time - start_time
	
	if(Engine.get_frames_drawn() % 100 == 0):
	#	print("Code took: ", total_time, " microseconds")
		pass
	
	
	boid_data.set_data(IMAGE_SIZE, IMAGE_SIZE, false, Image.FORMAT_RGBAF, boid_data_image_data)
	
	boid_data_texture.update(boid_data)
	
	#updates boid_pos_active
	boid_pos_active = boid_data_image_data.to_vector4_array()
	
	
	#$boid_particles.process_material.set_shader_parameter("boid_data", boid_data_address)
	
	
	pass

func _setup_compute_shader():
	
	rd = RenderingServer.create_local_rendering_device()
	
	#rd = RenderingServer.get_rendering_device()
	
	var shader_file := load("res://scripts/boid_compute_shader.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	boid_compute_shader = rd.shader_create_from_spirv(shader_spirv)
	pipeline = rd.compute_pipeline_create(boid_compute_shader)
	
	boid_pos_buffer = _generate_vec2_buffer(boid_pos)
	boid_pos_uniform = _generate_uniform(boid_pos_buffer, RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 0)
	
	boid_vel_buffer = _generate_vec2_buffer(boid_vel)
	boid_vel_uniform = _generate_uniform(boid_vel_buffer, RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 1)
	
	squad_bias_buffer = _generate_vec2_buffer(squad_biases)
	squad_bias_uniform = _generate_uniform(squad_bias_buffer, RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 2)
	
	bin_matrix_buffer = _generate_int_array_buffer(bin_first_bytes)
	bin_matrix_uniform = _generate_uniform(bin_matrix_buffer, RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 3)
	
	bin_next_buffer = _generate_int_array_buffer(bin_next_bytes)
	bin_next_uniform = _generate_uniform(bin_next_buffer, RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 4)
	
	params_buffer_0 = _generate_parameter_buffer(0, 0)
	params_uniform_0 = _generate_uniform(params_buffer_0, RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 5)
	
	params_buffer_1 = _generate_parameter_buffer(0, 1)
	params_uniform_1 = _generate_uniform(params_buffer_1, RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 5)
	
	var fmt := RDTextureFormat.new()
	fmt.width = IMAGE_SIZE
	fmt.height = IMAGE_SIZE
	fmt.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT \
					| RenderingDevice.TEXTURE_USAGE_STORAGE_BIT \
					| RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT \
					| RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT \
					| RenderingDevice.TEXTURE_USAGE_CPU_READ_BIT
	
	
	var view := RDTextureView.new()
	
	#Texture2DRD
	
	
	boid_data_buffer = rd.texture_create(fmt, view, [boid_data.get_data()])
	boid_data_buffer_uniform = _generate_uniform(boid_data_buffer, RenderingDevice.UNIFORM_TYPE_IMAGE, 6)
	
	
	#boid_data_address = Texture2DRD.new()
	#boid_data_address.texture_rd_rid = boid_data_buffer
	
	bindings_0 = [boid_pos_uniform, boid_vel_uniform, squad_bias_uniform, bin_matrix_uniform, bin_next_uniform, params_uniform_0, boid_data_buffer_uniform]
	bindings_1 = [boid_pos_uniform, boid_vel_uniform, squad_bias_uniform, bin_matrix_uniform, bin_next_uniform, params_uniform_1, boid_data_buffer_uniform]
	
func _generate_vec2_buffer(data):
	var data_buffer_bytes := PackedVector2Array(data).to_byte_array()
	var data_buffer = rd.storage_buffer_create(data_buffer_bytes.size(), data_buffer_bytes)
	return data_buffer

func _generate_int_array_buffer(data:PackedByteArray):
	var data_buffer = rd.storage_buffer_create(data.size(), data)
	return data_buffer

func _generate_uniform(data_buffer, type, binding):
	var data_uniform = RDUniform.new()
	data_uniform.uniform_type = type
	data_uniform.binding = binding
	data_uniform.add_id(data_buffer)
	return data_uniform

func _generate_parameter_buffer(delta, pass_number):
	var params_buffer_bytes : PackedByteArray = PackedFloat32Array(
		[num_boids, 
		IMAGE_SIZE, 
		
		vision_radius,
		avoid_radius,
		
		bin_dims.x, 
		bin_dims.y,
		
		bin_offset.x,
		bin_offset.y,
		
		alignment_factor,
		cohesion_factor,
		separation_factor,
		damp_factor,
		
		pass_number,
		
		delta]).to_byte_array()
	
	return rd.storage_buffer_create(params_buffer_bytes.size(), params_buffer_bytes)

func _exit_tree():
	
	_sync_boids_gpu()
	
	
	if boid_data_buffer.is_valid():
		rd.free_rid(boid_data_buffer)
	if params_buffer_0.is_valid():
		rd.free_rid(params_buffer_0)
	if params_buffer_1.is_valid():
		rd.free_rid(params_buffer_1)
	if boid_pos_buffer.is_valid():
		rd.free_rid(boid_pos_buffer)
	if boid_vel_buffer.is_valid():
		rd.free_rid(boid_vel_buffer)
	if pipeline.is_valid():
		rd.free_rid(pipeline)
	if boid_compute_shader.is_valid():
		rd.free_rid(boid_compute_shader)
	if squad_bias_buffer.is_valid():
		rd.free_rid(squad_bias_buffer)
	
	if bin_matrix_buffer.is_valid():
		rd.free_rid(bin_matrix_buffer)
	if bin_next_buffer.is_valid():
		rd.free_rid(bin_next_buffer)
	
	#DANGER these two doesn't like being freed
	if uniform_set_0.is_valid():
		rd.free_rid(uniform_set_0)
		pass
	if uniform_set_1.is_valid():
		rd.free_rid(uniform_set_1)
		pass
	
	
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
		
	
	
	queue_update_boid_colors()
	
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
	squad_bias_uniform = _generate_uniform(squad_bias_buffer, RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 2)
	bindings_0[2] = squad_bias_uniform
	bindings_1[2] = squad_bias_uniform
	
	
	
	update_squad_bias_uniform = false

func queue_update_boid_colors():
	
	update_boid_color_tex = true

func _update_boid_colors():
	
	if !update_boid_color_tex:
		return
	
	#16 bytes per pixel
	var boid_colors_image_data:PackedByteArray = boid_colors.to_byte_array()
	boid_colors_image.set_data(IMAGE_SIZE, IMAGE_SIZE, false, Image.FORMAT_RGBAF, boid_colors_image_data)
	
	boid_colors_texture.update(boid_colors_image)
	
	
	update_boid_color_tex = false
	
	pass


## changes num_boids, changes max_boids and tex if necissary, updates relevant uniforms
## perhaps do this over several frames?
func _add_boids(amount:int, _area:Rect2):
	
	if num_boids + amount > max_boids:
		amount = max_boids - num_boids
	
	
	
	
	
	pass


## changes num_boids, changes max_boids and tex if necissary, updates relevant uniforms
func delete_boids(selection:Array[int]):
	
	#DANGER I want to get rid of this, but Im worried its nessicary
	selection.sort()
	selection.reverse()
	
	remove_from_buffer.append_array(selection)
	
	for b in selection:
		_delete_boid(b)
	
	
	
	if num_boids <= 0:
		num_boids = 1
	
	
	$boid_particles.amount = num_boids
	
	
	pass

func _delete_boid(to_delete:int):
	
	num_boids -= 1
	
	
	var to_delete_indeces:Vector2i = squad_indeces[to_delete]
	var last_active_indeces:Vector2i = squad_indeces[num_boids]
	
	_swap_vals(squad_indeces, to_delete, num_boids)
	_swap_vals(squad_biases, to_delete, num_boids)
	_swap_vals(boid_colors, to_delete, num_boids)
	
	
	
	squads[last_active_indeces.x].units[last_active_indeces.y] = to_delete
	squads[to_delete_indeces.x].units[to_delete_indeces.y] = num_boids
	
	squads[to_delete_indeces.x].remove_boid(to_delete_indeces.y)
	
	
	queue_update_boid_colors()
	queue_update_squad_bias_uniform()
	
	
	#remove_from_buffer.append(to_delete)
	
	pass

## Swaps two given indeces in given array/vector/dict/ anything using '[]' operator that is also passed by reference
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
	
	var last_index:int = num_boids + remove_from_buffer.size()
	
	
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
	
	
	
	remove_from_buffer = []
	
	pass

## change the buffer (once its a single vec4 array) to new values
func _update_pos_vel_buffer_vals():
	
	
	
	
	pass
