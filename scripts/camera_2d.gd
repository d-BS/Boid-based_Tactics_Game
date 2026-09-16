extends Camera2D

var cam_speed:float = 750
var zoom_scale_factor:float = 2
var desired_location:Vector2 = position

var shift:bool = false
var up:bool = false
var down:bool = false
var left:bool = false
var right:bool = false

## true = zoom in, false = zoom out
signal scaleChanged(zoomIn: bool, zoomScale: float)

var d_time:float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	pass # Replace with function body.



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	d_time = delta
	
	
	if shift:
		
		var mouse_screen_pos:Vector2 = get_viewport().get_mouse_position()
		var screen_size:Vector2 = get_viewport_rect().size
		var mouse_screen_proportion:Vector2 = mouse_screen_pos/screen_size
		var move_dir:Vector2 = mouse_screen_proportion + Vector2(-.5, -.5)
		
		if(move_dir.length_squared() > .16):
			position += move_dir * cam_speed * d_time * 5
	
	
	if(up):
		if(get_viewport_rect().end.y > limit_bottom):
			position = get_target_position()
		
		position.y -= cam_speed * d_time
		
		
		
		pass
	
	if(down):
		
		position.y += cam_speed * d_time
		
		pass
	
	if(left):
		
		position.x -= cam_speed * d_time
		
		pass
	
	
	if(right):
		
		
		position.x += cam_speed * d_time
		
		
	
	
	pass

func _unhandled_input(event: InputEvent) -> void:
	
	
	if(event.is_action_pressed("shift")):
		
		shift = true
	
	elif(event.is_action_released("shift")):
		
		shift = false
	
	
	
	
	if event.is_action_pressed("ui_up"):
		
		up = true
	elif event.is_action_released("ui_up"):
		
		up = false
	
	
	
	
	
	if event.is_action_pressed("ui_down"):
		
		down = true
	elif event.is_action_released("ui_down"):
		
		down = false
	
	
	if event.is_action_pressed("ui_left"):
		
		left = true
	elif event.is_action_released("ui_left"):
		
		left = false
		
		
	
	if event.is_action_pressed("ui_right"):
		
		right = true
	elif event.is_action_released("ui_right"):
		
		right = false
		
		
		pass
	
	
	
	if event.is_action_pressed("zoom_in"):
		
		zoom *= zoom_scale_factor
		cam_speed /= zoom_scale_factor
		
		scaleChanged.emit(true, zoom_scale_factor)
		
		pass
	if event.is_action_pressed("zoom_out"):
		
		zoom /= zoom_scale_factor
		cam_speed *= zoom_scale_factor
		
		scaleChanged.emit(false, zoom_scale_factor)
		
		pass
	
	
	pass
