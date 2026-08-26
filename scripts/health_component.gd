class_name HealthComponent extends Node

@export var total_Health: int = 10
@export var current_Health: int = total_Health
@export var body:Node

signal die()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func recieve_damage(amount: int):
	
	current_Health -= amount
	
	if current_Health <= 0:
		die.emit()
		body.die()
	pass
