@tool
extends StaticBody2D


@export var texture: Texture2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	update_configuration_warnings()
	
	$Polygon2D.texture = texture
	
	if has_node("LightOccluder2D"):
		
		$LightOccluder2D.occluder = OccluderPolygon2D.new()
		$LightOccluder2D.occluder.polygon = PackedVector2Array($CollisionPolygon2D.polygon)
	
	$Polygon2D.polygon = $CollisionPolygon2D.polygon
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	if has_node("CollisionPolygon2D") && Engine.is_editor_hint():
		
		$Polygon2D.polygon = $CollisionPolygon2D.polygon
		
		$Polygon2D.texture = texture
		
		pass
	
	pass


func _get_configuration_warnings() -> PackedStringArray:
	var warnings = PackedStringArray()
		
	if !has_node("CollisionPolygon2D"):
		warnings.append("This node requires collisionPolygon to function.")
		
	return warnings # Return empty array if there are no warnings



func recieve_damage(amount: int):
	
	
	$HealthComponent.recieve_damage(amount)
	
	pass

func die():
	
	queue_free()
	
	pass
