extends Control

@export var num_selector:SpinBox

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass




func _on_button_exit_pressed() -> void:
	
	get_tree().quit()
	
	pass # Replace with function body.




func _on_button_start_pressed() -> void:
	
	var num_units:int = num_selector.value
	
	var next_scene:PackedScene = load("res://scenes/boid_compute.tscn")
	var scene_instance = next_scene.instantiate()
	scene_instance.get_child(0).num_boids = num_units
	
	get_tree().root.add_child(scene_instance)
	get_tree().current_scene = scene_instance
	
	queue_free()
	
	
	pass # Replace with function body.
