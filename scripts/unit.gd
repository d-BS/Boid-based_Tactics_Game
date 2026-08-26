class_name Unit extends RigidBody2D


@export var texture:Texture2D
@export var damage: int = 1



@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var target: Node2D



#boink things
var boink_power: float = 100
var boink_timer_max: float = 1
var boink_timer: float = boink_timer_max
var boink_juice: bool = true

#physics
var friction: float = 2
var faction:String = "neutral"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	#add_to_group()
	
	
	contact_monitor = true
	max_contacts_reported = 1
	
	lock_rotation = true
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	
	
	#handles boinking
	boink_timer -= delta
	
	if boink_timer <= 0:
		
		boink_timer = boink_timer_max
		
		var toBoink: Vector2 = position.direction_to(target.position)
		toBoink *= boink_power
		
		apply_impulse(toBoink)
		
		
		$CPUParticles2D.emitting = boink_juice
		
		
		pass
	
	
	
	#apply friction
	apply_force(-linear_velocity * friction)
	
	
	pass


func setTarget(newTarget: Node):
	
	target = newTarget
	
	pass

func recieve_damage(amount: int):
	
	
	$HealthComponent.recieve_damage(amount)
	
	pass


func die():
	
	queue_free()
	
	pass


func collision_w_other(body: Node) -> void:
	
	#if body.is_class("RigidBody2D"):
	
	if(body.is_class("Unit") && body.faction == faction && body.faction != "neutral"):
		pass
	else:
		body.recieve_damage(damage)
	
	
	
	
	pass # Replace with function body.
