extends Node2D


@export var unitTarget:Node


const unit:PackedScene = preload("res://scenes/unit.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	
	
	
	pass

func _unhandled_input(event: InputEvent) -> void:
	
	if 1==0 && event.is_action_pressed("click"):
		
		
		
		var unit_instance:Unit = unit.instantiate()
		unit_instance.position = get_global_mouse_position()
		unit_instance.setTarget(unitTarget)
		add_child(unit_instance)
		
		pass
	
	pass
