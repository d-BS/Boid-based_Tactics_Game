class_name Formation

var pos:Array[Vector2]
var size:int

## ie, rect, circle, none, etc
var formation_style:String

var spacing:Vector2
var location:Vector2

var rows:int
var cols:int

func _init(num_units:int) -> void:
	
	size = num_units
	
	var row_num:float = sqrt(size)
	rows = ceil(row_num)
	cols = floor(row_num)
	
	spacing = Vector2(100, 100)
	
	create_form()
	
	pass


func set_spacing(new_spacing:Vector2):
	
	
	spacing = new_spacing
	
	pass

func set_rows(new_rows:int):
	
	
	rows = new_rows
	
	pass


func set_cols(new_cols:int):
	
	
	cols = new_cols
	
	pass

func _update_form():
	
	
	pass

func create_form():
	
	pos = []
	pos.resize(size)
	
	var vert_offset:float = spacing.y * rows / 2
	var horz_offset:float = spacing.x * cols / 2
	
	
	for i in size:
		
		@warning_ignore("integer_division")
		var row_index:int = i / rows
		var col_index:int = i % rows
		
		pos[i] = Vector2(col_index * spacing.x - horz_offset, row_index * spacing.y - vert_offset)
		
		
		pass
	
	
	pass
