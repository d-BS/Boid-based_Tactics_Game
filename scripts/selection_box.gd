extends Node2D

var dragging:bool = false
var selectionRect:Rect2
@export var boid_manager:Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	selectionRect = Rect2(0, 0, 0, 0)
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	if Input.is_action_just_pressed("click"):
		
		dragging = true
		
		
	elif Input.is_action_just_released("click"):
		
		#_finalize_selection_using_overlapping_areas()
		if!boid_manager.SIMULATE_GPU:
			_finalize_selection_homemade()
		else:
			_finalize_selection_gpu()
		
		selectionRect = Rect2(0, 0, 0, 0)
		dragging = false
		queue_redraw()
		
		#coll_shape.shape.size = Vector2.ZERO
		
	
	if !dragging:
		position = get_global_mouse_position()
		
	else:
		
		selectionRect.position = position
		selectionRect.size = get_global_mouse_position() - position
		#selectionRect = selectionRect.abs()
		
		queue_redraw()
		
		
		pass
	
	pass



func _draw() -> void:
	
	var drawRect:Rect2 = selectionRect
	drawRect.position = Vector2.ZERO
	
	
	
	draw_rect(drawRect.abs(), Color(0.333, 0.624, 1.0, 0.75), true)
	




func _finalize_selection_homemade():
	
	
	var boid_list:Array[Boid]
	var to_select:Array[Boid] = []
	
	
	for s in boid_manager.squads:
		
		if s == null:
			continue
		
		boid_list.append_array(s.units)
	
	
	selectionRect = selectionRect.abs()
	
	#DANGER Apply grid later
	for b in boid_list:
		
		if selectionRect.has_point(b.position):
			
			to_select.append(b)
			
		
		pass
	
	boid_manager.select_boids(to_select)
	
	pass

#DANGER DANGER BAD PROGRAMMING HERE -> update w binning later
func _finalize_selection_gpu():
	
	selectionRect = selectionRect.abs()
	
	var to_select:Array[int] = []
	
	var curr_boid_pos:Color
	
	
	for b in boid_manager.NUM_BOIDS:
		
		curr_boid_pos = boid_manager.boid_pos_active[b]
		
		if selectionRect.has_point(Vector2(curr_boid_pos.r, curr_boid_pos.g)):
			to_select.append(b)
			
			
	
	
	boid_manager.select_boids(to_select)
	
	
	
	pass
