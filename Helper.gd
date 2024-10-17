extends Node
	
func get_wave_range(app_time, period, low, high):
	return low + (get_wave(app_time, period) * (high - low))

func get_wave(app_time, period):
	return sin(app_time * 2 * PI / period) * 0.5 + 0.5

