class_name Boid extends Area2D

#window size (preferred)
#1152
#648

#var personal_space:Area2D
var personal_shape:CollisionShape2D
var body:Sprite2D


#sleeping stupp
var is_sleeping: bool = false
static var sleep_cutoff: float = 5
static var sleep_cutoff_squared: float = sleep_cutoff * sleep_cutoff
static var wakeup_cutoff: float = 6
static var wakeup_cutoff_squared: float = wakeup_cutoff * wakeup_cutoff


#various index locations
var squad_id: Vector2i
var multimesh_index: int = -1

#@onready var viewport_dims: Vector2 = get_viewport().get_visible_rect().size

static var avoids: bool = true 
static var avoidance_factor:float = 10
static var avoidance_range:int = 25
static var avoidance_range_squared:int = avoidance_range * avoidance_range


static var aligns: bool = true
static var alignment_factor:float = .5


static var coheses: bool = true
static var cohesion_factor:float = -.05

#50
var personal_space_size:int = 35:
	set(value):
		personal_space_size = value
		personal_shape.shape.radius = value

#0, 60
#@export var min_speed: int = 0
static var max_speed: int = 100

#.1
var bias_loc:Vector2 = Vector2.INF
var squad_bias:Vector2 = Vector2.ZERO
static var bias_factor:float = .05

#formerly 1.5
static var damp_factor: float = 1.5


var velocity: Vector2:
	set(value):
		if value.length() > max_speed:
			velocity = value.normalized() * max_speed
			pass
		#elif value.length() < min_speed:
		#	velocity = value.normalized() * min_speed
		else:
			velocity = value



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	
	_setup_shape()
	
	#Maybe update sometime soon
	velocity = Vector2(0, float(randi_range(10, max_speed)))
	velocity = velocity.rotated(randf() * 2 * PI)
	
	
	pass # Replace with function body.




func _setup_shape():
	
	monitoring = true
	personal_shape = CollisionShape2D.new()
	personal_shape.shape = CircleShape2D.new()
	personal_shape.shape.radius = personal_space_size
	add_child(personal_shape)


func wake(kick:Vector2):
	
	is_sleeping = false
	monitoring = true
	velocity = kick

func sleep():
	
	velocity = Vector2.ZERO
	is_sleeping = true
	monitoring = false



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta:float) -> void:
	pass

func update(delta:float, neighbors:Array[Area2D]):#func _process(delta: float) -> void:
	
	
	position += velocity * delta
	
	
	#screen wrap
	#_screen_wrap(viewport_dims)
	
	
	#boid rules:
	
	if is_sleeping:
		return
	
	#applies rules that involve neighbors
	var average_velocity:Vector2 = _neighbor_rules(delta, neighbors)
	
	#applies bias
	if bias_loc != Vector2.INF:
		
		#set deadzone: more magic numbers!!!
		var deadzone_squared: int = 2500
		#var bias:Vector2 = (bias_loc - position) * bias_factor
		#bias = bias.normalized() * clampf(bias.length() - deadzone, 0, max_speed)
		
		#magical number 20 for the 'normal' speed
		#var bias: Vector2 = position.direction_to(bias_loc) * 25
		var bias: Vector2 = bias_loc - position
		if bias.length_squared() > deadzone_squared:
			bias = bias.normalized() * 20
			pass
		else:
			bias = Vector2.ZERO
			pass
		
		velocity += bias * delta
		
	
	#aplies squad bias
	velocity += squad_bias * delta * bias_factor * 1.5
	#squad_bias = Vector2.ZERO
	
	
	#applies damping
	velocity /= 1 + damp_factor * delta
	
	
	#determines if it should fall asleep
	if velocity.length_squared() <= sleep_cutoff_squared && average_velocity.length_squared() <= sleep_cutoff_squared:
		sleep()
	
	
	pass

func _screen_wrap(viewport_dims:Vector2):
	
	if position.x > viewport_dims.x:
		position.x = 0
	elif  position.x < 0:
		position.x = viewport_dims.x
	
	if position.y > viewport_dims.y:
		position.y = 0
	elif  position.y < 0:
		position.y = viewport_dims.y

func _neighbor_rules(delta:float, neighbors:Array[Area2D]) -> Vector2:
	
	var avoid_direction: Vector2 = Vector2.ZERO
	var num_neighbors: int = neighbors.size()
	
	var average_velocity: Vector2 = Vector2.ZERO
	var average_position: Vector2 = Vector2.ZERO
	
	
	var kicker: bool = velocity.length_squared() >= wakeup_cutoff_squared
	
	for b in neighbors:
		
		#skips if out of range
		# i think i wrote this wrong when i made it and it just never became a problem
		#if b.position.length_squared() < personal_space_size * personal_space_size:
		#	continue
		
		#passes if it detects a non boid
		if !b is Boid:
			continue
		
		#check personal space seperation
		if b.position.distance_squared_to(position) <= avoidance_range_squared:
			avoid_direction +=  position - b.position
			
			#wakes closest neighbors
			if b.is_sleeping:
				wake(velocity)
			
		
		if !b.is_sleeping:
			#for alignment calculation
			average_velocity += b.velocity
			
			#for cohesion calculation
			average_position += b.position
		
		#wakes sleeping neighbors
		elif kicker:
			b.wake(velocity)
		#	
	
	#avoidance
	velocity += avoid_direction * avoidance_factor * delta
	
	if num_neighbors > 0:
		
		#alignment
		#velocity += (average_velocity / num_neighbors - velocity) * alignment_factor * delta
		velocity += (average_velocity / num_neighbors) * alignment_factor * delta
		
		#cohesion
		velocity += (average_position / num_neighbors - position) * cohesion_factor * delta
		
	pass
	
	
	
	return average_velocity
