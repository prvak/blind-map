class_name Placeholder extends MarginContainer

var Width: int :
	get:
		return Width
	set(value):
		Width = value
		add_theme_constant_override("margin_left", value)
		
var Height: int :
	get:
		return Height
	set(value):
		Height = value
		add_theme_constant_override("margin_top", value)
