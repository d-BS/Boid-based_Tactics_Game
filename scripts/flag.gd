extends Sprite2D

@export var boid_manager:Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	
	
	if Input.is_action_just_pressed("rclick"):
		position = get_global_mouse_position()
		boid_manager.set_selected_bias(position)
		
	
	#clears bias
	if Input.is_action_just_pressed("delete"):
		boid_manager.set_selected_bias(Vector2.INF)
	
	if Input.is_action_just_pressed("spawnUnit"):
		
		#boid_manager.free()
		
		get_tree().reload_current_scene()
	
	pass


#func _unhandled_input(event: InputEvent) -> void:
	

	
	
#	pass
