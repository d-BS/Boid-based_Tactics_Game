class_name Squad

static var boid_manager:Node2D
var units: Array[int]

var goal: Vector2 = Vector2.INF
var color:Color
var formation:Formation = null

#ACTUALLY WHY IS THIS DOING ANYTHING???
#if I get rid of this variable WHICH DOES NOTHING
#then it crashes whenever i make a formation
static var f_just_pressed:bool = false

var update_uniform:bool = false

static var num_of_squads:int = 0
var squad_id:int

var appx_location:Vector2 = Vector2.ZERO

func _init(new_units:Array[int], squad_num:int, new_goal:Vector2 = Vector2.INF, new_color:Color = Color.WHITE):
	
	#loops through and lets each unit know where it is in the squad
	for i in new_units.size():
		
		boid_manager.squad_indeces[new_units[i]] = Vector2(squad_num, i)
		
		boid_manager.boid_colors[new_units[i]] = new_color
		
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
	
	
	boid_manager.squad_biases[units[index]] = Vector2.INF
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
	
	goal = new_bias
	
	if new_bias == Vector2.INF:
		formation = null
	
	if formation != null:
		formation.location = new_bias
		
		
		for i in units.size():
			boid_manager.squad_biases[units[i]] = formation.pos[i] + formation.location
		
		boid_manager.queue_update_squad_bias_uniform()
	

func update(_delta:float):
	
	#makes sure only one squad does work per frame
	var avg_pos_needed:bool = (Engine.get_frames_drawn() + squad_id) % num_of_squads == 0
	avg_pos_needed = avg_pos_needed && formation == null
	
	
	
	
	if avg_pos_needed:
		
		boid_manager.queue_update_squad_bias_uniform()
		
		
		var new_location: Vector2 = Vector2.ZERO
		for b in units:
			
			#sums locations for new appx location
			var unit_location_color:Color = boid_manager.boid_pos_active[b]
			var unit_location:Vector2 = Vector2(unit_location_color.r, unit_location_color.g)
			new_location += unit_location
			
			
			
			if goal == Vector2.INF:
				boid_manager.squad_biases[b] = Vector2.INF
			
			else:
				boid_manager.squad_biases[b] = goal + (unit_location - appx_location)
			
			
			
		
		
		
		appx_location = new_location / units.size()
	
	
	
	
	
	# Magic number 4 for when it dertermines when theyve arrived
	if goal.distance_squared_to(appx_location) < 16:
		
		set_bias(Vector2.INF)
		##OR turn off formation - probably not honestly
		
		print("Goal reached!")
		
		pass
	
	
	
	
	
	pass


## way too hardcoded - needs to be refactored later
func set_formation():
	
	var new_formation = Formation.new(units.size())
	
	if formation != null:
		new_formation.location = formation.location
		
	elif goal == Vector2.INF:
		new_formation.location = appx_location
	else:
		new_formation.location = goal
	
	formation = new_formation
	
	#DANGER dont like this
	for i in units.size():
		
		boid_manager.squad_biases[units[i]] = formation.pos[i] + formation.location
		
	
	
	boid_manager.queue_update_squad_bias_uniform()
	
	pass


func set_color(new_color:Color):
	
	
	for i in units.size():
		
		boid_manager.boid_colors[units[i]] = new_color
		
		
	
	color = new_color
	
	boid_manager.queue_update_boid_colors()
	
