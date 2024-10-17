extends Node2D

export(Color) var color = Color.black

func set_color(c):
	color = c
	update()

func _draw():
	draw_rect(Rect2(31, 79, 274, 52), color)
