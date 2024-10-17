extends Node2D
export(Color) var color = Color(1,1,1,0)

func _draw():
	draw_rect(Rect2(-5,-5,320+5,180+5), color)

func set_color(c):
	color = c
	update()
