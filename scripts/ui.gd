extends Control

@export var environment_manager:Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass



func _on_lighting_options_item_selected(index: int) -> void:
	
	environment_manager.set_lighting(environment_manager.lighting_presets[index])
	
	pass # Replace with function body.
