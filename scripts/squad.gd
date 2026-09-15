class_name Squad

static var boid_manager:Node2D

var units: PackedInt32Array

## only updated on _calc_appx_loc
var unit_locations: PackedVector2Array

var color:Color
var formation:Formation = null


var update_uniform:bool = false

static var num_of_squads:int = 0
var squad_id:int

var appx_location:Vector2 = Vector2.ZERO

func _init(new_units:Array[int], squad_num:int, new_goal:Vector2 = Vector2.INF, new_color:Color = Color.WHITE):
	
	
	#loops through and lets each unit know where it is in the squad
	for i in new_units.size():
		
		boid_manager.squad_indeces[new_units[i]] = Vector2(squad_num, i)
		
		boid_manager.boid_colors[new_units[i]] = new_color
		
		
	
	_calc_appx_loc()
	
	color = new_color
	
	num_of_squads += 1
	squad_id = squad_num
	units = new_units
	
	if new_goal != Vector2.INF:
		
		pass
	
	pass

func remove_boid(index:int):
	
	
	boid_manager.squad_biases[units[index]] = Vector2.INF
	boid_manager.squad_indeces[units[index]] = Vector2.ZERO
	
	#should swap toremove w back
	units[index] = units[units.size() - 1]
	#updates moved unit, pops toremove
	boid_manager.squad_indeces[units[index]].y = index
	units.resize(units.size() - 1)
	
	if(units.is_empty()):
		num_of_squads -= 1
	
	pass

func set_bias(new_bias:Vector2):
	
	
	if new_bias == Vector2.INF:
		formation = null
		
		for i in units.size():
			boid_manager.squad_biases[units[i]] = new_bias
		
	
	elif formation != null:
		formation.location = new_bias
		
		for i in units.size():
			boid_manager.squad_biases[units[i]] = formation.pos[i] + formation.location
	
	else:
		
		set_formation("mob", new_bias)
		
		pass
	
	boid_manager.queue_update_squad_bias_uniform()
	

func update(_delta:float):
	
	if(units.size() == 0):
		return
	
	
	
	pass


## way too hardcoded - needs to be refactored later
func set_formation(type:String, goal:Vector2 = Vector2.INF):
	
	
	_calc_appx_loc()
	
	
	var new_formation = Formation.new(units.size())
	
	match(type):
		"mob":
			new_formation.create_form_mob(unit_locations, appx_location)
		"rect":
			new_formation.create_form_rect()
	
	if(goal!=Vector2.INF):
		new_formation.location = goal
	
	elif formation != null:
		new_formation.location = formation.location
		
	else:
		new_formation.location = appx_location
		
	
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
	

## DANGER Pricy
func _calc_appx_loc():
	
	
	var new_location: Vector2 = Vector2.ZERO
	unit_locations.resize(units.size())
	
	var i:int = 0
	
	for b in units:
		
		#sums locations for new appx location
		var unit_location:Vector4 = boid_manager.boid_pos_active[b]
		unit_locations[i] = Vector2(unit_location.x, unit_location.y)
		new_location += unit_locations[i]
		
		i += 1
		
	
	appx_location = new_location / units.size()
	
	
	pass
