extends ItemList

@export var boid_manager:BoidManager

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	
	
	
	
	
	
	pass



func _on_squads_updated() -> void:
	
	for i in item_count:
		remove_item(0)
	
	var iterator:int = 0
	
	for s in boid_manager.squads:
		
		
		add_item(str("Squad ", iterator + 1, ", ", s.units.size(), " units"))
		
		iterator += 1
		
		pass
	
	if(boid_manager.selection_squad == -1):
		deselect_all()
	else:
		select(boid_manager.selection_squad)
	
	pass # Replace with function body.


func _on_item_selected(index: int) -> void:
	
	
	boid_manager.select_squad(index)
	
	
	pass # Replace with function body.
