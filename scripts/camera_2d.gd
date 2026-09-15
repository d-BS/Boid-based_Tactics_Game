extends Camera2D

var cam_speed:float = 750
var zoom_scale_factor:float = 2
var desired_location:Vector2 = position

## true = zoom in, false = zoom out
signal scaleChanged(zoomIn: bool, zoomScale: float)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	
	if(Input.is_action_pressed("shift")):
		var mouse_screen_pos:Vector2 = get_viewport().get_mouse_position()
		var screen_size:Vector2 = get_viewport_rect().size
		var mouse_screen_proportion:Vector2 = mouse_screen_pos/screen_size
		var move_dir:Vector2 = mouse_screen_proportion + Vector2(-.5, -.5)
		
		if(move_dir.length_squared() > .16):
			position += move_dir * cam_speed * delta * 5
	
	
	
	if Input.is_action_pressed("ui_up"):
		
		
		if(get_viewport_rect().end.y > limit_bottom):
			position = get_target_position()
		
		position.y -= cam_speed * delta
		
		
		
		pass
	
	if Input.is_action_pressed("ui_down"):
		
		
		position.y += cam_speed * delta
		
		pass
	
	if Input.is_action_pressed("ui_left"):
		
		
		position.x -= cam_speed * delta
		
		pass
		
	
	if Input.is_action_pressed("ui_right"):
		
		
		position.x += cam_speed * delta
		
		
		pass
	
	if Input.is_action_just_pressed("zoom_in"):
		
		zoom *= zoom_scale_factor
		cam_speed /= zoom_scale_factor
		
		scaleChanged.emit(true, zoom_scale_factor)
		
		pass
	if Input.is_action_just_pressed("zoom_out"):
		
		zoom /= zoom_scale_factor
		cam_speed *= zoom_scale_factor
		
		scaleChanged.emit(false, zoom_scale_factor)
		
		pass
	
	pass
