extends Node2D

const GAME_WIDTH = 320
const GAME_HEIGHT = 180


export(int) var spacing = 1

export(String) var speech_content = ""
export(Array, String) var choices = []
export(bool) var use_big_font = false
export(bool) var draw_text_box = true
onready var available_glyphs = [
	" ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.,:-_\"'?!()[]<>/",
	" ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.,\"'()[]<>-_!?/"
]
export(bool) var active = false
export(bool) var is_sticky = false
export(float) var dismiss_time_out = 3.0

var fonts = [
	preload("res://data/font3.png"),
	preload("res://data/font.png"),
]
var regions = []
var current_char = 0
var current_option = -1
var speech_char_timer = 0

onready var option = $Option
onready var fade_out_tween = $FadeOutTween 

signal dismiss(option_selected)

var index = 1
var text_h = 0

func _ready() -> void:
	if use_big_font:
		index = 0
	parse_glyphs()
	text_h = fonts[index].get_height() - 1
	
	if is_sticky:
		current_char = speech_content.length()
		activate()
	
func fade_out():
	current_char = 0
	if is_sticky:
		current_char = speech_content.length()
	fade_out_tween.interpolate_property(self, "modulate:a", 1, 0, dismiss_time_out)
	fade_out_tween.start()
	activate()

func font_width(content):
	var width = 0
	for c in content:
		var i = available_glyphs[index].find(c)
		width += regions[i].size.x + spacing
	return width
	
func _draw():
	var subspeech = speech_content.substr(0, current_char)
	var p = 5
	var text_w = font_width(subspeech)
	var x = -text_w / 2
	var y = -text_h - 5
	
	if position.x + text_w / 2 + 5 > GAME_WIDTH:
		x = GAME_WIDTH - (text_w + 5) - position.x
	elif position.x + x < 5:
		x = 5 - position.x
	
	draw_speech_box(subspeech, x, y)
	
	if choices.size() > 0 && current_char == speech_content.length():
		var cx = -10
		#var cx = start_position.x - 10
		var cy = y + p * 2 + 2 + text_h
		option.visible = true
		for i in range(choices.size()):
			draw_speech_box(choices[i], cx, cy)
			if i == current_option:
				option.set_position(Vector2(cx - 6 - 5, cy + text_h / 2))
			cy += p * 2 + 2 + text_h

func draw_speech_box(content, x, y):
	var text_w = font_width(content)
	
	if draw_text_box:
		var p = 5
		var rx = x - p
		var ry = y - p
		var rw = text_w + p * 2
		var rh = text_h + p * 2
		draw_rect(Rect2(rx - 1, ry - 1, rw + 2, rh + 2), Color(0, 0, 0, 0.7))
		trace_rect(rx, ry, rw, rh, Color(1,1,1,0.8))
	
	_font_draw(content, x, y)
	
func trace_rect(x,y,w,h, color):
	draw_rect(Rect2(x,y,w,1), color)
	draw_rect(Rect2(x,y,1,h), color)
	draw_rect(Rect2(x,y+h-1,w,1), color)
	draw_rect(Rect2(x+w-1,y,1,h), color)

func _font_draw(phrase, x, y):
	var advance = 0
	for c in phrase:
		advance = draw_char_at(c, x , y)
		x+=advance+spacing

func _process(dt):
	if !active:
		return
	if is_sticky:
		update()
		return
	
	if current_char < speech_content.length():
		speech_char_timer -= dt
		if speech_char_timer < 0:
			update()
			current_char += 1
			speech_char_timer = 0.04
	
	if Input.is_action_just_pressed("ui_up"):
		current_option -= 1
		current_option = clamp(current_option, 0, 1)
	if Input.is_action_just_pressed("ui_down"):
		current_option += 1
		current_option = clamp(current_option, 0, 1)
	option.set_position(Vector2(0, 10 + current_option * 10))
	update()

func next():
	if current_char < speech_content.length():
		current_char = speech_content.length() - 1
		update()
	else:
		active = false
		visible = false
		option.visible = false
		current_char = 0
		emit_signal("dismiss", current_option)
		current_option = 0
		speech_char_timer = 0

func draw_char_at(c, x,y):
	var i = available_glyphs[index].find(c)
	draw_texture_rect_region(fonts[index], Rect2(x,y,regions[i].size.x, regions[i].size.y), regions[i])
	return regions[i].size.x

func set_dialogue(dial):
	self.dialogue_line = dial

func set_content(content, ch = []):
	speech_content = content
	choices = ch

func activate():
	active = true
	visible = true
	update()

func parse_glyphs():
	var image = fonts[index].get_data()
	var last_left = 0
	var alpha
	var c_pos = -1
	image.lock()
	for x in fonts[index].get_width():
		alpha = image.get_pixel(x, 0).a8
		if alpha == 255:
			if c_pos >= 0:
				regions.push_back(Rect2(last_left+1, 1, x-last_left-1, fonts[index].get_height() - 1))
			last_left = x
			c_pos += 1
	image.unlock()

func _on_FadeOutTween_tween_completed(_object, _key):
	active = false
