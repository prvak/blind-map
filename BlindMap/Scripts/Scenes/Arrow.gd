extends Node2D

@export var Style: LevelStyleResource
@export var From: Vector2
@export var To: Vector2

const WINGS_LENGHT = 30 # px

func _draw():
	var antialiased = true
	var color = Color.WHITE
	var direction = From - To
	var left_wing = direction.normalized().rotated(PI/5) * WINGS_LENGHT
	var right_wing = direction.normalized().rotated(-PI/5) * WINGS_LENGHT
	draw_line(From, To, color, 4.0, antialiased)
	draw_line(To, To + left_wing, color, 4.0, antialiased)
	draw_line(To, To + right_wing, color, 4.0, antialiased)


