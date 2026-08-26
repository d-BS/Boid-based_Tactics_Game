extends Node2D

@onready var sun:DirectionalLight2D = $Sun
@onready var dark:CanvasModulate = $Dark

#class for containing environmental lighting
class EnvironmentalLighting:
	
	var sun_color: Color = Color.WHITE
	var sun_energy: float = 1.0
	var sun_height: float = 1.0
	var dark_color: Color = Color(0.341, 0.341, 0.341, 1.0)
	
	
	
	func _init(sun_c:Color = sun_color, sun_e:float = sun_energy, sun_h:float = sun_height, dark_c:Color = dark_color) -> void:
		sun_color = sun_c
		sun_energy = sun_e
		sun_height = sun_h
		dark_color = dark_c





#Environment Presets:

#Night, stars
#Color(0.078, 0.078, 0.078, 1.0)
#Color(1.0, 1.0, 1.0, 1.0), Energy 0.1
var night_lighting: EnvironmentalLighting = EnvironmentalLighting.new(Color(1.0, 1.0, 1.0, 1.0), .1, 1.0, Color(0.078, 0.078, 0.078, 1.0))

#Midnight, no stars
#Color(0.0, 0.0, 0.0, 1.0)
#Color(1.0, 1.0, 1.0, 1.0), Energy 0.0
var midnight_lighting: EnvironmentalLighting = EnvironmentalLighting.new(Color(1.0, 1.0, 1.0, 1.0), 0.0, 1.0, Color(0.0, 0.0, 0.0, 1.0))

#Midday
#Color(0.341, 0.341, 0.341, 1.0)
#Color(1.0, 1.0, 1.0, 1.0), Energy 1.0, Height 1
var day_lighting: EnvironmentalLighting = EnvironmentalLighting.new()

#Dawn/Dusk
#Color(0.282, 0.275, 0.282, 1.0)
#Color(1.0, 0.341, 0.196, 1.0), Energy 1.0, Height 1
var dusk_lighting: EnvironmentalLighting = EnvironmentalLighting.new(Color(1.0, 0.341, 0.196, 1.0), 1.0, 1.0, Color(0.282, 0.275, 0.282, 1.0))

var lighting_presets: Array[EnvironmentalLighting] = [day_lighting, night_lighting, midnight_lighting, dusk_lighting]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_lighting(day_lighting)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass



func set_lighting(light:EnvironmentalLighting):
	
	
	sun.color = light.sun_color
	sun.height = light.sun_height
	sun.energy = light.sun_energy
	
	dark.color = light.dark_color
	
	pass
