extends Sprite2D

@export var boid_manager:BoidManager

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	#DANGER BAD BAD Just make a func in manager for ts
	if Input.is_action_just_pressed("F"):
		
		if boid_manager.selection_squad != -1:
			boid_manager.squads[boid_manager.selection_squad].set_formation("rect")
			
			
		pass
	
	if Input.is_action_just_pressed("rclick"):
		position = get_global_mouse_position()
		boid_manager.set_selected_bias(position)
		
	
	#clears bias
	if Input.is_action_just_pressed("delete"):
		boid_manager.set_selected_bias(Vector2.INF)
	
	if Input.is_action_just_pressed("spawnUnit"):
		
		#boid_manager.free()
		
		var next_scene:PackedScene = load("res://scenes/main_menu.tscn")
		var scene_instance = next_scene.instantiate()
		
		get_tree().root.get_child(0).queue_free()
		
		get_tree().root.add_child(scene_instance)
		get_tree().current_scene = scene_instance
	
		
		
	
	pass


#func _unhandled_input(event: InputEvent) -> void:
	

	
	
#	pass
