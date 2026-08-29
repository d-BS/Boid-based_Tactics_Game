extends Node2D

@export var mMeshInstance:MultiMeshInstance2D

var boid_num:int = 0
var emptymMeshIDs: Array[int]



var SIMULATE_GPU:bool = false

#TODO: make actual squad class
#-list of boids
#-bias -> gives each member a shared bias DIRECTION to avoid merging?
#potentially: (likely not)
#-holds weight info, and updates

class Squad:
	
	var units: Array[Boid]
	
	
	var bias_vector: Vector2 = Vector2.ZERO
	var goal: Vector2 = Vector2.INF
	
	static var squad_bias_min: float = 500
	static var squad_bias_min_squared: float = squad_bias_min * squad_bias_min
	static var squad_bias_max: float = 1000
	static var squad_bias_max_squared:float = squad_bias_max * squad_bias_max
	
	var appx_location:Vector2 = Vector2.ZERO
	
	static var boid_manager:Node2D
	
	
	func _init(boids:Array[Boid]):
		
		
		units = boids
		
		var squad_index:int = 0
		
		for b in boids:
			
			b.squad_id[1] = squad_index
			squad_index += 1
			
			appx_location += b.position
		
		appx_location /= boids.size()
		
		
	
	
	func remove_boid(index:int):
		
		#should swap toremove w back
		#var temp: Boid = units[index]
		units[index].squad_bias = Vector2.ZERO
		units[index] = units.back()
		#units[units.size() - 1] = temp
		
		#updates moved unit, pops toremove
		units[index].squad_id[1] = index
		units.pop_back()
		
		#add delete self?!?
		
		pass
	
	func set_bias(new_bias:Vector2):
		
		
		goal = new_bias
		
		for b in units:
			
			b.bias_loc = goal
			
			if b.is_sleeping:
				b.wake(b.position.direction_to(goal) * b.wakeup_cutoff)
			
		
	
	
	func update(delta:float):
		
		
		if(goal != Vector2.INF):
			
			bias_vector = goal - appx_location
			var bias_len_squared:float = bias_vector.length_squared()
			
			#must be at least trying to get to the goal
			if bias_len_squared < squad_bias_min_squared:
				
				bias_vector = bias_vector.normalized() * squad_bias_min
				
			elif bias_len_squared > squad_bias_max_squared:
				
				bias_vector = bias_vector.normalized() * squad_bias_max
			
		else:
			bias_vector = Vector2.ZERO
		
		var new_location: Vector2 = Vector2.ZERO
		
		for b in units:
			
			b.squad_bias = bias_vector
			new_location += b.position
			
			boid_manager.mMeshInstance.multimesh.set_instance_transform_2d(b.multimesh_index, Transform2D(0, b.position))
			
			
			#update boids
			if b.is_sleeping:
				continue
			
			
			b.update(delta, b.get_overlapping_areas())
			
			
		
		
		appx_location = new_location / units.size()
		
		# Magic number 4 for when it dertermines when theyve arrived
		if goal.distance_squared_to(appx_location) < 1:
			
			#DANGER BECAUSE WE LOOP THROUGH B AGAIN
			set_bias(Vector2.INF)
			
			print("Goal reached!")
			
			pass
		
		pass
	
	pass


## squad 0 is selected boids
var squads:Array[Squad]
var empty_squads:Array[int]

@export var draw_velocity: bool = true:
	set(value):
		queue_redraw()
		draw_velocity = value


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	
	
	#creates empty first element
	squads.push_back(Squad.new([]))
	squads[0].boid_manager = self
	
	seed(2)
	
	spawn_boids(1000, get_viewport_rect())
	#spawn_boids(30, Rect2(0, 0, 100, 100))
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	
	for s in squads:
		
		
		s.update(delta)
		
		#for b in s.units:
			
		
			#show sleepers
		
		#	if b.is_sleeping && mMeshInstance.multimesh.get_instance_color(b.multimesh_index) != Color.SKY_BLUE:
		#		mMeshInstance.multimesh.set_instance_color(b.multimesh_index, Color.RED)
		#	elif !b.is_sleeping && mMeshInstance.multimesh.get_instance_color(b.multimesh_index) != Color.SKY_BLUE:
		#		mMeshInstance.multimesh.set_instance_color(b.multimesh_index, Color.BLACK)
		#	pass
	
	
	if draw_velocity:
		queue_redraw()
		
	
	pass

func _draw() -> void:
	
	if draw_velocity:
		
		#draw_circle(s.appx_location, 5, Color.BLUE)
		#if(s.goal != Vector2.INF):
		#	draw_circle(s.goal, 5, Color.GREEN)
		for s in squads:
		
			for b in s.units:
				draw_line(b.position, b.position + b.velocity, Color.WHITE)
	
	


func spawn_boids(num:int, rect:Rect2):
	
	deselect_boids()
	#GET RID OF BOIDLIST, USE SQADS INSTEAD
	
	var selection: Array[Boid]
	selection.resize(num)
	
	mMeshInstance.multimesh.instance_count += num
	mMeshInstance.multimesh.visible_instance_count += num
	
	for i in range(num):
		
		selection[i] = Boid.new()
		selection[i].position = Vector2(randf_range(rect.position.x, rect.size.x), randf_range(rect.position.y, rect.size.y))
		selection[i].multimesh_index = boid_num + i
		
		
		
		
		
		add_child(selection[i])
		mMeshInstance.multimesh.set_instance_color(selection[i].multimesh_index, Color.BLACK)
		
		#set squad, if applicable, let it know its id, etc
	
	squads[0] = Squad.new(selection)
	
	boid_num += num
	
	pass

#TODO: move the code for calculating wether boids are within rectangle over here
func select_boids(selection:Array[Boid]):
	
	deselect_boids()
	
	
	#loops through selection, adds to squad 0, the 'selection squad'
	for b in selection:
		
		#remove from current squad, if in one
		if b.squad_id != null:
			
			squads[b.squad_id[0]].remove_boid(b.squad_id[1])
			
			#keeps track of availible squad nums
			if squads[b.squad_id[0]].units.is_empty():
				
				empty_squads.insert(empty_squads.bsearch(b.squad_id[0]), b.squad_id[0])
				
		
		
		#removes current bias
		b.bias_loc = Vector2.INF
		
		#recolors it so it looks 'selected'
		mMeshInstance.multimesh.set_instance_color(b.multimesh_index, Color.SKY_BLUE)
		
		pass
	
	
	#clears any back bloat
	while !empty_squads.is_empty() && empty_squads.back() == squads.size() - 1:
		
		empty_squads.pop_back()
		squads.pop_back()
	
	
	#officially adds selection to the squad
	squads[0] = Squad.new(selection)
	
	
	pass

## moves boids currently in 'selection squad' into a normal squad
func deselect_boids():
	
	if squads[0].units.is_empty():
		return
	
	var new_squad: int
	
	if empty_squads.is_empty():
		new_squad = squads.size()
		squads.append(null)
	else:
		new_squad = empty_squads.pop_front()
	
	for b in squads[0].units:
		
		b.squad_id[0] = new_squad
		mMeshInstance.multimesh.set_instance_color(b.multimesh_index, Color.BLACK)
	
	squads[new_squad] = squads[0]
	
	
	squads[0] = Squad.new([])
	
	pass



func set_selected_bias(new_bias:Vector2):
	
	
	squads[0].set_bias(new_bias)
	
	
	pass
