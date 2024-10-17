extends Node2D
onready var sprite = $Sprite
export(bool) var active = false

var time = 0

func _process(dt):
	if !active:
		return
	
	time += dt
	modulate.a = Helper.get_wave_range(time, 1.8, 0.5, 0.8)
	position.y += floor(Helper.get_wave(time, 1) * 2)

func activate():
	active = true
	visible = true
	
func deactivate():
	active = false
	visible = false
	time = 0

func is_active():
	return active
