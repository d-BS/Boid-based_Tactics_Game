extends OptionButton

@export var selection_box:Node2D


## this script, as well as all the current ui ones, are temoprary and will be deleted later

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass



func _on_item_selected(index: int) -> void:
	
	selection_box.mode = index
	
	pass # Replace with function body.
