extends Camera2D

var cam_speed:float = 10
var zoom_scale_factor:float = 2

## true = zoom in, false = zoom out
signal scaleChanged(zoomIn: bool, zoomScale: float)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	
	if Input.is_action_pressed("ui_up"):
		
		position.y -= cam_speed
		
		pass
	
	if Input.is_action_pressed("ui_down"):
		
		position.y += cam_speed
		
		pass
	
	if Input.is_action_pressed("ui_left"):
		
		position.x -= cam_speed
		
		pass
	
	if Input.is_action_pressed("ui_right"):
		
		position.x += cam_speed
		
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
