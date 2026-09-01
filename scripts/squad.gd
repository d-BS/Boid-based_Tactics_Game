class_name Squad

static var boid_manager:Node2D
var units: Array[int]

var goal: Vector2 = Vector2.INF
var squad_bias: Vector2 = Vector2.ZERO
var color:Color
var formation:Formation = null

#static var squad_bias_min: float = 500
#static var squad_bias_min_squared: float = squad_bias_min * squad_bias_min
#static var squad_bias_max: float = 1000
#static var squad_bias_max_squared:float = squad_bias_max * squad_bias_max

static var num_of_squads:int = 0
var squad_id:int

var appx_location:Vector2 = Vector2.ZERO

func _init(new_units:Array[int], squad_num:int = 0, new_goal:Vector2 = Vector2.INF, new_color:Color = Color.WHITE):
	
	#loops through and lets each unit know where it is in the squad
	for i in new_units.size():
		
		boid_manager.squad_indeces[new_units[i]] = Vector2(squad_num, i)
		
		boid_manager.squad_color[new_units[i]] = new_color
		
		#if squadnum == 0, color = ugly blue, else random oklab
		#Color.SKY_BLUE
		#boid_manager.squadcolor[i] = squad color
		
	
	goal = new_goal
	color = new_color
	
	num_of_squads += 1
	squad_id = squad_num
	units = new_units
	
	
	pass

func remove_boid(index:int):
	
	
	
	boid_manager.squad_biases[units[index]] = Vector2.ZERO
	boid_manager.bias_locations[units[index]] = Vector2.INF
	boid_manager.squad_indeces[units[index]] = Vector2.ZERO
	
	#should swap toremove w back
	units[index] = units.back()
	
	#updates moved unit, pops toremove
	boid_manager.squad_indeces[units[index]].y = index
	units.pop_back()
	
	if(units.is_empty()):
		num_of_squads -= 1
	
	pass

func set_bias(new_bias:Vector2):
	
	if(units.is_empty()):
		return
	
	goal = new_bias
	
	for b in units:
		
		boid_manager.bias_locations[b] = goal
		
	
	#applies changes
	
	boid_manager.rd.free_rid(boid_manager.boid_bias_loc_buffer)
	
	boid_manager.boid_bias_loc_buffer = boid_manager._generate_vec2_buffer(boid_manager.bias_locations)
	var boid_bias_loc_uniform = boid_manager._generate_uniform(boid_manager.boid_bias_loc_buffer, RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 2)
	boid_manager.bindings[2] = boid_bias_loc_uniform
	

func update(_delta:float):
	
	#makes sure only one squad does work per frame
	var productive:bool = (Engine.get_frames_drawn() + squad_id) % num_of_squads == 0
	
	if(goal == Vector2.INF):
		squad_bias = Vector2.ZERO
	elif(productive):
		
		squad_bias = goal - appx_location
		
		#var bias_len_squared:float = squad_bias.length_squared()
		
		#must be at least trying to get to the goal
		#if bias_len_squared < squad_bias_min_squared:
			
		#	squad_bias = squad_bias.normalized() * squad_bias_min
			
		#elif bias_len_squared > squad_bias_max_squared:
			
		#	squad_bias = squad_bias.normalized() * squad_bias_max
		
		#magic number!!
		squad_bias = squad_bias.normalized() * 1000
	
	
	
	var new_location: Vector2 = Vector2.ZERO
	
	
	var iterator:int = 0
	
	for b in units:
		
		#sums locations for new av location
		var unit_location_color:Color = boid_manager.boid_pos_active[b]
		new_location += Vector2(unit_location_color.r, unit_location_color.g)
		
		
		
		if formation == null:
			boid_manager.squad_biases[b] = squad_bias
		else:
			boid_manager.bias_locations[b] = formation.pos[iterator] + appx_location 
		
		
		iterator += 1
		
	
	
	if(productive):
		
		boid_manager.rd.free_rid(boid_manager.squad_bias_buffer)
		
		boid_manager.squad_bias_buffer = boid_manager._generate_vec2_buffer(boid_manager.squad_biases)
		var squad_bias_uniform = boid_manager._generate_uniform(boid_manager.squad_bias_buffer, RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 3)
		boid_manager.bindings[3] = squad_bias_uniform
	
	appx_location = new_location / units.size()
	
	
	# Magic number 4 for when it dertermines when theyve arrived
	if goal.distance_squared_to(appx_location) < 16:
		
		#DANGER BECAUSE WE LOOP THROUGH B AGAIN
		set_bias(Vector2.INF)
		
		print("Goal reached!")
		
		pass
	
	pass


## test func for now
func set_formation():
	
	formation = Formation.new(units.size())
	
	
	pass
