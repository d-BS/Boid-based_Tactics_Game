extends Sprite2D

const SCROLL_OFFSET_SCALE = 3

var grass_noise_generator: FastNoiseLite = ResourceLoader.load("res://textures/grass_noise.tres")
var grass_shader: Shader = ResourceLoader.load("res://scripts/grass_blades.gdshader")

@export var camera: Camera2D
@onready var central_region: VisibleOnScreenNotifier2D = $CenterRegion
@onready var grass_blades: MultiMeshInstance2D = $GrassBlades

#interpolation mode is cubic btw
var ramp_color_offsets:PackedFloat32Array = [0, 0.172, 0.636, 1]
var ramp_colors: PackedColorArray = [Color(0.155, 0.307, 0.256, 1.0), Color(0.173, 0.337, 0.282, 1.0), Color(0.38, 0.529, 0.392, 1.0), Color(0.612, 0.69, 0.502, 1.0)]

#(Former darkest)
#Color(0.149, 0.2, 0.22, 1.0)



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	#return
	
	#create grass Noise
	_setup_grass_noise()
	
	
	#multimesh test
	_setup_grass_blades()
	
	
	pass # Replace with function body.




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	
	
	
	
	
	pass



func _setup_grass_noise():
	
	
	var noise_tex:NoiseTexture2D = NoiseTexture2D.new()
	
	#set dimensions
	var viewportDims:Vector2 = get_viewport_rect().size
	noise_tex.height = int(viewportDims.y)
	noise_tex.width = int(viewportDims.x)
	
	grass_blades.position = Vector2(-viewportDims.x/2, -viewportDims.y/2)
	
	central_region.rect = Rect2(Vector2(viewportDims.x / SCROLL_OFFSET_SCALE, viewportDims.y / SCROLL_OFFSET_SCALE), Vector2(viewportDims.x / SCROLL_OFFSET_SCALE, viewportDims.y / SCROLL_OFFSET_SCALE))
	
	
	scale = Vector2(SCROLL_OFFSET_SCALE, SCROLL_OFFSET_SCALE)
	
	#set generator
	noise_tex.noise = grass_noise_generator
	
	
	#set color ramp
	noise_tex.color_ramp = Gradient.new()
	noise_tex.color_ramp.offsets = ramp_color_offsets
	noise_tex.color_ramp.colors = ramp_colors
	noise_tex.color_ramp.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CUBIC
	
	#other
	noise_tex.generate_mipmaps = false
	
	
	texture = noise_tex
	
	
	
	pass


func _setup_grass_blades():
	
	
	var mMesh:MultiMesh = grass_blades.multimesh
	var blade_location:Vector2
	mMesh.mesh.center_offset.y = (mMesh.mesh.size.y) * .4
	
	#waits until texture is available
	#if texture == null:
	await texture.changed
	var noise_map:Image = texture.get_image()
	
	
	#color TODO:
	#change color to be more light & yellowy, from bottom to top
	
	
	
	
	
	
	for i in range(mMesh.visible_instance_count):
		
		var flip_horz: bool = i % 2 == 0
		var flip_scale: int = 1
		if flip_horz:
			flip_scale = -1
		
		
		blade_location = Vector2(randi_range(0, noise_map.get_width()-1),randi_range(0, noise_map.get_height()-1))
		mMesh.set_instance_color(i, noise_map.get_pixelv(blade_location))
		
		
		mMesh.set_instance_transform_2d(i, Transform2D(0, Vector2(flip_scale, 1), 0.0, blade_location))
	
	#var arr:PackedFloat32Array 
	#arr.sort()
	
	pass



func _jump_up():
	
	
	
	pass

func _jump_down():
	
	
	pass

func _jump_left():
	
	
	pass

func _jump_right():
	
	
	pass


func _on_camera_2d_scale_changed(zoomIn: bool, zoomScale: float) -> void:
	
	#var original_dimensions:Vector2 = Vector2(scale.x * size.x, scale.y * size.y)
	#var new_dimensions:Vector2 = original_dimensions
	
	if zoomIn:
		zoomScale = 1/zoomScale
	
	
	#scale *= zoomScale
	
	
	#grass_noise_generator.frequency *= zoomScale
	#grass_noise_generator.offset -= 
	
	#new_dimensions *= zoomScale
	
	#keep the position the same reletive to the camera
	#position -= (new_dimensions - original_dimensions)
	
	
#	var scale = Vector2.1 \div zoom_level
	
	
	pass # Replace with function body.

#called when central region is no longer on screen
#means we need to set the new region to be the central region
func _on_center_region_screen_exited() -> void:
	
	#if central_region.
	
	
	
	pass # Replace with function body.
